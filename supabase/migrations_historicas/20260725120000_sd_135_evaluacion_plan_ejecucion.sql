-- SD-135 · Separar evaluación, plan de tratamiento y ejecución clínica.
--
-- Hasta ahora los tres momentos clínicos vivían mezclados: `diagnosticos_aplicados`
-- hacía de evaluación, `tratamientos_aplicados.estado = 'indicado'` hacía de plan
-- (SD-150) y esa misma tabla hacía de ejecución. Una indicación quedaba así a un
-- flag de distancia de entrar en la pre-factura.
--
-- Este esquema separa los ejes:
--   · evaluaciones_clinicas → el acto de evaluar. Sus hallazgos son las filas de
--     `diagnosticos_aplicados`. Puede registrar cualquier cantidad.
--   · planes_tratamiento + items_plan_tratamiento → lo que se decide tratar. Solo
--     un subconjunto de los hallazgos llega aquí, y llega por decisión explícita.
--   · tratamientos_aplicados → exclusivamente lo ejecutado. Es el único eje que
--     factura.
--
-- Aditiva e idempotente. Ejecutar después de SD-150.

-- ---------------------------------------------------------------------------
-- 1. Estados
-- ---------------------------------------------------------------------------

-- Un solo ciclo de vida para la actividad planificada. `pendiente` es la
-- actividad aceptada que aún no arranca; `en_proceso` la que ya empezó (un
-- conducto en varias sesiones); `completado` la que cerró su ejecución.
do $$
begin
  if not exists (select 1 from pg_type where typname = 'estado_item_plan') then
    create type public.estado_item_plan as enum (
      'propuesto',
      'aceptado',
      'rechazado',
      'pendiente',
      'en_proceso',
      'completado',
      'cancelado'
    );
  end if;
end $$;

-- El encabezado del plan usa el mismo vocabulario menos `pendiente`, que solo
-- tiene sentido por actividad. Se reutiliza el enum para no duplicar términos.
do $$
begin
  if not exists (select 1 from pg_type where typname = 'estado_plan_tratamiento') then
    create type public.estado_plan_tratamiento as enum (
      'borrador',
      'propuesto',
      'aceptado',
      'rechazado',
      'en_proceso',
      'completado',
      'cancelado'
    );
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- 2. Evaluación clínica
-- ---------------------------------------------------------------------------

create table if not exists public.evaluaciones_clinicas (
  id            uuid primary key default gen_random_uuid(),
  paciente_id   uuid not null references public.pacientes(id) on delete restrict,
  consulta_id   uuid references public.consultas(id) on delete restrict,
  doctor_id     uuid not null references public.doctores(id) on delete restrict,
  fecha         timestamptz not null default now(),
  motivo        text,
  resumen       text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz
);

comment on table public.evaluaciones_clinicas is
  'Acto de evaluar al paciente. Sus hallazgos son las filas de diagnosticos_aplicados. '
  'Registrar un hallazgo aquí NO crea tratamiento aplicado ni cuenta (SD-135).';

-- Una consulta produce una evaluación. Fuera de consulta (revisión, urgencia
-- sin consulta abierta) `consulta_id` queda NULL y el índice no aplica.
create unique index if not exists uq_evaluaciones_clinicas_consulta
  on public.evaluaciones_clinicas (consulta_id)
  where consulta_id is not null and deleted_at is null;

create index if not exists idx_evaluaciones_clinicas_paciente
  on public.evaluaciones_clinicas (paciente_id, fecha desc)
  where deleted_at is null;

-- El hallazgo cuelga de la evaluación que lo produjo.
alter table public.diagnosticos_aplicados
  add column if not exists evaluacion_id uuid references public.evaluaciones_clinicas(id);

create index if not exists idx_diagnosticos_aplicados_evaluacion
  on public.diagnosticos_aplicados (evaluacion_id)
  where deleted_at is null;

-- ---------------------------------------------------------------------------
-- 3. Plan de tratamiento
-- ---------------------------------------------------------------------------

create table if not exists public.planes_tratamiento (
  id                 uuid primary key default gen_random_uuid(),
  paciente_id        uuid not null references public.pacientes(id) on delete restrict,
  evaluacion_id      uuid references public.evaluaciones_clinicas(id) on delete restrict,
  consulta_origen_id uuid references public.consultas(id) on delete restrict,
  doctor_id          uuid not null references public.doctores(id) on delete restrict,
  estado             public.estado_plan_tratamiento not null default 'borrador',
  notas              text,
  fecha_propuesta    timestamptz not null default now(),
  fecha_aceptacion   timestamptz,
  fecha_rechazo      timestamptz,
  motivo_rechazo     text,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  deleted_at         timestamptz
);

