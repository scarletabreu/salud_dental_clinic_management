-- HFX-QA-100 · Reconciliar el esquema del repositorio con el de producción.
--
-- Decisión del 1 ago 2026: **el modelo de producción es el oficial**. Todo lo
-- que la instancia remota acumuló a mano (Studio) y el repositorio nunca vio se
-- versiona aquí *tal cual*, para que `supabase db reset` reproduzca producción
-- y los arreglos de cliente de las fases siguientes se prueben contra la
-- realidad. Esta migración **no cambia el comportamiento de producción**: allí
-- todo esto ya existe y los `create ... if not exists` / `create or replace`
-- son no-ops.
--
-- Inventario de la deriva (dump remoto del 1 ago 2026 contra la base local):
--
--   Tablas sólo en producción   : auditoria_log, doctor_paciente, items_receta
--   Vista sólo en producción    : resumen_actividad_plan
--   Funciones sólo en producción: fn_auditoria_log, fn_autoasignar_doctor_paciente,
--                                 fn_cascade_deleted_at_doctor,
--                                 fn_cascade_deleted_at_usuario,
--                                 generar_codigo_receta
--   Triggers sólo en producción : 10 (auditoría, autoasignación, cascada de
--                                 borrado lógico, código de receta)
--   Función con cuerpo distinto : hfx_base_recibir_compra (producción va por
--                                 delante: registra movimiento de stock en vez
--                                 de tocar `stock_actual` a mano)
--   Policies de SELECT distintas: 14 tablas pasan de los tres roles planos a
--                                 las guardias `puede_ver_*` (HFX-CLIN-011)
--   Policy de UPDATE distinta   : consumibles_update incluye es_doctor()
--
-- Las vistas `pacientes_seguro` / `personas_seguro` / `contactos_seguro` NO se
-- versionan: están huérfanas y se retiran en la migración siguiente.
--
-- Nota sobre `to`: las policies de producción se crearon sin cláusula `to`, o
-- sea `to public`. Se reproducen igual para que local y remoto describan el
-- mismo esquema. Es inerte: HFX-CLIN-005/009 dejaron a `anon` sin ningún
-- privilegio de tabla en `public`, de modo que RLS ni siquiera llega a
-- evaluarse para una sesión anónima.

set check_function_bodies = off;

-- ---------------------------------------------------------------------------
-- 1. Secuencias
-- ---------------------------------------------------------------------------

create sequence if not exists public.auditoria_log_id_seq
    start with 1 increment by 1 no minvalue no maxvalue cache 1;

create sequence if not exists public.doctor_paciente_id_seq
    start with 1 increment by 1 no minvalue no maxvalue cache 1;

create sequence if not exists public.secuencia_codigo_receta
    start with 1 increment by 1 no minvalue no maxvalue cache 1;

-- ---------------------------------------------------------------------------
-- 2. `auditoria_log` — bitácora escrita por triggers `security definer`
-- ---------------------------------------------------------------------------
-- Guarda `to_jsonb(OLD)`/`to_jsonb(NEW)` completos de citas, consultas, cuentas
-- y pagos. HFX-CLIN-009 la cerró al cliente en producción; aquí nace ya cerrada
-- para que la base local no la exponga nunca (aquel bloque estaba guardado por
-- existencia y en local fue un no-op).

create table if not exists public.auditoria_log (
    id          bigint not null default nextval('public.auditoria_log_id_seq'::regclass),
    usuario_id  uuid,
    accion      character varying(20) not null,
    entidad     character varying(50) not null,
    entidad_id  text not null,
    detalles    jsonb,
    fecha       timestamp with time zone default now()
);

alter sequence public.auditoria_log_id_seq owned by public.auditoria_log.id;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'auditoria_log_pkey'
  ) then
    alter table only public.auditoria_log
      add constraint auditoria_log_pkey primary key (id);
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'auditoria_log_usuario_id_fkey'
  ) then
    alter table only public.auditoria_log
      add constraint auditoria_log_usuario_id_fkey
      foreign key (usuario_id) references public.usuarios(id) on delete set null;
  end if;
end;
$$;

create index if not exists idx_auditoria_entidad on public.auditoria_log using btree (entidad, entidad_id);
create index if not exists idx_auditoria_fecha   on public.auditoria_log using btree (fecha);
create index if not exists idx_auditoria_usuario on public.auditoria_log using btree (usuario_id);

