-- SD-103 · Plan de cuotas y pagos vinculados

alter table public.cuotas
  add column if not exists monto_pagado numeric(15,2) not null default 0;

alter table public.pagos
  add column if not exists cuota_id uuid;

do $$
begin
  if not exists (
    select 1
      from pg_constraint
     where conname = 'cuotas_monto_pagado_check'
       and conrelid = 'public.cuotas'::regclass
  ) then
    alter table public.cuotas
      add constraint cuotas_monto_pagado_check
      check (monto_pagado >= 0 and monto_pagado <= monto);
  end if;

  if not exists (
    select 1
      from pg_constraint
     where conname = 'pagos_cuota_id_fkey'
       and conrelid = 'public.pagos'::regclass
  ) then
    alter table public.pagos
      add constraint pagos_cuota_id_fkey
      foreign key (cuota_id) references public.cuotas(id) on delete restrict;
  end if;
end;
$$;

create index if not exists idx_pagos_cuota_id
  on public.pagos(cuota_id)
  where cuota_id is not null and deleted_at is null;

create index if not exists idx_cuotas_cuenta_vencimiento
  on public.cuotas(cuenta_id, fecha_vencimiento)
  where deleted_at is null;

create or replace function public.marcar_cuotas_vencidas(p_cuenta_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update public.cuotas
     set estado = 'vencida',
         updated_at = now()
   where cuenta_id = p_cuenta_id
     and deleted_at is null
     and estado = 'pendiente'
     and fecha_vencimiento < current_date;
$$;

create or replace function public.generar_plan_cuotas(
  p_cuenta_id uuid,
  p_cuotas jsonb
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_total numeric(15,2);
  v_pagado numeric(15,2);
  v_saldo numeric(15,2);
  v_suma_cuotas numeric(15,2);
  v_num_cuotas integer;
begin
  if p_cuotas is null or jsonb_typeof(p_cuotas) <> 'array' then
    raise exception 'El plan de cuotas no tiene un formato válido.';
  end if;

  v_num_cuotas := jsonb_array_length(p_cuotas);
  if v_num_cuotas < 2 or v_num_cuotas > 36 then
    raise exception 'El plan debe tener entre 2 y 36 cuotas.';
  end if;

  select monto_total
    into v_total
    from public.cuentas
   where id = p_cuenta_id
     and deleted_at is null
   for update;

  if not found then
    raise exception 'No se encontró la cuenta solicitada.';
  end if;

  if exists (
    select 1
      from public.cuotas
     where cuenta_id = p_cuenta_id
       and deleted_at is null
  ) then
    raise exception 'La cuenta ya tiene un plan de cuotas.';
  end if;

  select coalesce(sum(monto), 0)
    into v_pagado
    from public.pagos
   where cuenta_id = p_cuenta_id
     and estado = 'completado'
     and deleted_at is null;

  v_saldo := round(v_total - v_pagado, 2);
  if v_saldo <= 0 then
    raise exception 'Esta cuenta ya está saldada.';
  end if;

  select coalesce(sum((item->>'monto')::numeric), 0)
    into v_suma_cuotas
    from jsonb_array_elements(p_cuotas) item;

  if abs(v_suma_cuotas - v_saldo) > 0.01 then
    raise exception 'La suma de las cuotas (%) debe coincidir con el saldo pendiente (%).',
      v_suma_cuotas, v_saldo;
  end if;

  if exists (
    select 1
      from jsonb_array_elements(p_cuotas) item
     where (item->>'monto')::numeric <= 0
        or (item->>'fecha_vencimiento')::date < current_date
  ) then
    raise exception 'Todas las cuotas deben tener monto positivo y fecha vigente.';
  end if;

  insert into public.cuotas (
    cuenta_id,
    monto,
    monto_pagado,
    fecha_vencimiento,
    estado,
    created_at,
    updated_at
  )
  select
    p_cuenta_id,
    (item->>'monto')::numeric,
    0,
    (item->>'fecha_vencimiento')::date,
    'pendiente',
    now(),
    now()
  from jsonb_array_elements(p_cuotas) item;

  update public.cuentas
     set metodo_pago = 'credito',
         estado = 'pendiente',
         updated_at = now()
   where id = p_cuenta_id;
end;
$$;

drop function if exists public.registrar_pago(uuid, numeric, text);

create or replace function public.registrar_pago(
  p_cuenta_id uuid,
  p_monto numeric,
  p_metodo_pago text,
  p_cuota_id uuid default null
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_monto_total numeric(15,2);
  v_estado text;
  v_pagado numeric(15,2);
  v_saldo numeric(15,2);
  v_pago_id uuid;
  v_cuota_monto numeric(15,2);
  v_cuota_pagado numeric(15,2);
  v_cuota_estado public.estado_cuota;
begin
  select monto_total, estado
    into v_monto_total, v_estado
    from public.cuentas
   where id = p_cuenta_id
     and deleted_at is null
   for update;

  if not found then
    raise exception 'No se encontró la cuenta solicitada.';
  end if;
  if v_estado in ('saldada', 'cancelada') then
    raise exception 'La cuenta no admite nuevos pagos porque está %.', v_estado;
  end if;
  if p_monto is null or p_monto <= 0 then
    raise exception 'El monto del pago debe ser mayor que cero.';
  end if;

  select coalesce(sum(monto), 0)
    into v_pagado
    from public.pagos
   where cuenta_id = p_cuenta_id
     and estado = 'completado'
     and deleted_at is null;

  v_saldo := round(v_monto_total - v_pagado, 2);
  if p_monto > v_saldo + 0.01 then
    raise exception 'El monto del pago (%) excede el saldo pendiente (%).',
      p_monto, v_saldo;
  end if;

  if p_cuota_id is not null then
    select monto, monto_pagado, estado
      into v_cuota_monto, v_cuota_pagado, v_cuota_estado
      from public.cuotas
     where id = p_cuota_id
       and cuenta_id = p_cuenta_id
       and deleted_at is null
     for update;

    if not found then
      raise exception 'La cuota no pertenece a esta cuenta.';
    end if;
    if v_cuota_estado in ('pagada', 'cancelada') then
      raise exception 'La cuota no admite nuevos pagos porque está %.', v_cuota_estado;
    end if;
    if p_monto > (v_cuota_monto - v_cuota_pagado) + 0.01 then
      raise exception 'El monto del pago (%) excede el saldo de la cuota (%).',
        p_monto, v_cuota_monto - v_cuota_pagado;
    end if;
  end if;

  begin
    insert into public.pagos (
      cuenta_id,
      cuota_id,
      monto,
      fecha,
      estado,
      metodo_pago,
      created_at,
      updated_at
    ) values (
      p_cuenta_id,
      p_cuota_id,
      round(p_monto, 2),
      now(),
      'completado',
      p_metodo_pago::public.metodo_pago,
      now(),
      now()
    ) returning id into v_pago_id;
  exception
    when invalid_text_representation then
      raise exception 'El método de pago no es válido.';
  end;

  if p_cuota_id is not null then
    update public.cuotas
       set monto_pagado = least(monto, monto_pagado + round(p_monto, 2)),
           estado = case
             when monto_pagado + round(p_monto, 2) >= monto then 'pagada'::public.estado_cuota
             when fecha_vencimiento < current_date then 'vencida'::public.estado_cuota
             else 'pendiente'::public.estado_cuota
           end,
           updated_at = now()
     where id = p_cuota_id;
  end if;

  if v_pagado + p_monto >= v_monto_total then
    update public.cuentas
       set estado = 'saldada',
           fecha_pago = now(),
           updated_at = now()
     where id = p_cuenta_id;
  else
    update public.cuentas
       set estado = 'pendiente',
           updated_at = now()
     where id = p_cuenta_id;
  end if;

  return v_pago_id;
end;
$$;

grant execute on function public.marcar_cuotas_vencidas(uuid)
  to authenticated, anon;
grant execute on function public.generar_plan_cuotas(uuid, jsonb)
  to authenticated, anon;
grant execute on function public.registrar_pago(uuid, numeric, text, uuid)
  to authenticated, anon;