comment on table public.planes_tratamiento is
  'Lo que se decide tratar. Agrupa las actividades propuestas al paciente a partir '
  'de una evaluación; solo un subconjunto de los hallazgos llega aquí.';

create index if not exists idx_planes_tratamiento_paciente
  on public.planes_tratamiento (paciente_id, fecha_propuesta desc)
  where deleted_at is null;

create index if not exists idx_planes_tratamiento_evaluacion
  on public.planes_tratamiento (evaluacion_id)
  where deleted_at is null;

create table if not exists public.items_plan_tratamiento (
  id                     uuid primary key default gen_random_uuid(),
  plan_id                uuid not null references public.planes_tratamiento(id) on delete cascade,
  tratamiento_id         uuid not null references public.tratamientos(id) on delete restrict,
  -- Hallazgo que justifica la actividad. NULL = actividad sin hallazgo previo
  -- (profilaxis, estética), que es legítima: el vínculo es opcional en un
  -- sentido y prohibido en el otro (un hallazgo nunca crea un item por sí solo).
  diagnostico_aplicado_id uuid references public.diagnosticos_aplicados(id) on delete set null,
  diente_id              uuid references public.dientes(id) on delete restrict,
  superficie             public.tipo_superficie,
  estado                 public.estado_item_plan not null default 'propuesto',
  -- Precio del catálogo al proponer. Es una estimación: no factura, la
  -- pre-factura sigue leyendo `tratamientos_aplicados.precio_aplicado`.
  precio_estimado        numeric(15,2) not null default 0,
  orden                  integer not null default 0,
  notas                  text,
  doctor_propone_id      uuid references public.doctores(id) on delete restrict,
  fecha_propuesta        timestamptz not null default now(),
  fecha_aceptacion       timestamptz,
  fecha_rechazo          timestamptz,
  motivo_rechazo         text,
  fecha_inicio           timestamptz,
  fecha_completado       timestamptz,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  deleted_at             timestamptz,
  constraint items_plan_precio_no_negativo check (precio_estimado >= 0)
);

comment on table public.items_plan_tratamiento is
  'Actividad planificada sobre un diente/superficie. Su estado es la decisión '
  'clínica y del paciente; no genera cargo hasta ejecutarse.';

create index if not exists idx_items_plan_plan
  on public.items_plan_tratamiento (plan_id, orden)
  where deleted_at is null;

create index if not exists idx_items_plan_estado
  on public.items_plan_tratamiento (estado)
  where deleted_at is null;

create index if not exists idx_items_plan_diente
  on public.items_plan_tratamiento (diente_id)
  where deleted_at is null;

create index if not exists idx_items_plan_diagnostico
  on public.items_plan_tratamiento (diagnostico_aplicado_id)
  where deleted_at is null;

-- Coherencia de la auditoría: si hay decisión, hay fecha de decisión.
alter table public.items_plan_tratamiento
  drop constraint if exists items_plan_fechas_coherentes;
alter table public.items_plan_tratamiento
  add constraint items_plan_fechas_coherentes check (
    (estado <> 'rechazado' or fecha_rechazo is not null)
    and (estado <> 'completado' or fecha_completado is not null)
  );

-- ---------------------------------------------------------------------------
-- 4. Ejecución clínica
-- ---------------------------------------------------------------------------

-- `tratamientos_aplicados` pasa a significar una sola cosa: se hizo. Se le
-- añade el vínculo con lo planificado (NULL = ejecución no planificada, p. ej.
-- una urgencia resuelta en el momento) y la auditoría de quién y cuándo.
alter table public.tratamientos_aplicados
  add column if not exists item_plan_id      uuid references public.items_plan_tratamiento(id) on delete set null,
  add column if not exists doctor_ejecuta_id uuid references public.doctores(id) on delete restrict,
  add column if not exists fecha_ejecucion   timestamptz;

create index if not exists idx_tratamientos_aplicados_item_plan
  on public.tratamientos_aplicados (item_plan_id)
  where deleted_at is null;

-- ---------------------------------------------------------------------------
-- 5. Migración de datos
-- ---------------------------------------------------------------------------

-- 5.1 Una evaluación por consulta con actividad clínica registrada.
insert into public.evaluaciones_clinicas (
  paciente_id, consulta_id, doctor_id, fecha, motivo, created_at, updated_at
)
select c.paciente_id, c.id, c.doctor_id, c.fecha, c.motivo_consulta, now(), now()
from public.consultas c
where c.deleted_at is null
  and not exists (
    select 1 from public.evaluaciones_clinicas e
    where e.consulta_id = c.id and e.deleted_at is null
  );