alter table public.auditoria_log enable row level security;
revoke all on table public.auditoria_log from anon, authenticated;
grant all on table public.auditoria_log to service_role;

-- ---------------------------------------------------------------------------
-- 3. `doctor_paciente` — el corazón del modelo restrictivo de producción
-- ---------------------------------------------------------------------------
-- `puede_ver_paciente()` (HFX-CLIN-011) consulta esta tabla. Sin ella, la
-- guardia existía en local pero ninguna policy la invocaba: la base local
-- describía un modelo de permisos que no era el real.

create table if not exists public.doctor_paciente (
    id                bigint not null default nextval('public.doctor_paciente_id_seq'::regclass),
    doctor_id         uuid not null,
    paciente_id       uuid not null,
    fecha_asignacion  timestamp with time zone default now() not null,
    fecha_fin         timestamp with time zone,
    activo            boolean default true not null,
    asignado_por      uuid,
    motivo            text,
    created_at        timestamp with time zone default now() not null
);

alter sequence public.doctor_paciente_id_seq owned by public.doctor_paciente.id;

comment on table public.doctor_paciente is
  'Asignación explícita de qué doctor(es) tienen acceso a la información de un paciente. Reemplaza cualquier inferencia basada en citas. Una fila con activo=true representa una asignación vigente; el historial se preserva marcando activo=false en vez de borrar.';

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'doctor_paciente_pkey') then
    alter table only public.doctor_paciente
      add constraint doctor_paciente_pkey primary key (id);
  end if;

  if not exists (select 1 from pg_constraint where conname = 'doctor_paciente_doctor_id_fkey') then
    alter table only public.doctor_paciente
      add constraint doctor_paciente_doctor_id_fkey
      foreign key (doctor_id) references public.doctores(id);
  end if;

  if not exists (select 1 from pg_constraint where conname = 'doctor_paciente_paciente_id_fkey') then
    alter table only public.doctor_paciente
      add constraint doctor_paciente_paciente_id_fkey
      foreign key (paciente_id) references public.pacientes(id);
  end if;

  if not exists (select 1 from pg_constraint where conname = 'doctor_paciente_asignado_por_fkey') then
    alter table only public.doctor_paciente
      add constraint doctor_paciente_asignado_por_fkey
      foreign key (asignado_por) references public.usuarios(id);
  end if;
end;
$$;

create index if not exists idx_doctor_paciente_activo
  on public.doctor_paciente using btree (paciente_id, doctor_id) where (activo = true);

create unique index if not exists uq_doctor_paciente_activo
  on public.doctor_paciente using btree (doctor_id, paciente_id) where (activo = true);

alter table public.doctor_paciente enable row level security;
alter table only public.doctor_paciente force row level security;

drop policy if exists doctor_paciente_select on public.doctor_paciente;
create policy doctor_paciente_select on public.doctor_paciente
  for select using (public.es_admin() or public.es_asistente() or (doctor_id = auth.uid()));

drop policy if exists doctor_paciente_insert on public.doctor_paciente;
create policy doctor_paciente_insert on public.doctor_paciente
  for insert with check (public.es_admin() or public.es_asistente());

drop policy if exists doctor_paciente_update on public.doctor_paciente;
create policy doctor_paciente_update on public.doctor_paciente
  for update using (public.es_admin() or public.es_asistente())
  with check (public.es_admin() or public.es_asistente());

drop policy if exists doctor_paciente_delete on public.doctor_paciente;
create policy doctor_paciente_delete on public.doctor_paciente
  for delete using (public.es_admin());

grant all on table public.doctor_paciente to authenticated;
grant all on table public.doctor_paciente to service_role;
grant all on sequence public.doctor_paciente_id_seq to authenticated;
grant all on sequence public.doctor_paciente_id_seq to service_role;

-- ---------------------------------------------------------------------------
-- 4. `items_receta` — tabla legada, cerrada al cliente
-- ---------------------------------------------------------------------------
-- La aplicación usa la columna JSONB del mismo nombre en `recetas` (SD-153).
-- Se versiona sólo para que el esquema local coincida; nace sin policies y sin
-- permisos, igual que quedó en producción tras HFX-CLIN-009.

