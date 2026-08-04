-- ============================================================================
--  SD-102b · Hotfix de triggers sobre `pagos` (y `cuotas`)
--  Ejecuta este archivo en el SQL Editor de Supabase (una sola vez).
--
--  Contexto:
--    La tabla de ítems se renombró de `item_cuentas` a `items_cuenta`, pero dos
--    funciones trigger quedaron apuntando al nombre viejo. Al no existir esa
--    relación, CUALQUIER insert en `pagos` (y en `cuotas`) fallaba con:
--        relation "public.item_cuentas" does not exist
--    Este es el error que aparece al registrar un pago (SD-102), justo después
--    de arreglar el casteo del método de pago al enum `metodo_pago`.
--
--  Qué corrige:
--    1. `validar_monto_pago()` (trigger `tr_validar_exceso_pago`, BEFORE INSERT/
--       UPDATE sobre `pagos`):
--         · Usaba `item_cuentas` (inexistente).
--         · Además tenía un bug de producto cartesiano: unía cuentas × ítems ×
--           pagos en un solo FROM, inflando las sumas cuando había más de un
--           ítem o más de un pago, lo que rechazaba cobros válidos.
--       Se reescribe para validar contra `cuentas.monto_total` (el total
--       congelado en SD-96, misma fuente que usa la RPC `registrar_pago`) menos
--       la suma de pagos vigentes, con la misma tolerancia de 1 centavo. Así el
--       trigger nunca rechaza un cobro que la RPC ya aprobó.
--    2. `validar_monto_cuotas()` (trigger `tr_validar_limite_cuotas` sobre
--       `cuotas`): mismo bug de nombre de tabla; se corrige el nombre.
--
--  Los triggers no se recrean: siguen apuntando a estas funciones. Solo se
--  reemplaza el cuerpo (idempotente).
-- ============================================================================

create or replace function public.validar_monto_pago()
returns trigger
language plpgsql
as $$
declare
  v_total   numeric(15,2);
  v_pagado  numeric(15,2);
  v_balance numeric(15,2);
begin
  -- Solo un pago marcado como recibido ('completado') consume saldo.
  if new.estado <> 'completado' then
    return new;
  end if;

  -- Total congelado de la cuenta (misma fuente que la RPC registrar_pago).
  select coalesce(monto_total, 0)
    into v_total
    from public.cuentas
   where id = new.cuenta_id;

  -- Pagos vigentes ya aplicados, excluyendo la fila actual (relevante en UPDATE).
  select coalesce(sum(monto), 0)
    into v_pagado
    from public.pagos
   where cuenta_id = new.cuenta_id
     and deleted_at is null
     and id is distinct from new.id;

  v_balance := v_total - v_pagado;

  if new.monto > v_balance + 0.01 then
    raise exception 'El monto del pago (%) excede el balance pendiente (%).',
      new.monto, v_balance;
  end if;

  return new;
end;
$$;

create or replace function public.validar_monto_cuotas()
returns trigger
language plpgsql
as $$
declare
  monto_total_cuenta decimal(15,2);
  monto_total_cuotas decimal(15,2);
begin
  select coalesce(sum(precio_unitario * cantidad), 0)
    into monto_total_cuenta
    from public.items_cuenta
   where cuenta_id = new.cuenta_id
     and deleted_at is null;

  select coalesce(sum(monto), 0) + new.monto
    into monto_total_cuotas
    from public.cuotas
   where cuenta_id = new.cuenta_id
     and id != new.id;

  if monto_total_cuotas > monto_total_cuenta then
    raise exception 'La suma de las cuotas (%) no puede ser mayor al total de la cuenta (%)',
      monto_total_cuotas, monto_total_cuenta;
  end if;

  return new;
end;
$$;
