-- ============================================================================
--  SD-146 · Vincular citas con actividades planificadas del plan de tratamiento
--
--  Una cita deja de describir con texto libre lo que se piensa tratar: apunta a
--  las actividades del plan (`items_plan_tratamiento`) que se van a atender en
--  esa sesión. El motivo declarado por el paciente (`citas.motivo`) sigue
--  existiendo y no se sustituye: son dos cosas distintas —lo que el paciente
--  dice y lo que la clínica planificó—.
--
--  Tres piezas:
--
--   1. `citas_items_plan`: el puente. Muchas actividades por cita y una misma
--      actividad puede reprogramarse a otra cita, así que la relación es N:M.
--
--   2. `trg_validar_cita_item_plan`: la actividad tiene que ser del MISMO
--      paciente de la cita, estar viva y no estar ya decidida en contra
--      (rechazada/cancelada) ni cerrada (completada). La app lo filtra al
--      ofrecer la lista, pero la última palabra vive aquí — hay caminos que no
--      pasan por la app (SD-160 aplicó la misma regla a la cancelación).
--
--   3. Dos vistas de solo lectura con el resumen mínimo. Existen por RLS: las
--      citas las gestiona el ASISTENTE (ver `citas_insert`), y el asistente no
--      puede leer `planes_tratamiento`, `items_plan_tratamiento`, `tratamientos`
--      ni `dientes` (todas admin-or-doctor). Sin las vistas, quien agenda no
--      podría elegir la actividad ni ver el resumen en la agenda.
--
--      Las vistas exponen solo lo que la agenda necesita —procedimiento, pieza,
--      cara, estado, precio estimado—; NO el diagnóstico que la originó, ni las
--      notas clínicas, ni el motivo de un rechazo. Son propiedad de `postgres`
--      y sin `security_invoker`, así que atraviesan RLS; por eso llevan dentro
--      la misma comprobación de rol que la política `citas_select`.
--
--  Idempotente. Aplicar con:
--    supabase db query --linked -f supabase/migrations/20260730150000_sd_146_citas_actividades_planificadas.sql
--  y registrar la versión en `supabase_migrations.schema_migrations`.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Puente cita ↔ actividad planificada
-- ---------------------------------------------------------------------------
create table if not exists public.citas_items_plan (
  cita_id      uuid not null references public.citas(id) on delete cascade,
  item_plan_id uuid not null references public.items_plan_tratamiento(id) on delete cascade,
  created_at   timestamptz not null default now(),
  constraint citas_items_plan_pkey primary key (cita_id, item_plan_id)
);

comment on table public.citas_items_plan is
  'Actividades del plan de tratamiento que se piensan atender en una cita (SD-146). Relación N:M: una cita puede cubrir varias actividades y una actividad puede reprogramarse a otra cita.';

-- La PK ya cubre las búsquedas por cita; este índice sirve al camino inverso
-- (¿en qué citas está agendada esta actividad?).
create index if not exists idx_citas_items_plan_item
  on public.citas_items_plan (item_plan_id);

-- ---------------------------------------------------------------------------
-- 2. La actividad vinculada tiene que ser del paciente de la cita y estar viva
-- ---------------------------------------------------------------------------
create or replace function public.validar_cita_item_plan()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_paciente_cita uuid;
  v_paciente_item uuid;
  v_estado        estado_item_plan;
  v_anulada       timestamptz;
begin
  select persona_id into v_paciente_cita
    from citas
   where id = new.cita_id and deleted_at is null;

  if v_paciente_cita is null then
    raise exception 'La cita % no existe o fue eliminada.', new.cita_id
      using errcode = '23503';
  end if;

  select pt.paciente_id, ipt.estado, ipt.deleted_at
    into v_paciente_item, v_estado, v_anulada
    from items_plan_tratamiento ipt
    join planes_tratamiento pt on pt.id = ipt.plan_id
   where ipt.id = new.item_plan_id
     and pt.deleted_at is null;

  if v_paciente_item is null then
    raise exception 'La actividad % no existe o su plan fue eliminado.', new.item_plan_id
      using errcode = '23503';
  end if;

  if v_anulada is not null then
    raise exception 'La actividad % fue retirada del plan y no puede agendarse.', new.item_plan_id
      using errcode = '23514';
  end if;

  if v_paciente_item <> v_paciente_cita then
    raise exception 'La actividad % pertenece al plan de otro paciente.', new.item_plan_id
      using errcode = '23514';
  end if;

  -- Agendar algo ya rechazado, cancelado o terminado no es una decisión válida:
  -- es un defecto de quien llama.
  if v_estado in ('rechazado', 'cancelado', 'completado') then
    raise exception 'La actividad % está %; no puede agendarse.', new.item_plan_id, v_estado
      using errcode = '23514';
  end if;

  return new;
end;
$$;