create table if not exists public.items_receta (
    id                        uuid default gen_random_uuid() not null,
    receta_id                 uuid not null,
    medicamento_id            uuid,
    nombre_medicamento        text not null,
    presentacion_concentracion text default ''::text,
    dosis                     text not null,
    via_administracion        text default 'vía oral'::text,
    frecuencia                text not null,
    duracion                  text not null,
    cantidad_indicada         text default ''::text,
    indicaciones_especificas  text default ''::text,
    created_at                timestamp with time zone default now(),
    updated_at                timestamp with time zone default now(),
    deleted_at                timestamp with time zone
);

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'items_receta_pkey') then
    alter table only public.items_receta
      add constraint items_receta_pkey primary key (id);
  end if;

  if not exists (select 1 from pg_constraint where conname = 'items_receta_receta_id_fkey') then
    alter table only public.items_receta
      add constraint items_receta_receta_id_fkey
      foreign key (receta_id) references public.recetas(id) on delete cascade;
  end if;
end;
$$;

create index if not exists idx_items_receta_receta_id on public.items_receta using btree (receta_id);

alter table public.items_receta enable row level security;
revoke all on table public.items_receta from anon, authenticated;
grant all on table public.items_receta to service_role;

-- Índices de `recetas` que producción tiene y el repositorio no.
create index if not exists idx_recetas_consulta_id on public.recetas using btree (consulta_id);
create index if not exists idx_recetas_paciente_id on public.recetas using btree (paciente_id);

-- ---------------------------------------------------------------------------
-- 5. Funciones de trigger que sólo existían en producción
-- ---------------------------------------------------------------------------

create or replace function public.fn_auditoria_log() returns trigger
    language plpgsql security definer
    as $$
DECLARE
  v_usuario_id UUID;
  v_entidad_id TEXT;
  v_detalles JSONB;
BEGIN
  SELECT id INTO v_usuario_id FROM public.usuarios WHERE id = auth.uid();

  IF TG_OP = 'DELETE' THEN
    v_entidad_id := OLD.id::text;
    v_detalles := jsonb_build_object('eliminado', to_jsonb(OLD));
    INSERT INTO auditoria_log (usuario_id, accion, entidad, entidad_id, detalles, fecha)
    VALUES (v_usuario_id, 'DELETE', TG_TABLE_NAME, v_entidad_id, v_detalles, NOW());
    RETURN OLD;

  ELSIF TG_OP = 'UPDATE' THEN
    v_entidad_id := NEW.id::text;
    v_detalles := jsonb_build_object(
      'antes', to_jsonb(OLD),
      'despues', to_jsonb(NEW)
    );
    INSERT INTO auditoria_log (usuario_id, accion, entidad, entidad_id, detalles, fecha)
    VALUES (v_usuario_id, 'UPDATE', TG_TABLE_NAME, v_entidad_id, v_detalles, NOW());
    RETURN NEW;

  ELSIF TG_OP = 'INSERT' THEN
    v_entidad_id := NEW.id::text;
    v_detalles := jsonb_build_object('creado', to_jsonb(NEW));
    INSERT INTO auditoria_log (usuario_id, accion, entidad, entidad_id, detalles, fecha)
    VALUES (v_usuario_id, 'CREATE', TG_TABLE_NAME, v_entidad_id, v_detalles, NOW());
    RETURN NEW;
  END IF;

  RETURN NULL;
END;
$$;

create or replace function public.fn_autoasignar_doctor_paciente() returns trigger
    language plpgsql security definer
    set search_path to 'public'
    as $$
BEGIN
    -- Cada doctor que atiende una consulta de este paciente queda con acceso
    -- activo, sin importar si otro doctor ya lo tenía (cobertura de emergencia,
    -- referencias, co-tratamiento). El chequeo es por PAR doctor-paciente, no
    -- exclusivo por paciente, así que múltiples doctores pueden acumular acceso
    -- legítimamente con el tiempo.
    IF NOT EXISTS (
        SELECT 1 FROM doctor_paciente
        WHERE paciente_id = NEW.paciente_id
          AND doctor_id = NEW.doctor_id
          AND activo = true
    ) THEN
        INSERT INTO doctor_paciente (doctor_id, paciente_id, asignado_por, motivo)
        VALUES (
            NEW.doctor_id,
            NEW.paciente_id,
            NEW.doctor_id,
            'asignación automática: consulta ' || NEW.id::text
        );
    END IF;
    RETURN NEW;
END;
$$;

comment on function public.fn_autoasignar_doctor_paciente() is
  'Cada doctor que crea una consulta para un paciente queda con acceso activo en doctor_paciente. No es exclusivo: varios doctores pueden acumular acceso (cobertura de emergencia, co-tratamiento) sin que eso desactive el acceso de otros. La revocación de acceso (transferencia formal) sigue siendo una acción manual explícita en doctor_paciente, no automática.';

