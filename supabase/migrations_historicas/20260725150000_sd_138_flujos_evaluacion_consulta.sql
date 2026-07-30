-- SD-138 · Flujos independientes de evaluación y consulta.
--
-- La fila de consultas sigue siendo el contenedor longitudinal que ya usan
-- documentos, odontograma y signos vitales. `tipo_atencion` declara qué acto
-- abrió el doctor; no convierte una evaluación en una ejecución facturable.

do $$
begin
  if not exists (select 1 from pg_type where typname = 'tipo_atencion_clinica') then
    create type public.tipo_atencion_clinica as enum ('evaluacion', 'consulta');
  end if;
end $$;

alter table public.consultas
  add column if not exists tipo_atencion public.tipo_atencion_clinica
    not null default 'consulta';

comment on column public.consultas.tipo_atencion is
  'Evaluación = documenta hallazgos y plan; consulta = registra ejecución clínica.';

-- Sobrecarga transaccional de la RPC existente. Se conserva la firma anterior
-- para clientes desplegados antes de SD-138; la app nueva envía el parámetro
-- adicional y PostgREST resuelve esta firma sin ambigüedad.
create or replace function public.crear_consulta_completa(
  p_paciente_id uuid,
  p_doctor_id uuid,
  p_cita_id uuid,
  p_fecha timestamptz,
  p_motivo_consulta text,
  p_temp_condiciones jsonb,
  p_dientes jsonb,
  p_documentos jsonb,
  p_tipo_atencion public.tipo_atencion_clinica
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_consulta_id uuid;
begin
  v_consulta_id := public.crear_consulta_completa(
    p_paciente_id,
    p_doctor_id,
    p_cita_id,
    p_fecha,
    p_motivo_consulta,
    p_temp_condiciones,
    p_dientes,
    p_documentos
  );

  update public.consultas
     set tipo_atencion = p_tipo_atencion,
         updated_at = now()
   where id = v_consulta_id;

  return v_consulta_id;
end;
$$;

grant execute on function public.crear_consulta_completa(
  uuid, uuid, uuid, timestamptz, text, jsonb, jsonb, jsonb,
  public.tipo_atencion_clinica
) to authenticated;

alter table public.tratamientos_aplicados
  add column if not exists justificacion_no_planificada text;

-- Los registros anteriores a SD-138 no podían declarar esta procedencia. Se
-- conserva esa verdad explícitamente antes de endurecer el contrato para las
-- escrituras nuevas.
update public.tratamientos_aplicados
set justificacion_no_planificada =
      'Registro histórico anterior a la separación de actividades planificadas.'
where item_plan_id is null
  and nullif(btrim(justificacion_no_planificada), '') is null;

alter table public.tratamientos_aplicados
  drop constraint if exists tratamientos_origen_ejecucion_requerido;
alter table public.tratamientos_aplicados
  add constraint tratamientos_origen_ejecucion_requerido check (
    item_plan_id is not null
    or nullif(btrim(justificacion_no_planificada), '') is not null
  );

comment on column public.tratamientos_aplicados.justificacion_no_planificada is
  'Motivo clínico obligatorio cuando item_plan_id es NULL (SD-138).';

-- Una actividad ejecutada no puede seguir apareciendo como pendiente en la
-- próxima consulta. La misma escritura que registra lo realizado actualiza el
-- plan; los reintentos del autoguardado son idempotentes.
create or replace function public.marcar_item_plan_ejecutado()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.item_plan_id is null then
    return new;
  end if;

  if new.deleted_at is not null then
    if not exists (
      select 1
      from public.tratamientos_aplicados otra
      where otra.item_plan_id = new.item_plan_id
        and otra.id <> new.id
        and otra.deleted_at is null
    ) then
      update public.items_plan_tratamiento
         set estado = 'pendiente',
             fecha_completado = null,
             updated_at = now()
       where id = new.item_plan_id
         and deleted_at is null;
    end if;
    return new;
  end if;

  update public.items_plan_tratamiento
     set estado = case
           when new.estado = 'en_proceso' then 'en_proceso'::public.estado_item_plan
           else 'completado'::public.estado_item_plan
         end,
         fecha_inicio = coalesce(fecha_inicio, new.fecha_ejecucion, now()),
         fecha_completado = case
           when new.estado = 'en_proceso' then fecha_completado
           else coalesce(fecha_completado, new.fecha_ejecucion, now())
         end,
         updated_at = now()
   where id = new.item_plan_id
     and deleted_at is null;
  return new;
end;
$$;

drop trigger if exists trg_marcar_item_plan_ejecutado
  on public.tratamientos_aplicados;
create trigger trg_marcar_item_plan_ejecutado
after insert or update of estado, item_plan_id, deleted_at
on public.tratamientos_aplicados
for each row execute function public.marcar_item_plan_ejecutado();
