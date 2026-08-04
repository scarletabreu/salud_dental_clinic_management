-- SD-124 · El registro de mantenimiento y la fecha vigente del equipo
-- cambian como una sola operación para evitar estados parciales.
create or replace function public.registrar_mantenimiento_equipo(
  p_equipo_id uuid,
  p_suplidor_id uuid,
  p_costo numeric,
  p_fecha_mantenimiento timestamptz,
  p_descripcion text default 'Mantenimiento'
) returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_mantenimiento_id uuid;
begin
  if p_costo < 0 then
    raise exception 'El costo no puede ser negativo.' using errcode = '22023';
  end if;

  if p_fecha_mantenimiento::date > current_date then
    raise exception 'La fecha de mantenimiento no puede estar en el futuro.'
      using errcode = '22023';
  end if;

  insert into public.equipos_mantenimientos (
    equipo_id,
    suplidor_id,
    descripcion,
    costo,
    fecha_mantenimiento
  ) values (
    p_equipo_id,
    p_suplidor_id,
    coalesce(nullif(trim(p_descripcion), ''), 'Mantenimiento'),
    p_costo,
    p_fecha_mantenimiento
  )
  returning id into v_mantenimiento_id;

  update public.equipos
     set ultimo_mantenimiento = p_fecha_mantenimiento,
         updated_at = now()
   where id = p_equipo_id
     and deleted_at is null;

  if not found then
    raise exception 'El equipo no existe o fue eliminado.' using errcode = 'P0002';
  end if;

  return v_mantenimiento_id;
end;
$$;

grant execute on function public.registrar_mantenimiento_equipo(
  uuid, uuid, numeric, timestamptz, text
) to authenticated;

drop policy if exists equipos_mantenimientos_insert
  on public.equipos_mantenimientos;
create policy equipos_mantenimientos_insert
  on public.equipos_mantenimientos
  for insert
  to authenticated
  with check (public.es_admin() or public.es_asistente());