create or replace function public.fn_cascade_deleted_at_doctor() returns trigger
    language plpgsql
    as $$
BEGIN
  IF NEW.deleted_at IS DISTINCT FROM OLD.deleted_at THEN
    UPDATE admins SET deleted_at = NEW.deleted_at WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

create or replace function public.fn_cascade_deleted_at_usuario() returns trigger
    language plpgsql
    as $$
BEGIN
  IF NEW.deleted_at IS DISTINCT FROM OLD.deleted_at THEN
    UPDATE doctores SET deleted_at = NEW.deleted_at WHERE id = NEW.id;
    UPDATE asistentes SET deleted_at = NEW.deleted_at WHERE id = NEW.id;
    -- Ya NO se toca admin aquí directamente:
    -- admin ahora cuelga de doctor, no de usuario.
    -- El UPDATE de arriba a `doctor` disparará el trigger de nivel 2 solito.
  END IF;
  RETURN NEW;
END;
$$;

create or replace function public.generar_codigo_receta() returns trigger
    language plpgsql
    as $$
BEGIN
  IF NEW.codigo_receta IS NULL OR NEW.codigo_receta = '' THEN
    NEW.codigo_receta := 'RX-' || TO_CHAR(NOW(), 'YYYY') || '-' || LPAD(NEXTVAL('secuencia_codigo_receta')::TEXT, 5, '0');
  END IF;
  RETURN NEW;
END;
$$;

grant all on sequence public.secuencia_codigo_receta to authenticated;
grant all on sequence public.secuencia_codigo_receta to service_role;

-- Las funciones de trigger no las invoca nadie desde el cliente: sólo el
-- motor, en nombre del propietario. Producción ya las tiene cerradas a PUBLIC;
-- aquí se replica.
revoke all on function public.fn_auditoria_log()               from public;
revoke all on function public.fn_autoasignar_doctor_paciente() from public;
revoke all on function public.fn_cascade_deleted_at_doctor()   from public;
revoke all on function public.fn_cascade_deleted_at_usuario()  from public;
revoke all on function public.generar_codigo_receta()          from public;

grant all on function public.fn_auditoria_log()               to service_role;
grant all on function public.fn_autoasignar_doctor_paciente() to service_role;
grant all on function public.fn_cascade_deleted_at_doctor()   to service_role;
grant all on function public.fn_cascade_deleted_at_usuario()  to service_role;
grant all on function public.generar_codigo_receta()          to service_role;

-- ---------------------------------------------------------------------------
-- 5.b Cerrar las guardias RLS a PUBLIC
-- ---------------------------------------------------------------------------
-- HFX-CLIN-010 devolvió el EXECUTE a `authenticated` tras el revoke en bloque
-- de HFX-CLIN-001, pero en la base local PUBLIC conservó el EXECUTE por
-- defecto que trae toda función nueva. En producción no: allí están revocadas.
-- Se adopta el estado de producción, que además es el correcto — quien no está
-- autenticado no tiene por qué poder preguntarle a la base si puede ver a un
-- paciente.

do $$
declare
  v_firma text;
begin
  foreach v_firma in array array[
    'public.debe_ocultar_contacto_paciente(uuid)',
    'public.puede_ver_paciente(uuid)',
    'public.puede_ver_cuenta(uuid)',
    'public.puede_ver_plan(uuid)',
    'public.puede_ver_diente(uuid)',
    'public.puede_ver_odontograma(uuid)',
    'public.puede_ver_evaluacion(uuid)',
    'public.puede_ver_receta(uuid)'
  ] loop
    execute format('revoke all on function %s from public', v_firma);
    execute format('grant all on function %s to authenticated', v_firma);
    execute format('grant all on function %s to service_role', v_firma);
  end loop;
end;
$$;

-- Comentarios de las guardias que producción documentó y el repositorio no.
comment on function public.debe_ocultar_contacto_paciente(uuid) is
  'true si quien consulta es un doctor regular (no admin) y la persona referenciada es un paciente. Usado para enmascarar cédula/teléfono/dirección/referencia en las vistas *_seguro.';
comment on function public.es_doctor_no_admin() is
  'Distingue un doctor regular de un admin (que también es doctor por herencia). Necesario porque la regla de visibilidad de pacientes difiere entre ambos.';
