-- ============================================================================
--  Corrección de drift entre la base de datos y el repositorio.
--
--  Contexto: varios objetos se crearon a mano en el SQL Editor y quedaron
--  conviviendo con la versión versionada en `supabase/migrations`. Postgres no
--  reemplaza una función cuando cambia el tipo de un parámetro: crea una
--  sobrecarga nueva. Con dos candidatas, PostgREST no puede resolver la llamada
--  y devuelve "Could not choose the best candidate function".
--
--  Esta migración elimina los duplicados heredados, deja una sola definición
--  canónica de cada objeto y endurece las funciones SECURITY DEFINER.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. finalizar_consulta: eliminar la sobrecarga heredada (uuid, modo_pago, text)
--
--    La versión antigua recibía el enum `modo_pago` y no era SECURITY DEFINER,
--    por lo que además habría fallado contra las políticas RLS activas. La
--    versión vigente recibe `text` (lo que envía la app) y se queda como única.
-- ----------------------------------------------------------------------------
drop function if exists public.finalizar_consulta(uuid, public.modo_pago, text);

-- Definición canónica: valida el método de pago contra el enum `modo_pago`
-- antes de insertar, en vez de depender del cast implícito de la columna.
create or replace function public.finalizar_consulta(
  p_consulta_id uuid,
  p_metodo_pago text default 'contado',
  p_nota        text default null
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_paciente_id uuid;
  v_cita_id     uuid;
  v_cuenta_id   uuid;
  v_monto_total numeric(12,2);
  v_metodo_pago modo_pago;
begin
  -- 0. El método de pago llega como texto desde la app; `cuentas.metodo_pago`
  --    es el enum `modo_pago`. Se normaliza y se rechaza con un mensaje claro
  --    en vez de dejar que el cast implícito reviente la transacción.
  begin
    v_metodo_pago := lower(btrim(coalesce(p_metodo_pago, 'contado')))::modo_pago;
  exception when invalid_text_representation then
    raise exception 'Método de pago inválido: %. Valores admitidos: contado, credito.',
      p_metodo_pago using errcode = '22023';
  end;

  -- 1. Datos de la consulta (paciente para la cuenta, cita para completarla).
  select paciente_id, cita_id
    into v_paciente_id, v_cita_id
    from consultas
   where id = p_consulta_id
     and deleted_at is null;

  if v_paciente_id is null then
    raise exception 'La consulta % no existe o fue eliminada.', p_consulta_id;
  end if;

  -- 2. Idempotencia: si esta consulta ya tiene cuenta, se devuelve la existente
  --    (evita pre-facturas duplicadas si se reintenta finalizar).
  select id
    into v_cuenta_id
    from cuentas
   where consulta_id = p_consulta_id
     and deleted_at is null
   limit 1;

  if v_cuenta_id is not null then
    return v_cuenta_id;
  end if;

  -- 3. Monto = suma de los precios congelados de los tratamientos aplicados.
  select coalesce(sum(precio_aplicado), 0)
    into v_monto_total
    from tratamientos_aplicados
   where consulta_id = p_consulta_id
     and deleted_at is null
     and coalesce(estado, 'aplicado') = 'aplicado';

  -- 4. Cuenta ABIERTA con el total calculado.
  insert into cuentas (
    paciente_id, consulta_id, estado, monto_total, metodo_pago,
    fecha_creacion, nota, created_at, updated_at
  )
  values (
    v_paciente_id, p_consulta_id, 'abierta', v_monto_total, v_metodo_pago,
    now(), p_nota, now(), now()
  )
  returning id into v_cuenta_id;

  -- 5. Un ítem por tratamiento aplicado (descripción = nombre del tratamiento).
  insert into items_cuenta (
    cuenta_id, descripcion, precio_unitario, cantidad, created_at, updated_at
  )
  select
    v_cuenta_id,
    coalesce(t.nombre, 'Tratamiento'),
    coalesce(ta.precio_aplicado, 0),
    1,
    now(), now()
  from tratamientos_aplicados ta
  left join tratamientos t on t.id = ta.tratamiento_id
  where ta.consulta_id = p_consulta_id
    and ta.deleted_at is null
    and coalesce(ta.estado, 'aplicado') = 'aplicado';

  -- 6. Cierre clínico: marcar la cita como completada (si la consulta nació de una).
  if v_cita_id is not null then
    update citas
       set estado     = 'completada'::estado_cita,
           updated_at = now()
     where id = v_cita_id;
  end if;

  return v_cuenta_id;
end;
$$;

grant execute on function public.finalizar_consulta(uuid, text, text)
  to authenticated, anon;

-- ----------------------------------------------------------------------------
-- 2. pagos: eliminar el trigger heredado que duplicaba el ingreso de caja.
--
--    `tr_pago_a_movimiento_caja` convivía con `pagos_registrar_ingreso_caja`
--    (SD-111). Ambos insertan en `movimientos_caja` por cada pago. El heredado
--    lee la tabla muerta `cajas_diarias` y la FK de `movimientos_caja` ya
--    apunta a `cajas`: hoy no dispara porque `cajas_diarias` está vacía, pero
--    en cuanto tuviera una fila abierta duplicaría el ingreso y violaría la FK,
--    revirtiendo cada pago.
-- ----------------------------------------------------------------------------
drop trigger if exists tr_pago_a_movimiento_caja on public.pagos;
drop function if exists public.registrar_movimiento_por_pago();

-- ----------------------------------------------------------------------------
-- 3. validar_caja_abierta: validar contra `cajas`, no contra `cajas_diarias`.
--
--    El guard que impide registrar movimientos en una caja cerrada consultaba
--    la tabla heredada, así que nunca encontraba la caja y siempre dejaba pasar
--    el movimiento. SECURITY DEFINER para que RLS no lo desactive en silencio
--    (un rol sin SELECT sobre `cajas` haría que el EXISTS diera falso).
-- ----------------------------------------------------------------------------
create or replace function public.validar_caja_abierta()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if exists (
    select 1
      from public.cajas
     where id = new.caja_diaria_id
       and cerrada = true
  ) then
    raise exception 'No se pueden registrar movimientos en una caja que ya está cerrada.';
  end if;

  return new;
end;
$$;

-- ----------------------------------------------------------------------------
-- 4. Fijar search_path en las funciones SECURITY DEFINER que lo tenían mutable.
--
--    Sin `search_path` fijo, la resolución de nombres depende de la sesión que
--    invoca: es tanto un riesgo de seguridad (advisor de Supabase) como una
--    fuente de fallos intermitentes. Las tres funciones `es_*` se evalúan en
--    cada política RLS.
-- ----------------------------------------------------------------------------
alter function public.es_admin()                set search_path = public;
alter function public.es_doctor()               set search_path = public;
alter function public.es_asistente()            set search_path = public;
alter function public.crear_consulta_completa(uuid, uuid, uuid, timestamptz, text, jsonb, jsonb, jsonb)
                                                set search_path = public;
alter function public.recibir_compra(uuid, uuid) set search_path = public;
