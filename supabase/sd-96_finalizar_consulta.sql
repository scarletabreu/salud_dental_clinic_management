-- ============================================================================
--  SD-96 · FinalizarConsulta: pre-factura al cerrar la consulta (handoff clínico→financiero)
--  Ejecuta este archivo en el SQL Editor de Supabase (una sola vez).
--
--  Objetivo:
--    Al finalizar una consulta, dejar una pre-factura REAL en la BD: una `cuenta`
--    ABIERTA cuyo `monto_total` es la suma de los `precio_aplicado` (SD-84) de los
--    tratamientos de esa consulta, con un `items_cuenta` por tratamiento. Marca la
--    cita como COMPLETADA en la misma transacción y devuelve el id de la cuenta.
--
--  Esquema real (verificado contra la app / datasources):
--    · cuentas: paciente_id, consulta_id, metodo_pago (text 'Contado'/'Crédito'),
--      fecha_creacion, fecha_pago, nota, created_at, updated_at, deleted_at.
--    · items_cuenta: cuenta_id, descripcion, precio_unitario, cantidad, timestamps.
--    · tratamientos_aplicados: consulta_id, tratamiento_id, precio_aplicado (SD-84).
--    · citas.estado es el enum `estado_cita` (minúscula); 'completada' es terminal.
--
--  Columnas que se agregan a `cuentas` (aditivo, idempotente):
--    · estado       text  → ciclo de vida de la cuenta (abierta/pendiente/saldada/
--                           cancelada). Coincide con el enum Dart EstadoCuenta.
--    · monto_total  numeric(12,2) → total congelado al emitir la pre-factura.
-- ============================================================================

alter table cuentas
  add column if not exists paciente_id uuid          references personas(id),
  add column if not exists estado      text          not null default 'abierta',
  add column if not exists monto_total numeric(12,2) not null default 0;

create or replace function finalizar_consulta(
  p_consulta_id uuid,
  p_metodo_pago text default 'Contado',
  p_nota        text default null
) returns uuid
language plpgsql
security definer
as $$
declare
  v_paciente_id uuid;
  v_cita_id     uuid;
  v_cuenta_id   uuid;
  v_monto_total numeric(12,2);
begin
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

  -- 3. Monto = suma de los precios congelados de los tratamientos de la consulta.
  select coalesce(sum(precio_aplicado), 0)
    into v_monto_total
    from tratamientos_aplicados
   where consulta_id = p_consulta_id
     and deleted_at is null;

  -- 4. Cuenta ABIERTA con el total calculado.
  insert into cuentas (
    paciente_id, consulta_id, estado, monto_total, metodo_pago,
    fecha_creacion, nota, created_at, updated_at
  )
  values (
    v_paciente_id, p_consulta_id, 'abierta', v_monto_total, p_metodo_pago,
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
    and ta.deleted_at is null;

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

grant execute on function finalizar_consulta(uuid, text, text) to authenticated, anon;