comment on function public.puede_ver_consulta(uuid) is
  'Encadena hasta puede_ver_paciente() para tablas colgadas de consultas.';
comment on function public.puede_ver_cuenta(uuid) is
  'Encadena: cuenta -> paciente (directo o vía consulta).';
comment on function public.puede_ver_receta(uuid) is
  'Encadena: receta -> paciente (directo o vía consulta).';

-- ---------------------------------------------------------------------------
-- 6. Triggers que sólo existían en producción
-- ---------------------------------------------------------------------------

create or replace trigger trg_auditoria_caja_diaria
  after insert or delete or update on public.cajas_diarias
  for each row execute function public.fn_auditoria_log();

create or replace trigger trg_auditoria_cita
  after insert or delete or update on public.citas
  for each row execute function public.fn_auditoria_log();

create or replace trigger trg_auditoria_compra
  after insert or delete or update on public.compras
  for each row execute function public.fn_auditoria_log();

create or replace trigger trg_auditoria_consulta
  after insert or delete or update on public.consultas
  for each row execute function public.fn_auditoria_log();

create or replace trigger trg_auditoria_cuenta
  after insert or delete or update on public.cuentas
  for each row execute function public.fn_auditoria_log();

create or replace trigger trg_auditoria_pago
  after insert or delete or update on public.pagos
  for each row execute function public.fn_auditoria_log();

create or replace trigger trg_autoasignar_doctor_paciente
  after insert on public.consultas
  for each row execute function public.fn_autoasignar_doctor_paciente();

create or replace trigger trg_cascade_deleted_at_doctor
  after update of deleted_at on public.doctores
  for each row execute function public.fn_cascade_deleted_at_doctor();

create or replace trigger trg_cascade_deleted_at_usuario
  after update of deleted_at on public.usuarios
  for each row execute function public.fn_cascade_deleted_at_usuario();

create or replace trigger trg_generar_codigo_receta
  before insert on public.recetas
  for each row execute function public.generar_codigo_receta();

-- ---------------------------------------------------------------------------
-- 6.b Columnas y restricciones que sólo existían en producción
-- ---------------------------------------------------------------------------
-- Estas no son adornos: el cliente **ya las lee**. `tratamiento_aplicado_model`
-- mapea `cantidad_realizada`, `resumen_actividad_plan_model` mapea
-- `tipo_ejecucion` y `sesiones_planificadas`, y `receta_model` mapea
-- `codigo_receta`. En la base local ninguna existía, así que esas funciones
-- estaban rotas en cualquier entorno levantado con `supabase db reset`.

alter table public.tratamientos_aplicados
  add column if not exists cantidad_realizada numeric(10,2) default 1 not null;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'tratamientos_aplicados_cantidad_realizada_check') then
    alter table public.tratamientos_aplicados
      add constraint tratamientos_aplicados_cantidad_realizada_check
      check (cantidad_realizada > (0)::numeric);
  end if;
end;
$$;

alter table public.items_cuenta
  add column if not exists tratamiento_aplicado_id uuid;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'items_cuenta_tratamiento_aplicado_id_fkey') then
    alter table only public.items_cuenta
      add constraint items_cuenta_tratamiento_aplicado_id_fkey
      foreign key (tratamiento_aplicado_id)
      references public.tratamientos_aplicados(id) on delete set null;
  end if;
end;
$$;

alter table public.items_plan_tratamiento
  add column if not exists tipo_ejecucion text default 'unica'::text not null;
alter table public.items_plan_tratamiento
  add column if not exists sesiones_planificadas integer;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'items_plan_tratamiento_tipo_ejecucion_check') then
    alter table public.items_plan_tratamiento
      add constraint items_plan_tratamiento_tipo_ejecucion_check
      check (tipo_ejecucion = any (array['unica'::text, 'por_sesiones'::text]));
  end if;

  if not exists (select 1 from pg_constraint where conname = 'items_plan_tratamiento_sesiones_planificadas_check') then
    alter table public.items_plan_tratamiento
      add constraint items_plan_tratamiento_sesiones_planificadas_check
      check (sesiones_planificadas is null or sesiones_planificadas > 0);
  end if;

  if not exists (select 1 from pg_constraint where conname = 'items_plan_sesiones_coherentes') then
    alter table public.items_plan_tratamiento
      add constraint items_plan_sesiones_coherentes
      check (
        (tipo_ejecucion = 'unica'::text and sesiones_planificadas is null)
        or tipo_ejecucion = 'por_sesiones'::text
      );
  end if;
