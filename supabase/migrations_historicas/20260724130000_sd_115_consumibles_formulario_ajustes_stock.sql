-- SD-115 · Datos operativos del consumible y ajustes de stock auditables.
-- El RPC bloquea la fila, evita existencias negativas y registra cada ajuste
-- en la misma transacción para que el inventario no requiera cambios manuales.

alter table public.consumibles
  add column if not exists precio numeric(12, 2) not null default 0,
  add column if not exists suplidor_id uuid references public.suplidores(id),
  add column if not exists activo boolean not null default true;

-- Conserva la semántica de las bajas que existían antes de la columna activo.
update public.consumibles
   set activo = false
 where deleted_at is not null;

alter table public.consumibles
  drop constraint if exists consumibles_precio_no_negativo,
  add constraint consumibles_precio_no_negativo check (precio >= 0),
  drop constraint if exists consumibles_stock_actual_no_negativo,
  add constraint consumibles_stock_actual_no_negativo check (stock_actual >= 0),
  drop constraint if exists consumibles_stock_minimo_no_negativo,
  add constraint consumibles_stock_minimo_no_negativo check (stock_minimo >= 0);

create unique index if not exists consumibles_nombre_activo_unico_idx
  on public.consumibles (lower(btrim(nombre)))
  where activo;

create table if not exists public.movimientos_stock_consumible (
  id uuid primary key default gen_random_uuid(),
  consumible_id uuid not null references public.consumibles(id),
  stock_anterior integer not null check (stock_anterior >= 0),
  stock_nuevo integer not null check (stock_nuevo >= 0),
  diferencia integer not null,
  motivo text not null check (motivo in ('merma', 'correccion', 'usoInterno')),
  creado_por uuid references auth.users(id),
  created_at timestamptz not null default now(),
  constraint movimientos_stock_consumible_diferencia_check
    check (diferencia = stock_nuevo - stock_anterior)
);

create index if not exists movimientos_stock_consumible_consumible_fecha_idx
  on public.movimientos_stock_consumible (consumible_id, created_at desc);

create or replace function public.ajustar_stock_consumible(
  p_consumible_id uuid,
  p_nuevo_stock integer,
  p_motivo text
)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_stock_anterior integer;
begin
  if p_nuevo_stock < 0 then
    raise exception 'El stock no puede ser negativo.' using errcode = '22023';
  end if;

  if p_motivo not in ('merma', 'correccion', 'usoInterno') then
    raise exception 'El motivo del ajuste no es válido.' using errcode = '22023';
  end if;

  select stock_actual
    into v_stock_anterior
    from public.consumibles
   where id = p_consumible_id
     and activo = true
   for update;

  if not found then
    raise exception 'No se encontró un consumible activo para ajustar.' using errcode = 'P0002';
  end if;

  update public.consumibles
     set stock_actual = p_nuevo_stock,
         estado = case
           when p_nuevo_stock <= 0 then 'agotado'
           when p_nuevo_stock <= stock_minimo then 'bajoStock'
           else 'disponible'
         end,
         updated_at = now()
   where id = p_consumible_id;

  insert into public.movimientos_stock_consumible (
    consumible_id, stock_anterior, stock_nuevo, diferencia, motivo, creado_por
  ) values (
    p_consumible_id,
    v_stock_anterior,
    p_nuevo_stock,
    p_nuevo_stock - v_stock_anterior,
    p_motivo,
    auth.uid()
  );
end;
$$;

alter table public.movimientos_stock_consumible enable row level security;

drop policy if exists "authenticated_read_movimientos_stock_consumible"
  on public.movimientos_stock_consumible;
create policy "authenticated_read_movimientos_stock_consumible"
  on public.movimientos_stock_consumible for select to authenticated using (true);

drop policy if exists "authenticated_adjust_stock_consumible"
  on public.movimientos_stock_consumible;
create policy "authenticated_adjust_stock_consumible"
  on public.movimientos_stock_consumible for insert to authenticated with check (true);

grant execute on function public.ajustar_stock_consumible(uuid, integer, text)
  to authenticated;