-- 5.2 Cada hallazgo existente queda colgado de la evaluación de su consulta.
update public.diagnosticos_aplicados da
set evaluacion_id = e.id,
    updated_at = now()
from public.evaluaciones_clinicas e
where da.evaluacion_id is null
  and da.consulta_id is not null
  and e.consulta_id = da.consulta_id
  and e.deleted_at is null;

-- 5.3 Las indicaciones de SD-150 dejan de ser «tratamiento aplicado a medias» y
--     pasan a ser actividad propuesta del plan. Un plan por consulta que tenga
--     indicaciones.
insert into public.planes_tratamiento (
  paciente_id, evaluacion_id, consulta_origen_id, doctor_id, estado,
  notas, fecha_propuesta, created_at, updated_at
)
select distinct on (c.id)
       c.paciente_id, e.id, c.id, c.doctor_id, 'propuesto'::public.estado_plan_tratamiento,
       'Plan reconstruido desde las indicaciones registradas antes de SD-135.',
       c.fecha, now(), now()
from public.tratamientos_aplicados ta
join public.consultas c on c.id = ta.consulta_id and c.deleted_at is null
left join public.evaluaciones_clinicas e on e.consulta_id = c.id and e.deleted_at is null
where ta.deleted_at is null
  and ta.estado = 'indicado'
  and not exists (
    select 1 from public.planes_tratamiento p
    where p.consulta_origen_id = c.id and p.deleted_at is null
  );

insert into public.items_plan_tratamiento (
  plan_id, tratamiento_id, diente_id, superficie, estado, precio_estimado,
  notas, doctor_propone_id, fecha_propuesta, created_at, updated_at
)
select p.id, ta.tratamiento_id, ta.diente_id, ta.superficie,
       'propuesto'::public.estado_item_plan,
       coalesce(ta.precio_aplicado, t.costo, 0),
       ta.notas, c.doctor_id, coalesce(ta.created_at, c.fecha), now(), now()
from public.tratamientos_aplicados ta
join public.consultas c on c.id = ta.consulta_id and c.deleted_at is null
join public.planes_tratamiento p
  on p.consulta_origen_id = c.id and p.deleted_at is null
left join public.tratamientos t on t.id = ta.tratamiento_id
where ta.deleted_at is null
  and ta.estado = 'indicado'
  and not exists (
    select 1 from public.items_plan_tratamiento i
    where i.plan_id = p.id
      and i.tratamiento_id = ta.tratamiento_id
      and i.diente_id is not distinct from ta.diente_id
      and i.superficie is not distinct from ta.superficie
      and i.deleted_at is null
  );

-- Las indicaciones migradas salen del eje de ejecución. Borrado lógico: la fila
-- histórica se conserva, pero deja de contar como procedimiento realizado y de
-- ser visible para la pre-factura.
update public.tratamientos_aplicados ta
set deleted_at = now(),
    updated_at = now()
where ta.deleted_at is null
  and ta.estado = 'indicado';

-- `dientes.tratamientos_aplicados_ids` es el puente que la app usa para pintar
-- la pieza; hay que sacar de ahí los ids que acaban de dejar de ser ejecución.
update public.dientes d
set tratamientos_aplicados_ids = coalesce((
      select array_agg(x)
      from unnest(d.tratamientos_aplicados_ids) as x
      join public.tratamientos_aplicados ta on ta.id = x
      where ta.deleted_at is null
    ), '{}'::uuid[]),
    updated_at = now()
where d.deleted_at is null
  and exists (
    select 1 from unnest(d.tratamientos_aplicados_ids) as x
    join public.tratamientos_aplicados ta on ta.id = x
    where ta.deleted_at is not null
  );

-- 5.4 Auditoría de la ejecución ya registrada: el doctor de la consulta la hizo,
--     en la fecha en que se anotó.
update public.tratamientos_aplicados ta
set doctor_ejecuta_id = coalesce(ta.doctor_ejecuta_id, c.doctor_id),
    fecha_ejecucion   = coalesce(ta.fecha_ejecucion, ta.created_at, c.fecha),
    updated_at        = now()
from public.consultas c
where c.id = ta.consulta_id
  and ta.deleted_at is null
  and (ta.doctor_ejecuta_id is null or ta.fecha_ejecucion is null);

