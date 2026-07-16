-- ============================================================================
--  SD-102 · RegistrarPago: cobro atómico contra una cuenta (pre-factura)
--  Ejecuta este archivo en el SQL Editor de Supabase (una sola vez).
--
--  Objetivo:
--    Registrar un pago sobre una `cuenta` en una sola transacción: valida el
--    monto contra el saldo pendiente, inserta el pago (estado 'completado') y
--    cierra la cuenta ('saldada' + fecha_pago) si con este pago queda saldada;
--    si es un abono parcial la deja 'pendiente'. Devuelve el id del pago creado.
--
--  Consistencia:
--    · El saldo se calcula server-side bloqueando la fila de la cuenta
--      (FOR UPDATE) para evitar sobre-cobros por pagos concurrentes.
--    · `monto_pagado` NO es una columna: se deriva de la suma de `pagos`. El
--      cierre de la cuenta se refleja en `estado` / `fecha_pago`.
--    · 'completado' es el estado de un pago recibido en el vocabulario de la app
--      (enum Dart EstadoPago; `Pago.fueExitoso` == completado).
--
--  Esquema real (verificado contra la app / datasources):
--    · pagos:   cuenta_id, monto, fecha, estado (text), metodo_pago (text),
--               created_at, updated_at, deleted_at.
--    · cuentas: monto_total (SD-96), estado (text), fecha_pago, deleted_at.
-- ============================================================================

create or replace function registrar_pago(
  p_cuenta_id   uuid,
  p_monto       numeric,
  p_metodo_pago text
) returns uuid
language plpgsql
security definer
as $$
declare
  v_monto_total numeric(12,2);
  v_estado      text;
  v_pagado      numeric(12,2);
  v_saldo       numeric(12,2);
  v_pago_id     uuid;
begin
  -- 1. Cuenta objetivo, bloqueada para el resto de la transacción.
  select monto_total, estado
    into v_monto_total, v_estado
    from cuentas
   where id = p_cuenta_id
     and deleted_at is null
   for update;

  if not found then
    raise exception 'La cuenta % no existe o fue eliminada.', p_cuenta_id;
  end if;

  if v_estado = 'cancelada' then
    raise exception 'No se puede cobrar sobre una cuenta cancelada.';
  end if;

  -- 2. Saldo pendiente real = total congelado − pagos vigentes.
  select coalesce(sum(monto), 0)
    into v_pagado
    from pagos
   where cuenta_id = p_cuenta_id
     and deleted_at is null;

  v_saldo := v_monto_total - v_pagado;

  -- 3. Validaciones de negocio (autoridad server-side, además del use case).
  if p_monto is null or p_monto <= 0 then
    raise exception 'El monto del pago debe ser mayor que cero.';
  end if;

  if p_monto > v_saldo + 0.01 then
    raise exception 'El monto (%) excede el saldo pendiente (%).',
      p_monto, v_saldo;
  end if;

  -- 4. Inserta el pago recibido.
  insert into pagos (
    cuenta_id, monto, fecha, estado, metodo_pago, created_at, updated_at
  )
  values (
    p_cuenta_id, p_monto, now(), 'completado', p_metodo_pago, now(), now()
  )
  returning id into v_pago_id;

  -- 5. Cierra la cuenta si quedó saldada; si no, la marca pendiente.
  if v_pagado + p_monto >= v_monto_total then
    update cuentas
       set estado     = 'saldada',
           fecha_pago = now(),
           updated_at = now()
     where id = p_cuenta_id;
  else
    update cuentas
       set estado     = 'pendiente',
           updated_at = now()
     where id = p_cuenta_id;
  end if;

  return v_pago_id;
end;
$$;

grant execute on function registrar_pago(uuid, numeric, text) to authenticated, anon;
