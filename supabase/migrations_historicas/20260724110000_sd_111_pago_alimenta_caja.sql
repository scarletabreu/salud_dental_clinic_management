-- SD-111 · Cada pago completado genera un ingreso en la caja abierta del día.
--
-- En el dominio actual, el estado de pago que arquitectura denomina RECIBIDO
-- está persistido como `completado`.

create or replace function public.registrar_pago_en_caja()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caja_id uuid;
  v_zona_horaria constant text := 'America/Santo_Domingo';
begin
  if new.estado <> 'completado' or new.deleted_at is not null then
    return new;
  end if;

  select id
    into v_caja_id
    from public.cajas
   where cerrada = false
     and (fecha at time zone v_zona_horaria)::date =
         (current_timestamp at time zone v_zona_horaria)::date
   limit 1
   for update;

  if v_caja_id is null then
    raise exception using
      errcode = 'P0001',
      message = 'No hay una caja abierta para hoy. Abre la caja antes de registrar el pago.';
  end if;

  insert into public.movimientos_caja (
    caja_diaria_id,
    tipo,
    monto,
    descripcion,
    referencia_id,
    fecha
  ) values (
    v_caja_id,
    'ingreso',
    new.monto,
    'Cobro a cuenta',
    new.id,
    new.fecha
  );

  return new;
end;
$$;

drop trigger if exists pagos_registrar_ingreso_caja on public.pagos;
create trigger pagos_registrar_ingreso_caja
  after insert on public.pagos
  for each row execute function public.registrar_pago_en_caja();