-- ---------------------------------------------------------------------------
-- 6. La regla dura: un hallazgo no genera ejecución ni cuenta
-- ---------------------------------------------------------------------------

-- Sin `indicado`, la tabla no puede volver a albergar algo no ejecutado. El
-- plan es el único lugar donde vive una intención.
--
-- La restricción exime a las filas archivadas: las indicaciones que el paso 5.3
-- movió al plan se conservan con su `estado` original como registro histórico.
-- Reescribirles el estado sería falsear lo que decía el expediente; lo que
-- importa es que ninguna fila viva pueda volver a ser una intención.
alter table public.tratamientos_aplicados
  drop constraint if exists tratamientos_aplicados_solo_ejecucion;
alter table public.tratamientos_aplicados
  add constraint tratamientos_aplicados_solo_ejecucion
  check (
    deleted_at is not null
    or estado in ('aplicado', 'en_proceso', 'completado')
  )
  not valid;

-- Se valida aparte para que una fila histórica corrupta no aborte la migración
-- entera; si alguna queda fuera del dominio, este paso lo dirá con su id.
do $$
begin
  alter table public.tratamientos_aplicados
    validate constraint tratamientos_aplicados_solo_ejecucion;
exception when check_violation then
  raise warning 'Quedan tratamientos_aplicados con estado fuera de (aplicado, en_proceso, completado). '
                'La restricción queda NOT VALID: revísalos y ejecuta VALIDATE CONSTRAINT.';
end $$;

-- Un item del plan solo puede quedar vinculado a una ejecución cuando ya se
-- decidió ejecutarlo. Cierra la puerta a que aceptar/proponer facture.
create or replace function public.verificar_item_plan_ejecutable()
returns trigger
language plpgsql
as $$
declare
  v_estado public.estado_item_plan;
begin
  if new.item_plan_id is null then
    return new;
  end if;

  select estado into v_estado
  from public.items_plan_tratamiento
  where id = new.item_plan_id and deleted_at is null;

  if v_estado is null then
    raise exception 'El item de plan % no existe o fue eliminado.', new.item_plan_id;
  end if;

  if v_estado in ('propuesto', 'rechazado', 'cancelado') then
    raise exception
      'No se puede registrar la ejecución de una actividad en estado %. '
      'Debe estar aceptada, pendiente, en proceso o completada.', v_estado;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_item_plan_ejecutable on public.tratamientos_aplicados;
create trigger trg_item_plan_ejecutable
  before insert or update of item_plan_id on public.tratamientos_aplicados
  for each row execute function public.verificar_item_plan_ejecutable();

-- ---------------------------------------------------------------------------
-- 7. Pre-factura: solo ejecución
-- ---------------------------------------------------------------------------

