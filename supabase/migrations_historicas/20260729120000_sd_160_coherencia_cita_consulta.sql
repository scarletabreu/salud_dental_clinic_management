-- ============================================================================
--  SD-160 · Coherencia cita ↔ consulta: fecha real, estados y cierre atómico
--  Ejecuta este archivo en el SQL Editor de Supabase (una sola vez).
--
--  Tres reglas, todas del lado de la BD, para que no dependan de que la app las
--  respete. Este archivo es idempotente y NO reescribe datos clínicos: la
--  corrección de `consultas.fecha` ya escrita vive aparte, en
--  supabase/sd-160_corregir_fechas_consultas.sql, porque es irreversible y se
--  decide leyendo antes el diagnóstico.
--
--   1. `finalizar_consulta` completa la cita SIEMPRE, incluso cuando sale por
--      el retorno idempotente. Antes el `return` de idempotencia ocurría antes
--      del `update citas`: un reintento de finalizar (o cualquier consulta que
--      ya tuviera cuenta) dejaba la cita clavada en `en_consulta` para siempre.
--
--   2. Un trigger impide cancelar una cita cuya consulta siga abierta. La app
--      ya lo comprueba y da un mensaje accionable, pero hay caminos que no
--      pasan por ella (SQL a mano, el trigger de paciente inactivo, otro
--      cliente): la última palabra tiene que estar aquí.
--
--   3. Reprogramar una cita arrastra la fecha de su consulta ABIERTA, para que
--      heredar la fecha al crearla no se deshaga al mover la cita después.
--
--  Diagnóstico previo y posterior: supabase/sd-160_diagnostico_coherencia_cita_consulta.sql
--  (solo lectura). Las cuatro categorías deben quedar en cero tras aplicar esto
--  y la corrección de fechas, salvo la C, que requiere decisión caso por caso.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. finalizar_consulta: cerrar la cita también en el camino idempotente.
--
--    Se reescribe completa (no hay forma de parchear un cuerpo plpgsql) a
--    partir de la definición vigente en
--    20260725100000_corregir_drift_rpc_y_caja.sql, conservando el filtro por
--    `tratamientos_aplicados.estado` y la validación del enum `modo_pago`.
-- ---------------------------------------------------------------------------
create or replace function public.finalizar_consulta(
  p_consulta_id uuid,
  p_metodo_pago text default 'contado',
  p_nota        text default null
) returns uuid
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_paciente_id uuid;
  v_cita_id     uuid;
  v_cuenta_id   uuid;
  v_monto_total numeric(12,2);
  v_metodo_pago modo_pago;
begin
  -- El método llega como texto desde la app; la columna es el enum `modo_pago`.
  begin
    v_metodo_pago := lower(btrim(coalesce(p_metodo_pago, 'contado')))::modo_pago;
  exception when invalid_text_representation then
    raise exception 'Método de pago inválido: %. Valores admitidos: contado, credito.',
      p_metodo_pago using errcode = '22023';
  end;

  select paciente_id, cita_id into v_paciente_id, v_cita_id
  from consultas where id = p_consulta_id and deleted_at is null;
  if v_paciente_id is null then
    raise exception 'La consulta % no existe o fue eliminada.', p_consulta_id;
  end if;

  -- Cierre clínico ANTES de cualquier retorno: finalizar una consulta cierra su
  -- cita, y eso debe valer también cuando la pre-factura ya existía. El estado
  -- terminal se respeta (no se reabre una cita cancelada a mano).
  if v_cita_id is not null then
    update citas
       set estado     = 'completada'::estado_cita,
           updated_at = now()
     where id = v_cita_id
       and estado <> 'completada'::estado_cita
       and estado <> 'cancelada'::estado_cita;
  end if;

  -- Idempotencia: reintentar finalizar no duplica la pre-factura.
  select id into v_cuenta_id from cuentas
  where consulta_id = p_consulta_id and deleted_at is null limit 1;
  if v_cuenta_id is not null then return v_cuenta_id; end if;

  -- Solo procedimientos ejecutados. Las actividades del plan (propuestas,
  -- aceptadas o pendientes) y los hallazgos de la evaluación no facturan.
  select coalesce(sum(precio_aplicado), 0) into v_monto_total
  from tratamientos_aplicados
  where consulta_id = p_consulta_id
    and deleted_at is null
    and coalesce(estado, 'aplicado') <> 'indicado';

  insert into cuentas (
    paciente_id, consulta_id, estado, monto_total, metodo_pago,
    fecha_creacion, nota, created_at, updated_at
  ) values (
    v_paciente_id, p_consulta_id, 'abierta', v_monto_total, v_metodo_pago,
    now(), p_nota, now(), now()
  ) returning id into v_cuenta_id;

  insert into items_cuenta (
    cuenta_id, descripcion, precio_unitario, cantidad, created_at, updated_at
  )
  select v_cuenta_id, coalesce(t.nombre, 'Tratamiento'),
         coalesce(ta.precio_aplicado, 0), 1, now(), now()
  from tratamientos_aplicados ta
  left join tratamientos t on t.id = ta.tratamiento_id
  where ta.consulta_id = p_consulta_id
    and ta.deleted_at is null
    and coalesce(ta.estado, 'aplicado') <> 'indicado';

  return v_cuenta_id;