comment on function public.validar_cita_item_plan() is
  'SD-146. Impide vincular a una cita una actividad de otro paciente, retirada del plan o ya decidida en contra/terminada.';

drop trigger if exists trg_validar_cita_item_plan on public.citas_items_plan;
create trigger trg_validar_cita_item_plan
  before insert or update on public.citas_items_plan
  for each row execute function public.validar_cita_item_plan();

-- ---------------------------------------------------------------------------
-- 3. RLS del puente: mismo alcance que `citas`, porque es parte de agendar
-- ---------------------------------------------------------------------------
alter table public.citas_items_plan enable row level security;

drop policy if exists citas_items_plan_select on public.citas_items_plan;
drop policy if exists citas_items_plan_insert on public.citas_items_plan;
drop policy if exists citas_items_plan_delete on public.citas_items_plan;

create policy citas_items_plan_select on public.citas_items_plan
  for select to authenticated
  using (es_admin() or es_doctor() or es_asistente());

create policy citas_items_plan_insert on public.citas_items_plan
  for insert to authenticated
  with check (es_admin() or es_doctor() or es_asistente());

create policy citas_items_plan_delete on public.citas_items_plan
  for delete to authenticated
  using (es_admin() or es_doctor() or es_asistente());

-- No hay política de UPDATE a propósito: la fila son dos claves y una fecha.
-- Cambiar el vínculo es borrar uno y crear otro.

grant select, insert, delete on table public.citas_items_plan to authenticated;
grant all on table public.citas_items_plan to service_role;

-- ---------------------------------------------------------------------------
-- 4. Resumen de las actividades de cada cita (lo que pinta la agenda)
-- ---------------------------------------------------------------------------
create or replace view public.resumen_actividades_cita as
select
  cip.cita_id,
  ipt.id                as item_plan_id,
  ipt.plan_id,
  ipt.tratamiento_id,
  t.nombre              as tratamiento_nombre,
  d.fdi_code            as fdi_diente,
  ipt.superficie,
  ipt.estado,
  ipt.precio_estimado,
  ipt.orden
from citas_items_plan cip
join items_plan_tratamiento ipt on ipt.id = cip.item_plan_id
join planes_tratamiento pt      on pt.id = ipt.plan_id
left join tratamientos t        on t.id = ipt.tratamiento_id
left join dientes d             on d.id = ipt.diente_id
where ipt.deleted_at is null
  and pt.deleted_at is null
  and (es_admin() or es_doctor() or es_asistente());

comment on view public.resumen_actividades_cita is
  'SD-146. Resumen mínimo de las actividades planificadas de cada cita, legible por el asistente que agenda. No expone diagnóstico ni notas clínicas.';

-- ---------------------------------------------------------------------------
-- 5. Actividades que se pueden agendar de un paciente (lo que ofrece el
--    formulario de la cita)
-- ---------------------------------------------------------------------------
create or replace view public.actividades_agendables_paciente as
select
  pt.paciente_id,
  ipt.id       as item_plan_id,
  ipt.plan_id,
  ipt.tratamiento_id,
  t.nombre     as tratamiento_nombre,
  d.fdi_code   as fdi_diente,
  ipt.superficie,
  ipt.estado,
  ipt.precio_estimado,
  ipt.orden
from items_plan_tratamiento ipt
join planes_tratamiento pt on pt.id = ipt.plan_id
left join tratamientos t   on t.id = ipt.tratamiento_id
left join dientes d        on d.id = ipt.diente_id
where ipt.deleted_at is null
  and pt.deleted_at is null
  -- Lo mismo que admite el trigger: propuesto entra porque una cita también
  -- sirve para presentarle al paciente lo que aún no ha decidido.
  and ipt.estado in ('propuesto', 'aceptado', 'pendiente', 'en_proceso')
  and (es_admin() or es_doctor() or es_asistente());

comment on view public.actividades_agendables_paciente is
  'SD-146. Actividades del plan de un paciente que todavía pueden agendarse en una cita. Mismo alcance de estados que acepta trg_validar_cita_item_plan.';

grant select on table public.resumen_actividades_cita to authenticated;
grant select on table public.actividades_agendables_paciente to authenticated;

-- `alter default privileges` de Supabase concede ALL a `anon` sobre cada tabla
-- y vista nueva. En una tabla con RLS eso es inocuo, pero estas vistas la
-- atraviesan: sin revocar, un token anónimo podría leerlas. Hoy no devolverían
-- nada —el filtro de rol de dentro no lo cumple `anon`—, pero la defensa no
-- debe depender de una sola línea del WHERE.
revoke all on table public.resumen_actividades_cita from anon;
revoke all on table public.actividades_agendables_paciente from anon;
revoke all on table public.citas_items_plan from anon;
revoke all on function public.validar_cita_item_plan() from anon;