-- Misma firma y contrato que la vigente (20260725100000) —incluida la
-- normalización del método de pago y la idempotencia—. Lo único que cambia es
-- el criterio de cobro: ahora **toda** fila viva de `tratamientos_aplicados`
-- factura, porque desde SD-135 esa tabla solo contiene ejecución. El filtro por
-- `estado = 'aplicado'` de SD-150 se sustituye por la exclusión explícita del
-- valor heredado `indicado`, que ya no puede volver a entrar (CHECK del paso 6)
-- pero podría sobrevivir en una instalación cuya validación quedara NOT VALID.
create or replace function public.finalizar_consulta(
  p_consulta_id uuid,
  p_metodo_pago text default 'contado',
  p_nota        text default null
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_paciente_id uuid;
  v_cita_id     uuid;
  v_cuenta_id   uuid;
  v_monto_total numeric(12,2);
  v_metodo_pago modo_pago;
begin
  -- El método llega como texto desde la app; la columna es el enum `modo_pago`.
  begin
    v_metodo_pago := lower(btrim(coalesce(p_metodo_pago, 'contado')))::modo_pago;
  exception when invalid_text_representation then
    raise exception 'Método de pago inválido: %. Valores admitidos: contado, credito.',
      p_metodo_pago using errcode = '22023';
  end;

  select paciente_id, cita_id into v_paciente_id, v_cita_id
  from consultas where id = p_consulta_id and deleted_at is null;
  if v_paciente_id is null then
    raise exception 'La consulta % no existe o fue eliminada.', p_consulta_id;
  end if;

  -- Idempotencia: reintentar finalizar no duplica la pre-factura.
  select id into v_cuenta_id from cuentas
  where consulta_id = p_consulta_id and deleted_at is null limit 1;
  if v_cuenta_id is not null then return v_cuenta_id; end if;

  -- Solo procedimientos ejecutados. Las actividades del plan (propuestas,
  -- aceptadas o pendientes) y los hallazgos de la evaluación no facturan.
  select coalesce(sum(precio_aplicado), 0) into v_monto_total
  from tratamientos_aplicados
  where consulta_id = p_consulta_id
    and deleted_at is null
    and coalesce(estado, 'aplicado') <> 'indicado';

  insert into cuentas (
    paciente_id, consulta_id, estado, monto_total, metodo_pago,
    fecha_creacion, nota, created_at, updated_at
  ) values (
    v_paciente_id, p_consulta_id, 'abierta', v_monto_total, v_metodo_pago,
    now(), p_nota, now(), now()
  ) returning id into v_cuenta_id;

  insert into items_cuenta (
    cuenta_id, descripcion, precio_unitario, cantidad, created_at, updated_at
  )
  select v_cuenta_id, coalesce(t.nombre, 'Tratamiento'),
         coalesce(ta.precio_aplicado, 0), 1, now(), now()
  from tratamientos_aplicados ta
  left join tratamientos t on t.id = ta.tratamiento_id
  where ta.consulta_id = p_consulta_id
    and ta.deleted_at is null
    and coalesce(ta.estado, 'aplicado') <> 'indicado';

  if v_cita_id is not null then
    update citas set estado = 'completada'::estado_cita, updated_at = now()
    where id = v_cita_id;
  end if;

  return v_cuenta_id;
end;
$$;

grant execute on function public.finalizar_consulta(uuid, text, text) to authenticated, anon;

-- ---------------------------------------------------------------------------
-- 8. RLS — grupo clínico, igual que el resto del expediente
-- ---------------------------------------------------------------------------

alter table public.evaluaciones_clinicas   enable row level security;
alter table public.planes_tratamiento      enable row level security;
alter table public.items_plan_tratamiento  enable row level security;

drop policy if exists evaluaciones_clinicas_select on public.evaluaciones_clinicas;
drop policy if exists evaluaciones_clinicas_insert on public.evaluaciones_clinicas;
drop policy if exists evaluaciones_clinicas_update on public.evaluaciones_clinicas;
drop policy if exists evaluaciones_clinicas_delete on public.evaluaciones_clinicas;
create policy evaluaciones_clinicas_select on public.evaluaciones_clinicas for select to authenticated using (es_admin() or es_doctor());
create policy evaluaciones_clinicas_insert on public.evaluaciones_clinicas for insert to authenticated with check (es_admin() or es_doctor());
create policy evaluaciones_clinicas_update on public.evaluaciones_clinicas for update to authenticated using (es_admin() or es_doctor()) with check (es_admin() or es_doctor());
create policy evaluaciones_clinicas_delete on public.evaluaciones_clinicas for delete to authenticated using (es_admin() or es_doctor());

drop policy if exists planes_tratamiento_select on public.planes_tratamiento;
drop policy if exists planes_tratamiento_insert on public.planes_tratamiento;
drop policy if exists planes_tratamiento_update on public.planes_tratamiento;
drop policy if exists planes_tratamiento_delete on public.planes_tratamiento;
create policy planes_tratamiento_select on public.planes_tratamiento for select to authenticated using (es_admin() or es_doctor());
create policy planes_tratamiento_insert on public.planes_tratamiento for insert to authenticated with check (es_admin() or es_doctor());
create policy planes_tratamiento_update on public.planes_tratamiento for update to authenticated using (es_admin() or es_doctor()) with check (es_admin() or es_doctor());
create policy planes_tratamiento_delete on public.planes_tratamiento for delete to authenticated using (es_admin() or es_doctor());

drop policy if exists items_plan_tratamiento_select on public.items_plan_tratamiento;
drop policy if exists items_plan_tratamiento_insert on public.items_plan_tratamiento;
drop policy if exists items_plan_tratamiento_update on public.items_plan_tratamiento;
drop policy if exists items_plan_tratamiento_delete on public.items_plan_tratamiento;
create policy items_plan_tratamiento_select on public.items_plan_tratamiento for select to authenticated using (es_admin() or es_doctor());
create policy items_plan_tratamiento_insert on public.items_plan_tratamiento for insert to authenticated with check (es_admin() or es_doctor());
create policy items_plan_tratamiento_update on public.items_plan_tratamiento for update to authenticated using (es_admin() or es_doctor()) with check (es_admin() or es_doctor());
create policy items_plan_tratamiento_delete on public.items_plan_tratamiento for delete to authenticated using (es_admin() or es_doctor());
