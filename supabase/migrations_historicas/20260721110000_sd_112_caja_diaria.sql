-- SD-112 · Caja diaria: apertura, balance operativo y movimientos en tiempo real.

create table if not exists public.cajas (
  id uuid primary key default gen_random_uuid(),
  fecha timestamptz not null default now(),
  monto_apertura numeric(12,2) not null check (monto_apertura >= 0),
  monto_cierre numeric(12,2) not null default 0,
  monto_esperado numeric(12,2) not null default 0,
  monto_real numeric(12,2) not null default 0,
  cerrada boolean not null default false,
  abierta_por uuid references auth.users(id),
  cerrada_por uuid references auth.users(id),
  observaciones text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists cajas_una_abierta_idx
  on public.cajas ((cerrada)) where cerrada = false;

create table if not exists public.movimientos_caja (
  id uuid primary key default gen_random_uuid(),
  caja_diaria_id uuid not null references public.cajas(id),
  tipo text not null check (tipo in ('ingreso', 'egreso')),
  monto numeric(12,2) not null check (monto > 0),
  descripcion text not null,
  referencia_id uuid,
  fecha timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists movimientos_caja_fecha_idx
  on public.movimientos_caja (caja_diaria_id, fecha desc)
  where deleted_at is null;

create or replace function public.registrar_pago_en_caja()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caja_id uuid;
begin
  if new.estado <> 'completado' or new.deleted_at is not null then
    return new;
  end if;

  select id into v_caja_id from cajas where cerrada = false limit 1;
  if v_caja_id is not null then
    insert into movimientos_caja (caja_diaria_id, tipo, monto, descripcion, referencia_id, fecha)
    values (v_caja_id, 'ingreso', new.monto, 'Cobro a cuenta', new.id, new.fecha);
  end if;
  return new;
end;
$$;

drop trigger if exists pagos_registrar_ingreso_caja on public.pagos;
create trigger pagos_registrar_ingreso_caja
  after insert on public.pagos
  for each row execute function public.registrar_pago_en_caja();

alter table public.cajas enable row level security;
alter table public.movimientos_caja enable row level security;

grant select, insert, update on public.cajas to authenticated;
grant select, insert, update on public.movimientos_caja to authenticated;

drop policy if exists "authenticated_manage_cajas" on public.cajas;
create policy "authenticated_manage_cajas" on public.cajas
  for all to authenticated
  using (
    exists (select 1 from public.admins where id = auth.uid())
    or exists (select 1 from public.asistentes where id = auth.uid())
  )
  with check (
    exists (select 1 from public.admins where id = auth.uid())
    or exists (select 1 from public.asistentes where id = auth.uid())
  );

drop policy if exists "authenticated_manage_movimientos_caja" on public.movimientos_caja;
create policy "authenticated_manage_movimientos_caja" on public.movimientos_caja
  for all to authenticated
  using (
    exists (select 1 from public.admins where id = auth.uid())
    or exists (select 1 from public.asistentes where id = auth.uid())
  )
  with check (
    exists (select 1 from public.admins where id = auth.uid())
    or exists (select 1 from public.asistentes where id = auth.uid())
  );

alter publication supabase_realtime add table public.movimientos_caja;