end;
$$;

alter table public.recetas
  add column if not exists codigo_receta text;

-- FK duplicada de `admins`. Producción tiene DOS restricciones sobre la misma
-- columna hacia la misma tabla: `admins_id_doctores_fkey` (la que creó
-- HFX-CLIN-000, versionada y comentada) y `admins_id_fkey` (el nombre de la
-- línea base, repuntado a mano en el Studio de `usuarios` a `doctores`).
--
-- Es la causa directa del defecto D2: PostgREST ve dos caminos `admins →
-- doctores` y responde «more than one relationship was found». Ninguna de las
-- dos aporta integridad que la otra no imponga ya, así que retirar la
-- redundante no cambia ninguna garantía de datos, sólo limpia el grafo de
-- relaciones. Se conserva la versionada.
--
-- (El embed sigue necesitando una pista explícita en el cliente: la tabla
-- `auditoria_correcciones_clinicas` de HFX-CLIN-001, con FK a `admins` y a
-- `doctores`, mantiene un camino m2m inferido. Eso lo resuelve F1.)
alter table public.admins drop constraint if exists admins_id_fkey;

-- Producción añadió `on update cascade` a varias FK de paciente/persona.
-- Inerte (los uuid no se actualizan), pero se replica para que ambos esquemas
-- coincidan y el gate de deriva pueda quedar limpio.
do $$
declare
  v record;
begin
  for v in
    select * from (values
      ('citas',                 'citas_persona_id_fkey',                 'persona_id',  'personas',   ''),
      ('cuentas',               'cuentas_paciente_id_fkey',              'paciente_id', 'personas',   ''),
      ('recetas',               'recetas_paciente_id_fkey',              'paciente_id', 'personas',   ''),
      ('consultas',             'consultas_paciente_id_fkey',            'paciente_id', 'pacientes',  ' on delete cascade'),
      ('documentos_clinicos',   'documentos_clinicos_paciente_id_fkey',  'paciente_id', 'pacientes',  ' on delete cascade'),
      ('records',               'records_paciente_id_fkey',              'paciente_id', 'pacientes',  ' on delete cascade'),
      ('evaluaciones_clinicas', 'evaluaciones_clinicas_paciente_id_fkey','paciente_id', 'pacientes',  ' on delete restrict'),
      ('planes_tratamiento',    'planes_tratamiento_paciente_id_fkey',   'paciente_id', 'pacientes',  ' on delete restrict')
    ) as t(tabla, restriccion, columna, referencia, extra)
  loop
    execute format('alter table public.%I drop constraint if exists %I', v.tabla, v.restriccion);
    execute format(
      'alter table only public.%I add constraint %I foreign key (%I) references public.%I(id) on update cascade%s',
      v.tabla, v.restriccion, v.columna, v.referencia, v.extra
    );
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- 7. `resumen_actividad_plan` — vista de seguimiento del plan de tratamiento
-- ---------------------------------------------------------------------------