end;
$$;

grant execute on function public.finalizar_consulta(uuid, text, text)
  to authenticated, anon;

-- ---------------------------------------------------------------------------
-- 2. No se cancela una cita con su consulta abierta.
--
--    Se comprueba solo cuando el estado PASA a 'cancelada', para no penalizar
--    updates que no tocan el estado ni bloquear filas ya canceladas.
-- ---------------------------------------------------------------------------
create or replace function public.bloquear_cancelacion_con_consulta_abierta()
returns trigger
language plpgsql
set search_path to 'public'
as $$
begin
  if new.estado = 'cancelada'::estado_cita
     and (old.estado is distinct from new.estado)
     and exists (
       select 1
       from consultas c
       where c.cita_id = new.id
         and c.deleted_at is null
         and c.finalizada is not true
     )
  then
    raise exception
      'La cita % tiene una consulta en curso: finaliza o elimina la consulta antes de cancelarla.',
      new.id
      using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger if exists tr_bloquear_cancelacion_con_consulta_abierta on public.citas;

create trigger tr_bloquear_cancelacion_con_consulta_abierta
  before update of estado on public.citas
  for each row
  execute function public.bloquear_cancelacion_con_consulta_abierta();

-- ---------------------------------------------------------------------------
-- 3. Reprogramar una cita arrastra la fecha de su consulta abierta.
--
--    Heredar la fecha al crear la consulta no basta: si después se mueve la
--    cita, la consulta se queda en el hueco viejo y el desfase vuelve por otra
--    puerta. Solo se realinean las consultas ABIERTAS: reescribir la fecha de
--    una consulta ya finalizada cambiaría un registro clínico cerrado, que es
--    justo lo que no se debe tocar desde la agenda.
-- ---------------------------------------------------------------------------
create or replace function public.realinear_consulta_al_reprogramar_cita()
returns trigger
language plpgsql
set search_path to 'public'
as $$
begin
  if new.fecha_hora is distinct from old.fecha_hora then
    update consultas
       set fecha      = new.fecha_hora,
           updated_at = now()
     where cita_id = new.id
       and deleted_at is null
       and finalizada is not true;
  end if;
  return new;
end;
$$;

drop trigger if exists tr_realinear_consulta_al_reprogramar_cita on public.citas;

create trigger tr_realinear_consulta_al_reprogramar_cita
  after update of fecha_hora on public.citas
  for each row
  execute function public.realinear_consulta_al_reprogramar_cita();

comment on function public.bloquear_cancelacion_con_consulta_abierta() is
  'SD-160: impide cancelar una cita mientras su consulta siga abierta.';

comment on function public.realinear_consulta_al_reprogramar_cita() is
  'SD-160: al mover una cita, su consulta abierta hereda la nueva fecha.';