create or replace view public.resumen_actividad_plan as
 with realizado as (
         select ta.item_plan_id,
            sum(ta.cantidad_realizada) as cantidad_realizada_total,
            sum((ta.precio_aplicado * ta.cantidad_realizada)) as monto_realizado
           from public.tratamientos_aplicados ta
          where ((ta.deleted_at is null) and (coalesce(ta.estado, 'aplicado'::text) <> 'indicado'::text))
          group by ta.item_plan_id
        ), facturado as (
         select ta.item_plan_id,
            sum((ic.precio_unitario * (ic.cantidad)::numeric)) as monto_facturado,
            array_agg(distinct ic.cuenta_id) as cuentas_involucradas
           from (public.items_cuenta ic
             join public.tratamientos_aplicados ta on ((ta.id = ic.tratamiento_aplicado_id)))
          where ((ic.deleted_at is null) and (ta.deleted_at is null))
          group by ta.item_plan_id
        ), pagos_por_cuenta as (
         select c.id as cuenta_id,
            c.monto_total,
            coalesce(sum(p_1.monto), (0)::numeric) as total_pagado_cuenta
           from (public.cuentas c
             left join public.pagos p_1 on (((p_1.cuenta_id = c.id) and (p_1.deleted_at is null) and (p_1.estado = 'completado'::public.estado_pago))))
          where (c.deleted_at is null)
          group by c.id, c.monto_total
        ), pagado as (
         select ta.item_plan_id,
            sum(
                case
                    when (ppc.monto_total > (0)::numeric) then (((ic.precio_unitario * (ic.cantidad)::numeric) / ppc.monto_total) * ppc.total_pagado_cuenta)
                    else (0)::numeric
                end) as monto_pagado_prorrateado
           from ((public.items_cuenta ic
             join public.tratamientos_aplicados ta on ((ta.id = ic.tratamiento_aplicado_id)))
             join pagos_por_cuenta ppc on ((ppc.cuenta_id = ic.cuenta_id)))
          where ((ic.deleted_at is null) and (ta.deleted_at is null))
          group by ta.item_plan_id
        )
 select ipt.id as item_plan_id,
    ipt.plan_id,
    pt.paciente_id,
    ipt.tratamiento_id,
    t.nombre as tratamiento_nombre,
    ipt.tipo_ejecucion,
    ipt.sesiones_planificadas,
    ipt.estado,
    ipt.precio_estimado as monto_presupuestado,
    coalesce(r.cantidad_realizada_total, (0)::numeric) as cantidad_realizada,
    coalesce(r.monto_realizado, (0)::numeric) as monto_realizado,
    coalesce(f.monto_facturado, (0)::numeric) as monto_facturado,
    coalesce(p.monto_pagado_prorrateado, (0)::numeric) as monto_pagado,
    greatest((ipt.precio_estimado - coalesce(f.monto_facturado, (0)::numeric)), (0)::numeric) as monto_pendiente
   from (((((public.items_plan_tratamiento ipt
     join public.planes_tratamiento pt on ((pt.id = ipt.plan_id)))
     left join public.tratamientos t on ((t.id = ipt.tratamiento_id)))
     left join realizado r on ((r.item_plan_id = ipt.id)))
     left join facturado f on ((f.item_plan_id = ipt.id)))
     left join pagado p on ((p.item_plan_id = ipt.id)))
  where (ipt.deleted_at is null);

grant all on table public.resumen_actividad_plan to authenticated;
grant all on table public.resumen_actividad_plan to service_role;

-- ---------------------------------------------------------------------------
-- 8. `hfx_base_recibir_compra` — producción va por delante del repositorio
-- ---------------------------------------------------------------------------
-- La versión del repositorio sumaba a `consumibles.stock_actual` a mano. La de
-- producción inserta en `movimientos_stock_consumible` y deja que
-- `fn_aplicar_movimiento_stock` actualice el stock: así queda trazabilidad y el
-- `for update` del trigger evita carreras con otros movimientos concurrentes
-- sobre el mismo consumible. Se adopta la de producción.

create or replace function public.hfx_base_recibir_compra(p_compra_id uuid, p_usuario_id uuid)
 returns void
 language plpgsql
 security definer
 set search_path to 'public'
as $$
DECLARE
  v_caja_id UUID;
  v_monto_total NUMERIC(12, 2);
  v_estado_compra TEXT;
  v_item RECORD;
BEGIN
  SELECT estado::text INTO v_estado_compra
  FROM compras
  WHERE id = p_compra_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'La compra especificada no existe.';
  END IF;

  IF v_estado_compra IN ('recibido', 'recibida') THEN
    RAISE EXCEPTION 'Esta compra ya fue recibida anteriormente.';
  END IF;

  SELECT COALESCE(SUM(cantidad * precio_unitario), 0)
  INTO v_monto_total
  FROM consumibles_compras
  WHERE compra_id = p_compra_id;

  SELECT id INTO v_caja_id
  FROM cajas
  WHERE cerrada = false
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_caja_id IS NULL THEN
    RAISE EXCEPTION 'No hay ninguna caja abierta actualmente.';
  END IF;

  UPDATE compras
  SET
    estado = 'recibido'::estado_compra,
    updated_at = NOW()
  WHERE id = p_compra_id;

  -- 5. Registrar movimiento de stock por cada artículo recibido.
  --    El trigger fn_aplicar_movimiento_stock actualiza consumibles.stock_actual
  --    y calcula stock_anterior/stock_nuevo, con FOR UPDATE para evitar carreras
  --    con otros movimientos concurrentes sobre el mismo consumible.
  FOR v_item IN
    SELECT consumible_id, cantidad
    FROM consumibles_compras
    WHERE compra_id = p_compra_id
  LOOP
    INSERT INTO movimientos_stock_consumible (
      consumible_id,
      diferencia,
      motivo
    ) VALUES (
      v_item.consumible_id,
      v_item.cantidad,
      'compra_recibida'
    );
  END LOOP;

  IF v_monto_total > 0 THEN
    INSERT INTO movimientos_caja (
      caja_diaria_id,
      tipo,
      monto,
      descripcion,
      metodo_pago,
      fecha,
      created_at
    ) VALUES (
      v_caja_id,
      'egreso',
      v_monto_total,
      'Pago por recepción de compra #' || SUBSTRING(p_compra_id::text, 1, 8),
      'efectivo',
      NOW(),
      NOW()
    );

    UPDATE cajas
    SET
      monto_esperado = COALESCE(monto_esperado, 0) - v_monto_total,
      updated_at = NOW()
    WHERE id = v_caja_id;
  END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- 9. Policies de SELECT: de los tres roles planos a las guardias `puede_ver_*`
-- ---------------------------------------------------------------------------
-- Este es el cambio de fondo. En el repositorio, cualquier doctor veía a
-- cualquier paciente; en producción un doctor regular sólo ve los pacientes con
-- asignación activa en `doctor_paciente`. El cliente se adapta a este modelo
-- (fases F1 y F3): «no veo la ficha completa de este paciente» es un estado
-- normal para un doctor no asignado, no un error.

drop policy if exists pacientes_select on public.pacientes;
create policy pacientes_select on public.pacientes
  for select using (public.puede_ver_paciente(id));

drop policy if exists persona_select on public.personas;
create policy persona_select on public.personas
  for select using (
    (public.es_admin() or public.es_doctor() or public.es_asistente())
    and (
      (not exists (select 1 from public.pacientes p where p.id = personas.id))
      or public.puede_ver_paciente(id)
    )
  );

drop policy if exists cuenta_select on public.cuentas;
create policy cuenta_select on public.cuentas
  for select using (
    ((paciente_id is not null) and public.puede_ver_paciente(paciente_id))
    or public.puede_ver_consulta(consulta_id)
  );

drop policy if exists cuotas_select on public.cuotas;
create policy cuotas_select on public.cuotas
  for select using (public.puede_ver_cuenta(cuenta_id));

drop policy if exists items_cuenta_select on public.items_cuenta;
create policy items_cuenta_select on public.items_cuenta
  for select using (public.puede_ver_cuenta(cuenta_id));

drop policy if exists pago_select on public.pagos;
create policy pago_select on public.pagos
  for select using (public.puede_ver_cuenta(cuenta_id));

drop policy if exists odontograma_select on public.odontogramas;
create policy odontograma_select on public.odontogramas
  for select using (public.puede_ver_consulta(consulta_id));

drop policy if exists dientes_select on public.dientes;
create policy dientes_select on public.dientes
  for select using (public.puede_ver_odontograma(odontograma_id));

drop policy if exists superficies_select on public.superficies;
create policy superficies_select on public.superficies
  for select using (public.puede_ver_diente(diente_id));

drop policy if exists evaluaciones_clinicas_select on public.evaluaciones_clinicas;
create policy evaluaciones_clinicas_select on public.evaluaciones_clinicas
  for select using (public.puede_ver_paciente(paciente_id));

drop policy if exists planes_tratamiento_select on public.planes_tratamiento;
create policy planes_tratamiento_select on public.planes_tratamiento
  for select using (public.puede_ver_paciente(paciente_id));

drop policy if exists items_plan_tratamiento_select on public.items_plan_tratamiento;
create policy items_plan_tratamiento_select on public.items_plan_tratamiento
  for select using (public.puede_ver_plan(plan_id));

drop policy if exists record_select on public.records;
create policy record_select on public.records
  for select using (public.puede_ver_paciente(paciente_id));

drop policy if exists record_condicion_select on public.record_condicion;
create policy record_condicion_select on public.record_condicion
  for select using (
    exists (
      select 1 from public.records r
      where r.id = record_condicion.record_id
        and public.puede_ver_paciente(r.paciente_id)
    )
  );

-- Deriva de inventario: en producción el doctor también puede actualizar
-- consumibles. Se versiona tal cual para no cambiar producción en este paso.
-- Pendiente de revisión de negocio: no forma parte de la matriz de roles de QA.
drop policy if exists consumibles_update on public.consumibles;
create policy consumibles_update on public.consumibles
  for update using (public.es_admin() or public.es_asistente() or public.es_doctor())
  with check (public.es_admin() or public.es_asistente() or public.es_doctor());
