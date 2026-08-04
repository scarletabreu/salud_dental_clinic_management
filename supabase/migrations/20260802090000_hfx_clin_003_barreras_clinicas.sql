-- HFX-CLIN-003 · Barreras activas de seguridad clínica
--
-- La aplicación almacenaba información clínica pero se comportaba como un
-- formulario pasivo: aceptaba signos vitales imposibles, guardaba una condición
-- descubierta hoy como texto libre que no participaba en ninguna comprobación,
-- prescribía con dosis y frecuencia en texto plano y dejaba asignar un
-- tratamiento global a una pieza concreta.
--
-- Esta migración añade las barreras que faltaban:
--
--   * signos vitales estructurados, con unidad, actor, origen y validación;
--   * un motor de alertas cuyas reglas viven en catálogo, con versión y
--     aprobación explícita —sin umbrales inventados—;
--   * condiciones descubiertas durante la consulta que participan de inmediato
--     en contraindicaciones;
--   * recetas con renglón estructurado, bloqueo absoluto y coherencia;
--   * alcance clínico verificado en la base, no solo en la pantalla;
--   * consentimiento con evidencia y versión del plan mostrado.
--
-- Códigos de error estables que añade este ticket (CL001–CL005 son de
-- HFX-CLIN-002):
--
--   CL006  signo vital físicamente imposible o relación imposible.
--   CL007  alerta clínica pendiente de acción documentada.
--   CL008  renglón de receta incompleto o incoherente.
--   CL009  duplicidad de medicamento o principio activo.
--   CL010  contraindicación absoluta: sin excepción posible.
--   CL011  riesgo relativo sin justificación por medicamento.
--   CL012  alcance clínico incompatible con el catálogo.
--   CL013  consentimiento ausente o incompleto.

begin;

-- ---------------------------------------------------------------------------
-- 1. Signos vitales estructurados
-- ---------------------------------------------------------------------------

-- Los límites de este catálogo son de posibilidad física, no umbrales clínicos:
-- fuera de ellos el dato no describe a una persona viva, así que se rechaza en
-- cualquier protocolo. Los umbrales de criticidad viven en `reglas_clinicas` y
-- requieren aprobación del dueño clínico.
create table if not exists public.catalogo_signos_vitales (
  codigo          text primary key,
  etiqueta        text not null,
  unidad          text not null,
  minimo_posible  numeric not null,
  maximo_posible  numeric not null,
  decimales       integer not null default 0,
  orden           integer not null default 0,
  constraint catalogo_signos_vitales_rango check (minimo_posible < maximo_posible)
);

comment on table public.catalogo_signos_vitales is
  'HFX-CLIN-003. Rango físicamente posible de cada signo vital. No es un umbral clínico.';

insert into public.catalogo_signos_vitales
  (codigo, etiqueta, unidad, minimo_posible, maximo_posible, decimales, orden)
values
  ('presion_sistolica',       'Presión sistólica',      'mmHg', 30,  300, 0, 10),
  ('presion_diastolica',      'Presión diastólica',     'mmHg', 10,  200, 0, 20),
  ('pulso',                   'Pulso',                  'lpm',  10,  300, 0, 30),
  ('temperatura',             'Temperatura',            '°C',   25,   45, 1, 40),
  ('saturacion_o2',           'Saturación de oxígeno',  '%',    10,  100, 0, 50),
  ('frecuencia_respiratoria', 'Frecuencia respiratoria','rpm',   4,   80, 0, 60),
  ('dolor',                   'Dolor referido',         '/10',   0,   10, 0, 70),
  ('peso',                    'Peso',                   'kg',  0.5,  400, 1, 80),
  ('talla',                   'Talla',                  'cm',   20,  260, 1, 90)
on conflict (codigo) do update
  set etiqueta = excluded.etiqueta,
      unidad = excluded.unidad,
      minimo_posible = excluded.minimo_posible,
      maximo_posible = excluded.maximo_posible,
      decimales = excluded.decimales,
      orden = excluded.orden;

create table if not exists public.signos_vitales_consulta (
  id                 uuid primary key default gen_random_uuid(),
  consulta_id        uuid not null references public.consultas(id) on delete cascade,
  codigo             text not null references public.catalogo_signos_vitales(codigo),
  valor              numeric not null,
  unidad             text not null,
  medido_en          timestamptz not null default now(),
  medido_por         uuid references public.usuarios(id),
  origen             text not null default 'medido',
  observacion        text,
  estado_validacion  text not null default 'valido',
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  deleted_at         timestamptz,
  constraint signos_vitales_origen_check
    check (origen in ('medido', 'referido', 'dispositivo')),
  constraint signos_vitales_estado_check
    check (estado_validacion in ('valido', 'confirmado_por_doctor', 'descartado'))
);

comment on table public.signos_vitales_consulta is
  'HFX-CLIN-003. Una medición por fila: valor, unidad, momento, actor, origen y estado de validación.';

create unique index if not exists signos_vitales_consulta_vigente_uk
  on public.signos_vitales_consulta (consulta_id, codigo)
  where deleted_at is null;

create index if not exists signos_vitales_consulta_idx
  on public.signos_vitales_consulta (consulta_id)
  where deleted_at is null;

alter table public.signos_vitales_consulta enable row level security;

drop policy if exists signos_vitales_consulta_select on public.signos_vitales_consulta;
create policy signos_vitales_consulta_select on public.signos_vitales_consulta
  for select to authenticated
  using (public.puede_ver_consulta(consulta_id));

-- El rango imposible se comprueba en la base: una medición fuera de él no
-- describe a un paciente vivo, venga de la pantalla o de un POST directo.
create or replace function public.hfx_clin_003_validar_signo_vital()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_cat record;
begin
  select * into v_cat
    from catalogo_signos_vitales
   where codigo = new.codigo;

  if not found then
    raise exception 'El signo vital "%" no está en el catálogo.', new.codigo
      using errcode = 'CL006';
  end if;

  if new.valor < v_cat.minimo_posible or new.valor > v_cat.maximo_posible then
    raise exception '% = % % está fuera del rango físicamente posible (% a % %).',
      v_cat.etiqueta, new.valor, v_cat.unidad,
      v_cat.minimo_posible, v_cat.maximo_posible, v_cat.unidad
      using errcode = 'CL006';
  end if;

  new.unidad := coalesce(nullif(new.unidad, ''), v_cat.unidad);

  if new.unidad <> v_cat.unidad then
    raise exception '% se registra en % y llegó en "%".',
      v_cat.etiqueta, v_cat.unidad, new.unidad
      using errcode = 'CL006';
  end if;

  new.updated_at := now();
  return new;
end;
$$;

alter function public.hfx_clin_003_validar_signo_vital() owner to postgres;

drop trigger if exists trg_validar_signo_vital on public.signos_vitales_consulta;
create trigger trg_validar_signo_vital
  before insert or update on public.signos_vitales_consulta
  for each row execute function public.hfx_clin_003_validar_signo_vital();

-- ---------------------------------------------------------------------------
-- 2. Reglas clínicas: configurables, versionadas y aprobadas
-- ---------------------------------------------------------------------------

create table if not exists public.reglas_clinicas (
  id            uuid primary key default gen_random_uuid(),
  codigo        text not null,
  version       integer not null default 1,
  nombre        text not null,
  descripcion   text,
  categoria     text not null,
  tipo          text not null,
  parametros    jsonb,
  accion        text not null,
  severidad     text not null default 'advertencia',
  estado        text not null default 'pendiente_aprobacion',
  fuente        text,
  aprobada_por  uuid references public.usuarios(id),
  aprobada_en   timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  constraint reglas_clinicas_codigo_version_uk unique (codigo, version),
  constraint reglas_clinicas_categoria_check
    check (categoria in ('signo_vital', 'condicion', 'medicamento', 'tratamiento')),
  constraint reglas_clinicas_tipo_check
    check (tipo in ('rango_imposible', 'relacion_imposible', 'valor_critico',
                    'combinacion_condicion_signo', 'requisito_dato')),
  constraint reglas_clinicas_accion_check
    check (accion in ('advertir', 'confirmar', 'documentar',
                      'bloquear_electivo', 'referir')),
  constraint reglas_clinicas_severidad_check
    check (severidad in ('informativa', 'advertencia', 'critica', 'absoluta')),
  constraint reglas_clinicas_estado_check
    check (estado in ('pendiente_aprobacion', 'aprobada', 'retirada')),
  -- Una regla aprobada sin parámetros no puede evaluarse: se rechaza en vez de
  -- quedar viva y silenciosa.
  constraint reglas_clinicas_aprobada_completa
    check (estado <> 'aprobada' or (parametros is not null and aprobada_en is not null))
);

comment on table public.reglas_clinicas is
  'HFX-CLIN-003. Reglas del motor de alertas. Solo evalúan las aprobadas con parámetros; los umbrales clínicos requieren aprobación del dueño doctor.';
comment on column public.reglas_clinicas.parametros is
  'Forma según tipo. valor_critico: {"codigo":"pulso","min":50,"max":110}. combinacion_condicion_signo: {"condicion":"embarazo","signos":[{"codigo":"presion_sistolica","max":140}]}. requisito_dato: {"codigo":"peso","exige_al_recetar":true}. Cualquier regla admite además "edad_min_anios" y "edad_max_anios" para limitarla a una franja etaria.';

create index if not exists reglas_clinicas_vigentes_idx
  on public.reglas_clinicas (categoria, estado)
  where estado = 'aprobada';

alter table public.reglas_clinicas enable row level security;

drop policy if exists reglas_clinicas_select on public.reglas_clinicas;
create policy reglas_clinicas_select on public.reglas_clinicas
  for select to authenticated using (true);

-- Reglas de imposibilidad física: se aprueban aquí porque no son un protocolo
-- clínico, son la definición de un dato válido. Su parámetro es el catálogo.
insert into public.reglas_clinicas
  (codigo, version, nombre, descripcion, categoria, tipo, parametros, accion,
   severidad, estado, fuente, aprobada_en)
values
  ('SV_RANGO_IMPOSIBLE', 1,
   'Signo vital fuera del rango físicamente posible',
   'Rechaza una medición que no puede corresponder a una persona viva.',
   'signo_vital', 'rango_imposible',
   jsonb_build_object('origen', 'catalogo_signos_vitales'),
   'bloquear_electivo', 'absoluta', 'aprobada',
   'Definición de dato válido, no protocolo clínico.', now()),
  ('SV_DIASTOLICA_MAYOR_SISTOLICA', 1,
   'Diastólica mayor o igual que la sistólica',
   'Una presión diastólica que iguala o supera la sistólica es una medición imposible.',
   'signo_vital', 'relacion_imposible',
   jsonb_build_object('mayor', 'presion_sistolica', 'menor', 'presion_diastolica'),
   'bloquear_electivo', 'absoluta', 'aprobada',
   'Definición de dato válido, no protocolo clínico.', now())
on conflict (codigo, version) do nothing;

-- Umbrales de criticidad: quedan registrados como pendientes para que el dueño
-- clínico los complete y apruebe. Sin `parametros` y sin `estado = aprobada` el
-- motor no los evalúa; no se inventa ningún protocolo aquí.
insert into public.reglas_clinicas
  (codigo, version, nombre, descripcion, categoria, tipo, parametros, accion,
   severidad, estado, fuente)
values
  ('SV_PRESION_CRITICA', 1, 'Presión arterial crítica',
   'Pendiente: definir el rango de presión que exige acción documentada.',
   'signo_vital', 'valor_critico', null, 'documentar', 'critica',
   'pendiente_aprobacion', 'Requiere aprobación del dueño clínico.'),
  ('SV_PULSO_CRITICO', 1, 'Pulso crítico',
   'Pendiente: definir el rango de pulso que exige acción documentada.',
   'signo_vital', 'valor_critico', null, 'documentar', 'critica',
   'pendiente_aprobacion', 'Requiere aprobación del dueño clínico.'),
  ('SV_TEMPERATURA_CRITICA', 1, 'Temperatura crítica',
   'Pendiente: definir la temperatura que exige acción documentada.',
   'signo_vital', 'valor_critico', null, 'documentar', 'critica',
   'pendiente_aprobacion', 'Requiere aprobación del dueño clínico.'),
  ('SV_SATURACION_CRITICA', 1, 'Saturación de oxígeno crítica',
   'Pendiente: definir la saturación que exige referencia o emergencia.',
   'signo_vital', 'valor_critico', null, 'referir', 'critica',
   'pendiente_aprobacion', 'Requiere aprobación del dueño clínico.'),
  ('SV_DOLOR_SEVERO', 1, 'Dolor severo referido',
   'Pendiente: definir a partir de qué valor el dolor exige acción documentada.',
   'signo_vital', 'valor_critico', null, 'documentar', 'advertencia',
   'pendiente_aprobacion', 'Requiere aprobación del dueño clínico.'),
  ('COMB_EMBARAZO_SIGNOS', 1, 'Embarazo con signos vitales alterados',
   'Pendiente: definir qué combinación de embarazo y signos vitales exige acción documentada o referencia.',
   'condicion', 'combinacion_condicion_signo', null, 'documentar', 'critica',
   'pendiente_aprobacion', 'Requiere aprobación del dueño clínico.'),
  ('COMB_HIPERTENSION_SIGNOS', 1, 'Hipertensión con presión alterada',
   'Pendiente: definir qué presión exige acción documentada en un paciente hipertenso conocido.',
   'condicion', 'combinacion_condicion_signo', null, 'documentar', 'critica',
   'pendiente_aprobacion', 'Requiere aprobación del dueño clínico.'),
  ('COMB_DIABETES_SIGNOS', 1, 'Diabetes con signos vitales alterados',
   'Pendiente: definir qué combinación de diabetes y signos vitales exige acción documentada antes de un procedimiento.',
   'condicion', 'combinacion_condicion_signo', null, 'documentar', 'critica',
   'pendiente_aprobacion', 'Requiere aprobación del dueño clínico.'),
  ('PED_PESO_REQUERIDO', 1, 'Paciente pediátrico sin peso registrado',
   'Pendiente: definir hasta qué edad la dosificación exige peso registrado en la consulta.',
   'medicamento', 'requisito_dato', null, 'documentar', 'critica',
   'pendiente_aprobacion', 'Requiere aprobación del dueño clínico.')
on conflict (codigo, version) do nothing;

-- ---------------------------------------------------------------------------
-- 3. Alertas clínicas producidas por el motor
-- ---------------------------------------------------------------------------

create table if not exists public.alertas_clinicas (
  id             uuid primary key default gen_random_uuid(),
  consulta_id    uuid not null references public.consultas(id) on delete cascade,
  regla_id       uuid references public.reglas_clinicas(id),
  regla_codigo   text not null,
  regla_version  integer not null default 1,
  severidad      text not null,
  accion         text not null,
  mensaje        text not null,
  disparador     jsonb not null default '{}'::jsonb,
  estado         text not null default 'pendiente',
  justificacion  text,
  resuelta_por   uuid references public.usuarios(id),
  resuelta_en    timestamptz,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  constraint alertas_clinicas_estado_check
    check (estado in ('pendiente', 'confirmada', 'documentada', 'obsoleta')),
  -- Continuar pese a la alerta deja constancia de por qué.
  constraint alertas_clinicas_justificacion_check
    check (estado <> 'documentada' or coalesce(btrim(justificacion), '') <> '')
);

comment on table public.alertas_clinicas is
  'HFX-CLIN-003. Alerta emitida por el motor sobre una consulta. Guarda qué dato la disparó y qué acción exige.';

create unique index if not exists alertas_clinicas_vigente_uk
  on public.alertas_clinicas (consulta_id, regla_codigo, regla_version)
  where estado <> 'obsoleta';

create index if not exists alertas_clinicas_consulta_idx
  on public.alertas_clinicas (consulta_id, created_at desc);

alter table public.alertas_clinicas enable row level security;

drop policy if exists alertas_clinicas_select on public.alertas_clinicas;
create policy alertas_clinicas_select on public.alertas_clinicas
  for select to authenticated
  using (public.puede_ver_consulta(consulta_id));

-- ---------------------------------------------------------------------------
-- 4. Condiciones descubiertas durante la consulta
-- ---------------------------------------------------------------------------

create table if not exists public.condiciones_consulta (
  id                        uuid primary key default gen_random_uuid(),
  consulta_id               uuid not null references public.consultas(id) on delete cascade,
  condicion_id              uuid not null references public.condiciones(id) on delete restrict,
  severidad                 text not null default 'moderada',
  notas                     text,
  detectada_en              timestamptz not null default now(),
  incorporar_al_expediente  boolean not null default false,
  confirmada_por            uuid references public.usuarios(id),
  confirmada_en             timestamptz,
  created_at                timestamptz not null default now(),
  updated_at                timestamptz not null default now(),
  deleted_at                timestamptz,
  constraint condiciones_consulta_severidad_check
    check (severidad in ('leve', 'moderada', 'severa'))
);

comment on table public.condiciones_consulta is
  'HFX-CLIN-003. Condición de catálogo detectada durante la consulta. Participa en contraindicaciones desde el momento en que se registra; el texto libre de consultas.temp_condiciones queda como complemento.';

create unique index if not exists condiciones_consulta_vigente_uk
  on public.condiciones_consulta (consulta_id, condicion_id)
  where deleted_at is null;

create index if not exists condiciones_consulta_consulta_idx
  on public.condiciones_consulta (consulta_id)
  where deleted_at is null;

alter table public.condiciones_consulta enable row level security;

drop policy if exists condiciones_consulta_select on public.condiciones_consulta;
create policy condiciones_consulta_select on public.condiciones_consulta
  for select to authenticated
  using (public.puede_ver_consulta(consulta_id));

-- Lo que el motor y las contraindicaciones deben mirar: el expediente más lo
-- descubierto hoy. Una condición detectada en esta consulta cuenta desde que se
-- registra, sin esperar al cierre.
create or replace view public.condiciones_activas_paciente as
  select rc.record_id       as record_id,
         r.paciente_id      as paciente_id,
         rc.condicion_id    as condicion_id,
         null::uuid         as consulta_id,
         'expediente'::text as origen,
         null::text         as severidad,
         rc.fecha_deteccion as detectada_en
    from public.record_condicion rc
    join public.records r on r.id = rc.record_id
   where rc.activo
     and r.deleted_at is null
  union all
  select null::uuid         as record_id,
         c.paciente_id      as paciente_id,
         cc.condicion_id    as condicion_id,
         cc.consulta_id     as consulta_id,
         'consulta'::text   as origen,
         cc.severidad       as severidad,
         cc.detectada_en    as detectada_en
    from public.condiciones_consulta cc
    join public.consultas c on c.id = cc.consulta_id
   where cc.deleted_at is null
     and c.deleted_at is null;

alter view public.condiciones_activas_paciente owner to postgres;
-- La vista no puede convertirse en una puerta trasera a la RLS del expediente:
-- se evalúa con los permisos de quien consulta.
alter view public.condiciones_activas_paciente set (security_invoker = on);

comment on view public.condiciones_activas_paciente is
  'HFX-CLIN-003. Condiciones que deben participar en contraindicaciones: las del expediente y las descubiertas en consulta.';

-- ---------------------------------------------------------------------------
-- 5. Medicinas: principio activo para detectar duplicidad real
-- ---------------------------------------------------------------------------

alter table public.medicinas
  add column if not exists principio_activo text;

comment on column public.medicinas.principio_activo is
  'HFX-CLIN-003. Cuando falta, el sistema informa "información insuficiente" en vez de afirmar que no hay conflicto.';

-- ---------------------------------------------------------------------------
-- 6. Alcance clínico verificado en la base
-- ---------------------------------------------------------------------------

-- El catálogo dice sobre qué se aplica cada diagnóstico y tratamiento. Hasta
-- ahora el selector de una pieza ofrecía elementos globales y la base los
-- aceptaba: quedaba un hallazgo de arcada colgado de un molar.
create or replace function public.hfx_clin_003_validar_alcance()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_alcance text;
  v_nombre  text;
begin
  if tg_table_name = 'diagnosticos_aplicados' then
    select d.alcance::text, d.nombre into v_alcance, v_nombre
      from diagnosticos d where d.id = new.diagnosis_id;
  else
    select t.alcance::text, t.nombre into v_alcance, v_nombre
      from tratamientos t where t.id = new.tratamiento_id;
  end if;

  if v_alcance is null then
    return new; -- El catálogo responde por su propia integridad referencial.
  end if;

  if v_alcance = 'puntual' then
    if new.diente_id is null then
      raise exception '"%" se aplica sobre una superficie y llegó sin pieza.', v_nombre
        using errcode = 'CL012';
    end if;
    if new.superficie is null then
      raise exception '"%" se aplica sobre una superficie concreta: falta indicarla.', v_nombre
        using errcode = 'CL012';
    end if;
  elsif v_alcance = 'diente' then
    if new.diente_id is null then
      raise exception '"%" se aplica sobre una pieza y llegó sin pieza.', v_nombre
        using errcode = 'CL012';
    end if;
    if new.superficie is not null then
      raise exception '"%" se aplica a la pieza completa, no a una superficie.', v_nombre
        using errcode = 'CL012';
    end if;
  else -- arcada, global
    if new.diente_id is not null then
      raise exception '"%" tiene alcance % y no puede asignarse a una pieza.',
        v_nombre, v_alcance
        using errcode = 'CL012';
    end if;
    if new.superficie is not null then
      raise exception '"%" tiene alcance % y no puede asignarse a una superficie.',
        v_nombre, v_alcance
        using errcode = 'CL012';
    end if;
  end if;

  return new;
end;
$$;

alter function public.hfx_clin_003_validar_alcance() owner to postgres;

drop trigger if exists trg_validar_alcance_diagnostico on public.diagnosticos_aplicados;
create trigger trg_validar_alcance_diagnostico
  before insert or update of diagnosis_id, diente_id, superficie
  on public.diagnosticos_aplicados
  for each row when (new.deleted_at is null)
  execute function public.hfx_clin_003_validar_alcance();

drop trigger if exists trg_validar_alcance_tratamiento on public.tratamientos_aplicados;
create trigger trg_validar_alcance_tratamiento
  before insert or update of tratamiento_id, diente_id, superficie
  on public.tratamientos_aplicados
  for each row when (new.deleted_at is null)
  execute function public.hfx_clin_003_validar_alcance();

-- "Realizado" y "en proceso" no pueden ser verdad a la vez: el estado manda y
-- el booleano histórico se deriva de él.
create or replace function public.hfx_clin_003_coherencia_ejecucion()
returns trigger
language plpgsql
set search_path to 'public'
as $$
begin
  new.esta_terminado := (coalesce(new.estado, 'aplicado') = 'completado');
  return new;
end;
$$;

alter function public.hfx_clin_003_coherencia_ejecucion() owner to postgres;

drop trigger if exists trg_coherencia_ejecucion on public.tratamientos_aplicados;
create trigger trg_coherencia_ejecucion
  before insert or update on public.tratamientos_aplicados
  for each row execute function public.hfx_clin_003_coherencia_ejecucion();

-- ---------------------------------------------------------------------------
-- 7. Consentimiento del plan
-- ---------------------------------------------------------------------------

alter table public.planes_tratamiento
  add column if not exists version integer not null default 1;

comment on column public.planes_tratamiento.version is
  'HFX-CLIN-003. Sube con cada cambio de actividades o precios; el consentimiento guarda la versión que el paciente vio.';

-- Cambiar las actividades o los precios invalida el consentimiento anterior:
-- el paciente aceptó otra cosa. La versión es lo que lo hace comprobable.
create or replace function public.hfx_clin_003_versionar_plan()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_plan uuid := coalesce(new.plan_id, old.plan_id);
begin
  if tg_op = 'UPDATE'
     and new.tratamiento_id is not distinct from old.tratamiento_id
     and new.precio_estimado is not distinct from old.precio_estimado
     and new.diente_id is not distinct from old.diente_id
     and new.superficie is not distinct from old.superficie
     and new.deleted_at is not distinct from old.deleted_at then
    return new;
  end if;

  update planes_tratamiento
     set version = version + 1, updated_at = now()
   where id = v_plan;

  return coalesce(new, old);
end;
$$;

alter function public.hfx_clin_003_versionar_plan() owner to postgres;

drop trigger if exists trg_versionar_plan on public.items_plan_tratamiento;
create trigger trg_versionar_plan
  after insert or update or delete on public.items_plan_tratamiento
  for each row execute function public.hfx_clin_003_versionar_plan();

create table if not exists public.consentimientos_plan (
  id                    uuid primary key default gen_random_uuid(),
  plan_id               uuid not null references public.planes_tratamiento(id) on delete cascade,
  version_plan          integer not null,
  decision              text not null,
  items                 jsonb not null default '[]'::jsonb,
  total_aceptado        numeric(15,2) not null default 0,
  persona_acepta        text not null,
  relacion_con_paciente text not null default 'titular',
  metodo                text not null,
  motivo_rechazo        text,
  registrado_por        uuid references public.usuarios(id),
  fecha                 timestamptz not null default now(),
  created_at            timestamptz not null default now(),
  constraint consentimientos_plan_decision_check
    check (decision in ('aceptado', 'rechazado')),
  constraint consentimientos_plan_metodo_check
    check (metodo in ('verbal_presencial', 'firma_fisica', 'firma_digital', 'telefonico')),
  constraint consentimientos_plan_rechazo_check
    check (decision <> 'rechazado' or coalesce(btrim(motivo_rechazo), '') <> ''),
  constraint consentimientos_plan_persona_check
    check (coalesce(btrim(persona_acepta), '') <> '')
);

comment on table public.consentimientos_plan is
  'HFX-CLIN-003. Evidencia de la decisión del paciente: versión del plan mostrado, tratamientos y precios aceptados, quién decidió y por qué medio. Una decisión del doctor en la UI no es una firma del paciente.';

create index if not exists consentimientos_plan_plan_idx
  on public.consentimientos_plan (plan_id, fecha desc);

alter table public.consentimientos_plan enable row level security;

drop policy if exists consentimientos_plan_select on public.consentimientos_plan;
create policy consentimientos_plan_select on public.consentimientos_plan
  for select to authenticated
  using (
    public.es_admin() or public.es_doctor() or public.es_asistente()
  );

-- Un plan no pasa a aceptado sin evidencia de quién aceptó y qué vio.
create or replace function public.hfx_clin_003_exigir_consentimiento()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if new.estado::text not in ('aceptado', 'rechazado') then
    return new;
  end if;
  if old.estado::text = new.estado::text then
    return new;
  end if;

  if not exists (
    select 1 from consentimientos_plan cp
     where cp.plan_id = new.id
       and cp.decision = new.estado::text
       and cp.version_plan = new.version
  ) then
    raise exception 'El plan % no puede pasar a "%" sin consentimiento registrado de la versión % del plan.',
      new.id, new.estado, new.version
      using errcode = 'CL013';
  end if;

  return new;
end;
$$;

alter function public.hfx_clin_003_exigir_consentimiento() owner to postgres;

drop trigger if exists trg_exigir_consentimiento_plan on public.planes_tratamiento;
create trigger trg_exigir_consentimiento_plan
  before update of estado on public.planes_tratamiento
  for each row execute function public.hfx_clin_003_exigir_consentimiento();

-- Registrar la decisión y aplicarla al plan es una sola operación: no puede
-- quedar un plan aceptado sin evidencia ni una evidencia sin plan.
create or replace function public.registrar_consentimiento_plan(
  p_plan_id      uuid,
  p_decision     text,
  p_persona      text,
  p_metodo       text,
  p_relacion     text default 'titular',
  p_motivo       text default null,
  p_items        jsonb default null
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_plan     record;
  v_items    jsonb;
  v_total    numeric(15,2);
  v_actor    uuid := auth.uid();
  v_id       uuid;
begin
  if p_decision not in ('aceptado', 'rechazado') then
    raise exception 'Decisión de consentimiento no válida: %.', p_decision
      using errcode = 'CL013';
  end if;

  select * into v_plan from planes_tratamiento
   where id = p_plan_id and deleted_at is null
     for update;

  if not found then
    raise exception 'El plan % no existe o fue eliminado.', p_plan_id
      using errcode = 'CL004';
  end if;

  if not public.es_contexto_interno() then
    if v_actor is null or not (public.es_doctor() or public.es_admin()) then
      raise exception 'Solo un doctor puede registrar el consentimiento de un plan.'
        using errcode = '42501';
    end if;
  end if;

  if coalesce(btrim(p_persona), '') = '' then
    raise exception 'Falta el nombre de quien acepta o rechaza el plan.'
      using errcode = 'CL013';
  end if;

  -- Los precios que se guardan como aceptados son los del plan en este momento,
  -- no los que el cliente diga: la evidencia no la redacta la pantalla.
  select coalesce(jsonb_agg(jsonb_build_object(
           'item_plan_id', i.id,
           'tratamiento_id', i.tratamiento_id,
           'diente_id', i.diente_id,
           'superficie', i.superficie,
           'precio_estimado', i.precio_estimado,
           'estado', i.estado
         ) order by i.orden), '[]'::jsonb),
         coalesce(sum(i.precio_estimado), 0)
    into v_items, v_total
    from items_plan_tratamiento i
   where i.plan_id = p_plan_id
     and i.deleted_at is null
     and (p_items is null or i.id::text in (
           select jsonb_array_elements_text(p_items)));

  insert into consentimientos_plan (
    plan_id, version_plan, decision, items, total_aceptado, persona_acepta,
    relacion_con_paciente, metodo, motivo_rechazo, registrado_por
  ) values (
    p_plan_id, v_plan.version, p_decision, v_items,
    case when p_decision = 'aceptado' then v_total else 0 end,
    btrim(p_persona), coalesce(nullif(btrim(p_relacion), ''), 'titular'),
    p_metodo, nullif(btrim(p_motivo), ''), v_actor
  ) returning id into v_id;

  update planes_tratamiento
     set estado = p_decision::estado_plan_tratamiento,
         fecha_aceptacion = case when p_decision = 'aceptado' then now() else fecha_aceptacion end,
         fecha_rechazo = case when p_decision = 'rechazado' then now() else fecha_rechazo end,
         motivo_rechazo = case when p_decision = 'rechazado' then nullif(btrim(p_motivo), '') else motivo_rechazo end,
         updated_at = now()
   where id = p_plan_id;

  return jsonb_build_object(
    'consentimiento_id', v_id,
    'plan_id', p_plan_id,
    'version_plan', v_plan.version,
    'decision', p_decision,
    'total_aceptado', case when p_decision = 'aceptado' then v_total else 0 end,
    'items', v_items
  );
end;
$$;

alter function public.registrar_consentimiento_plan(uuid, text, text, text, text, text, jsonb)
  owner to postgres;

-- ---------------------------------------------------------------------------
-- 8. Motor de alertas
-- ---------------------------------------------------------------------------

-- Edad del paciente en años. La dosificación pediátrica y cualquier umbral que
-- dependa de la franja etaria la necesitan; devuelve null cuando el expediente
-- no tiene fecha de nacimiento, y en ese caso la regla no se evalúa en vez de
-- suponer una edad.
create or replace function public.hfx_clin_003_edad_paciente(p_paciente_id uuid)
returns numeric
language sql
stable
security definer
set search_path to 'public'
as $$
  select case
           when p.fecha_nacimiento is null then null
           else extract(epoch from age(current_date, p.fecha_nacimiento)) / 31557600.0
         end
    from personas p
   where p.id = p_paciente_id;
$$;

alter function public.hfx_clin_003_edad_paciente(uuid) owner to postgres;

-- ¿Aplica esta regla a la edad de este paciente? Sin franja configurada aplica
-- siempre; con franja configurada y sin fecha de nacimiento no aplica, porque
-- el sistema no puede afirmar que el paciente entra en ella.
create or replace function public.hfx_clin_003_regla_aplica_edad(
  p_parametros jsonb,
  p_edad       numeric
) returns boolean
language sql
immutable
as $$
  select case
           when p_parametros is null then true
           when (p_parametros ? 'edad_min_anios') is false
            and (p_parametros ? 'edad_max_anios') is false then true
           when p_edad is null then false
           else coalesce(p_edad >= (p_parametros ->> 'edad_min_anios')::numeric, true)
            and coalesce(p_edad <  (p_parametros ->> 'edad_max_anios')::numeric, true)
         end;
$$;

alter function public.hfx_clin_003_regla_aplica_edad(jsonb, numeric) owner to postgres;

-- Evalúa las reglas aprobadas sobre los datos ya guardados de la consulta y
-- deja las alertas resultantes. Las alertas que dejaron de aplicar se marcan
-- obsoletas en vez de borrarse: la consulta conserva por qué se avisó.
create or replace function public.hfx_clin_003_evaluar_alertas(p_consulta_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_regla     record;
  v_signo     record;
  v_vigentes  text[] := '{}';
  v_valor     numeric;
  v_min       numeric;
  v_max       numeric;
  v_codigo    text;
  v_mensaje   text;
  v_cond      text;
  v_paciente  uuid;
  v_edad      numeric;
begin
  select paciente_id into v_paciente from consultas where id = p_consulta_id;
  v_edad := public.hfx_clin_003_edad_paciente(v_paciente);

  for v_regla in
    select * from reglas_clinicas
     where estado = 'aprobada'
       and parametros is not null
       and tipo in ('valor_critico', 'combinacion_condicion_signo',
                    'requisito_dato')
     order by codigo
  loop
    -- Una regla limitada a una franja etaria no se evalúa fuera de ella.
    if not public.hfx_clin_003_regla_aplica_edad(v_regla.parametros, v_edad) then
      continue;
    end if;

    if v_regla.tipo = 'requisito_dato' then
      v_codigo := v_regla.parametros ->> 'codigo';

      -- El dato exigido ya está: nada que avisar.
      if exists (
        select 1 from signos_vitales_consulta sv
         where sv.consulta_id = p_consulta_id
           and sv.codigo = v_codigo
           and sv.deleted_at is null
      ) then
        continue;
      end if;

      v_mensaje := format('%s: falta registrar %s en esta consulta.',
        v_regla.nombre,
        coalesce((select lower(etiqueta) from catalogo_signos_vitales
                   where codigo = v_codigo), v_codigo));

      insert into alertas_clinicas (
        consulta_id, regla_id, regla_codigo, regla_version, severidad, accion,
        mensaje, disparador
      ) values (
        p_consulta_id, v_regla.id, v_regla.codigo, v_regla.version,
        v_regla.severidad, v_regla.accion, v_mensaje,
        jsonb_build_object('codigo', v_codigo, 'valor', null,
                           'edad_anios', round(v_edad, 1), 'faltante', true)
      )
      on conflict (consulta_id, regla_codigo, regla_version)
        where estado <> 'obsoleta'
      do update set mensaje = excluded.mensaje,
                    disparador = excluded.disparador,
                    updated_at = now();

      v_vigentes := v_vigentes || v_regla.codigo;

    elsif v_regla.tipo = 'valor_critico' then
      v_codigo := v_regla.parametros ->> 'codigo';
      v_min := nullif(v_regla.parametros ->> 'min', '')::numeric;
      v_max := nullif(v_regla.parametros ->> 'max', '')::numeric;

      select sv.valor, cat.etiqueta, cat.unidad
        into v_signo
        from signos_vitales_consulta sv
        join catalogo_signos_vitales cat on cat.codigo = sv.codigo
       where sv.consulta_id = p_consulta_id
         and sv.codigo = v_codigo
         and sv.deleted_at is null
       limit 1;

      if not found then
        continue;
      end if;

      v_valor := v_signo.valor;
      if (v_min is not null and v_valor < v_min)
         or (v_max is not null and v_valor > v_max) then
        v_mensaje := format('%s = %s %s fuera del rango clínico aprobado (%s a %s).',
          v_signo.etiqueta, v_valor, v_signo.unidad,
          coalesce(v_min::text, '—'), coalesce(v_max::text, '—'));

        insert into alertas_clinicas (
          consulta_id, regla_id, regla_codigo, regla_version, severidad, accion,
          mensaje, disparador
        ) values (
          p_consulta_id, v_regla.id, v_regla.codigo, v_regla.version,
          v_regla.severidad, v_regla.accion, v_mensaje,
          jsonb_build_object('codigo', v_codigo, 'valor', v_valor,
                             'min', v_min, 'max', v_max)
        )
        on conflict (consulta_id, regla_codigo, regla_version)
          where estado <> 'obsoleta'
        do update set mensaje = excluded.mensaje,
                      disparador = excluded.disparador,
                      updated_at = now();

        v_vigentes := v_vigentes || v_regla.codigo;
      end if;

    else -- combinacion_condicion_signo
      v_cond := v_regla.parametros ->> 'condicion';

      if not exists (
        select 1 from condiciones_activas_paciente cap
          join condiciones c on c.id = cap.condicion_id
         where cap.paciente_id = v_paciente
           and lower(c.nombre) like '%' || lower(v_cond) || '%'
      ) then
        continue;
      end if;

      for v_signo in
        select (s ->> 'codigo') as codigo,
               nullif(s ->> 'min', '')::numeric as minimo,
               nullif(s ->> 'max', '')::numeric as maximo
          from jsonb_array_elements(coalesce(v_regla.parametros -> 'signos', '[]'::jsonb)) s
      loop
        select sv.valor into v_valor
          from signos_vitales_consulta sv
         where sv.consulta_id = p_consulta_id
           and sv.codigo = v_signo.codigo
           and sv.deleted_at is null
         limit 1;

        if v_valor is null then
          continue;
        end if;

        if (v_signo.minimo is not null and v_valor < v_signo.minimo)
           or (v_signo.maximo is not null and v_valor > v_signo.maximo) then
          v_mensaje := format('%s: %s = %s con la condición "%s" registrada.',
            v_regla.nombre, v_signo.codigo, v_valor, v_cond);

          insert into alertas_clinicas (
            consulta_id, regla_id, regla_codigo, regla_version, severidad,
            accion, mensaje, disparador
          ) values (
            p_consulta_id, v_regla.id, v_regla.codigo, v_regla.version,
            v_regla.severidad, v_regla.accion, v_mensaje,
            jsonb_build_object('condicion', v_cond, 'codigo', v_signo.codigo,
                               'valor', v_valor)
          )
          on conflict (consulta_id, regla_codigo, regla_version)
            where estado <> 'obsoleta'
          do update set mensaje = excluded.mensaje,
                        disparador = excluded.disparador,
                        updated_at = now();

          v_vigentes := v_vigentes || v_regla.codigo;
          exit;
        end if;
      end loop;
    end if;
  end loop;

  -- Lo que dejó de aplicar no sigue exigiendo acción, pero queda registrado.
  update alertas_clinicas
     set estado = 'obsoleta', updated_at = now()
   where consulta_id = p_consulta_id
     and estado = 'pendiente'
     and not (regla_codigo = any (v_vigentes));

  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', a.id,
             'regla', a.regla_codigo,
             'severidad', a.severidad,
             'accion', a.accion,
             'mensaje', a.mensaje,
             'estado', a.estado,
             'disparador', a.disparador
           ) order by a.created_at)
      from alertas_clinicas a
     where a.consulta_id = p_consulta_id
       and a.estado <> 'obsoleta'
  ), '[]'::jsonb);
end;
$$;

alter function public.hfx_clin_003_evaluar_alertas(uuid) owner to postgres;

-- Deja constancia de la decisión clínica sobre una alerta.
create or replace function public.resolver_alerta_clinica(
  p_alerta_id     uuid,
  p_estado        text,
  p_justificacion text default null
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_alerta record;
  v_actor  uuid;
begin
  if p_estado not in ('confirmada', 'documentada') then
    raise exception 'Estado de alerta no válido: %.', p_estado
      using errcode = 'CL007';
  end if;

  select * into v_alerta from alertas_clinicas where id = p_alerta_id;
  if not found then
    raise exception 'La alerta % no existe.', p_alerta_id using errcode = 'CL004';
  end if;

  v_actor := public.hfx_clin_002_actor_clinico(v_alerta.consulta_id);

  if p_estado = 'documentada' and coalesce(btrim(p_justificacion), '') = '' then
    raise exception 'Esta alerta exige una acción documentada: falta la justificación clínica.'
      using errcode = 'CL007';
  end if;

  update alertas_clinicas
     set estado = p_estado,
         justificacion = nullif(btrim(p_justificacion), ''),
         resuelta_por = v_actor,
         resuelta_en = now(),
         updated_at = now()
   where id = p_alerta_id;

  insert into auditoria_clinica (consulta_id, evento, actor_id, rol, metadata)
  values (
    v_alerta.consulta_id, 'alerta_resuelta', v_actor,
    case when public.es_admin() then 'admin' else 'doctor' end,
    jsonb_build_object('alerta_id', p_alerta_id, 'regla', v_alerta.regla_codigo,
                       'estado', p_estado)
  );

  return jsonb_build_object('id', p_alerta_id, 'estado', p_estado);
end;
$$;

alter function public.resolver_alerta_clinica(uuid, text, text) owner to postgres;

-- ---------------------------------------------------------------------------
-- 9. Receta: renglón estructurado, bloqueo absoluto y coherencia
-- ---------------------------------------------------------------------------

-- Conflictos entre las medicinas de una receta y las condiciones activas del
-- paciente, incluidas las descubiertas hoy. Devuelve una fila por conflicto.
create or replace function public.hfx_clin_003_conflictos_receta(
  p_consulta_id uuid,
  p_items       jsonb
) returns table (
  medicina_id   uuid,
  medicina      text,
  condicion     text,
  tipo          text,
  descripcion   text
)
language sql
security definer
set search_path to 'public'
as $$
  select m.id,
         coalesce(m.nombre, i ->> 'nombre_medicamento'),
         c.nombre,
         ci.tipo_contraindicacion::text,
         ci.descripcion
    from jsonb_array_elements(coalesce(p_items, '[]'::jsonb)) i
    join medicinas m on m.id = nullif(i ->> 'medicamento_id', '')::uuid
    join contraindicaciones ci
      on ci.medicina_id = m.id and ci.deleted_at is null
    join condiciones c on c.id = ci.condicion_id
   where exists (
     select 1
       from condiciones_activas_paciente cap
       join consultas cons on cons.id = p_consulta_id
      where cap.paciente_id = cons.paciente_id
        and cap.condicion_id = ci.condicion_id
   );
$$;

alter function public.hfx_clin_003_conflictos_receta(uuid, jsonb) owner to postgres;

-- Validación de los renglones. `p_estricto` distingue el borrador —donde el
-- doctor todavía está escribiendo— de la emisión, que es un documento clínico.
-- La contraindicación absoluta bloquea en ambos: no hay momento en el que sea
-- aceptable.
create or replace function public.hfx_clin_003_validar_receta(
  p_consulta_id uuid,
  p_items       jsonb,
  p_estricto    boolean default false
) returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_item        jsonb;
  v_conflicto   record;
  v_nombre      text;
  v_dosis       numeric;
  v_frecuencia  numeric;
  v_duracion    numeric;
  v_cantidad    numeric;
  v_esperada    numeric;
  v_vistos      text[] := '{}';
  v_clave       text;
  v_principio   text;
  v_paciente    uuid;
  v_edad        numeric;
  v_req         record;
begin
  if p_items is null or jsonb_typeof(p_items) <> 'array'
     or jsonb_array_length(p_items) = 0 then
    return;
  end if;

  -- 9.1 Contraindicación absoluta: sin excepción, ni con justificación.
  for v_conflicto in
    select * from public.hfx_clin_003_conflictos_receta(p_consulta_id, p_items)
     where tipo = 'absoluta'
  loop
    raise exception '% está contraindicado de forma absoluta por "%": %.',
      v_conflicto.medicina, v_conflicto.condicion, v_conflicto.descripcion
      using errcode = 'CL010';
  end loop;

  -- 9.1.b Dosificación por peso: si el dueño clínico aprobó hasta qué edad la
  -- receta exige peso registrado, no se emite sin ese dato. Mientras la regla
  -- siga pendiente no hay barrera: aquí no se inventa el corte pediátrico.
  if p_estricto then
    select paciente_id into v_paciente from consultas where id = p_consulta_id;
    v_edad := public.hfx_clin_003_edad_paciente(v_paciente);

    for v_req in
      select * from reglas_clinicas
       where estado = 'aprobada'
         and parametros is not null
         and tipo = 'requisito_dato'
         and coalesce((parametros ->> 'exige_al_recetar')::boolean, false)
    loop
      if not public.hfx_clin_003_regla_aplica_edad(v_req.parametros, v_edad) then
        continue;
      end if;

      if not exists (
        select 1 from signos_vitales_consulta sv
         where sv.consulta_id = p_consulta_id
           and sv.codigo = v_req.parametros ->> 'codigo'
           and sv.deleted_at is null
      ) then
        raise exception 'No se puede emitir la receta: falta % y la dosificación de este paciente depende de ese dato.',
          coalesce((select lower(etiqueta) from catalogo_signos_vitales
                     where codigo = v_req.parametros ->> 'codigo'),
                   v_req.parametros ->> 'codigo')
          using errcode = 'CL012';
      end if;
    end loop;
  end if;

  for v_item in select value from jsonb_array_elements(p_items)
  loop
    v_nombre := coalesce(nullif(v_item ->> 'nombre_medicamento', ''), 'el medicamento');

    -- 9.2 Riesgo relativo: justificación por medicamento, no una nota global.
    if exists (
      select 1 from public.hfx_clin_003_conflictos_receta(
                   p_consulta_id, jsonb_build_array(v_item))
       where tipo = 'relativa'
    ) and coalesce(btrim(v_item ->> 'justificacion_riesgo'), '') = '' then
      raise exception '% tiene una contraindicación relativa para este paciente y exige justificación clínica propia.',
        v_nombre
        using errcode = 'CL011';
    end if;

    if not p_estricto then
      continue;
    end if;

    -- 9.3 Renglón estructurado.
    v_dosis      := nullif(v_item ->> 'dosis_cantidad', '')::numeric;
    v_frecuencia := nullif(v_item ->> 'frecuencia_horas', '')::numeric;
    v_duracion   := nullif(v_item ->> 'duracion_dias', '')::numeric;
    v_cantidad   := nullif(v_item ->> 'cantidad_total', '')::numeric;

    if v_dosis is null or v_dosis <= 0
       or coalesce(btrim(v_item ->> 'dosis_unidad'), '') = ''
       or coalesce(btrim(v_item ->> 'via_administracion'), '') = '' then
      raise exception 'El renglón de % no tiene dosis, unidad o vía de administración.',
        v_nombre using errcode = 'CL008';
    end if;

    if v_frecuencia is null or v_frecuencia <= 0 or v_frecuencia > 168 then
      raise exception 'La frecuencia de % debe estar entre 1 y 168 horas.',
        v_nombre using errcode = 'CL008';
    end if;

    if v_duracion is null or v_duracion <= 0 or v_duracion > 365 then
      raise exception 'La duración de % debe estar entre 1 y 365 días.',
        v_nombre using errcode = 'CL008';
    end if;

    if v_cantidad is null or v_cantidad <= 0 then
      raise exception 'Falta la cantidad total a despachar de %.',
        v_nombre using errcode = 'CL008';
    end if;

    -- 9.4 Coherencia: lo que se despacha tiene que alcanzar para el tratamiento
    -- indicado, y no duplicarlo.
    v_esperada := ceil(24.0 / v_frecuencia) * v_duracion * v_dosis;
    if v_cantidad < v_esperada or v_cantidad > v_esperada * 2 then
      raise exception 'La cantidad de % (%) no cuadra con % cada % horas durante % días (se esperaban ~%).',
        v_nombre, v_cantidad, v_dosis, v_frecuencia, v_duracion, v_esperada
        using errcode = 'CL008';
    end if;

    -- 9.5 Duplicidad: por medicamento y por principio activo cuando se conoce.
    v_clave := coalesce(nullif(v_item ->> 'medicamento_id', ''),
                        lower(btrim(coalesce(v_item ->> 'nombre_medicamento', ''))));
    if v_clave = any (v_vistos) then
      raise exception 'La receta repite %.', v_nombre using errcode = 'CL009';
    end if;
    v_vistos := v_vistos || v_clave;

    select lower(btrim(m.principio_activo)) into v_principio
      from medicinas m
     where m.id = nullif(v_item ->> 'medicamento_id', '')::uuid
       and coalesce(btrim(m.principio_activo), '') <> '';

    if v_principio is not null then
      if ('pa:' || v_principio) = any (v_vistos) then
        raise exception 'La receta repite el principio activo "%" en más de un medicamento.',
          v_principio using errcode = 'CL009';
      end if;
      v_vistos := v_vistos || ('pa:' || v_principio);
    end if;
  end loop;
end;
$$;

alter function public.hfx_clin_003_validar_receta(uuid, jsonb, boolean) owner to postgres;

-- ---------------------------------------------------------------------------
-- 10. Extensión del borrador clínico
-- ---------------------------------------------------------------------------

-- Se aplica después de `hfx_clin_002_aplicar_borrador`, sobre la misma
-- transacción y el mismo contrato: clave ausente no se toca; clave presente
-- describe el conjunto completo deseado.
create or replace function public.hfx_clin_003_aplicar_extras(
  p_consulta_id uuid,
  p_actor_id    uuid,
  p_payload     jsonb
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_fila        jsonb;
  v_conservados uuid[];
  v_codigos     text[];
  v_sistolica   numeric;
  v_diastolica  numeric;
  v_paciente    uuid;
  v_record      uuid;
  v_id          uuid;
  v_diente_id   uuid;
  v_signos      jsonb := '{}'::jsonb;
begin
  p_payload := coalesce(p_payload, '{}'::jsonb);

  select paciente_id into v_paciente from consultas where id = p_consulta_id;

  -- 10.1 Signos vitales estructurados.
  if jsonb_exists(p_payload, 'signos_vitales_medidos')
     and jsonb_typeof(p_payload -> 'signos_vitales_medidos') = 'array' then

    v_codigos := coalesce((
      select array_agg(f ->> 'codigo')
        from jsonb_array_elements(p_payload -> 'signos_vitales_medidos') as f
       where nullif(f ->> 'codigo', '') is not null
         and nullif(f ->> 'valor', '') is not null), '{}'::text[]);

    update signos_vitales_consulta
       set deleted_at = now(), updated_at = now()
     where consulta_id = p_consulta_id
       and deleted_at is null
       and not (codigo = any (v_codigos));

    for v_fila in
      select value from jsonb_array_elements(p_payload -> 'signos_vitales_medidos')
    loop
      if nullif(v_fila ->> 'codigo', '') is null
         or nullif(v_fila ->> 'valor', '') is null then
        continue;
      end if;

      insert into signos_vitales_consulta (
        consulta_id, codigo, valor, unidad, medido_en, medido_por, origen,
        observacion, estado_validacion
      ) values (
        p_consulta_id,
        v_fila ->> 'codigo',
        (v_fila ->> 'valor')::numeric,
        coalesce(nullif(v_fila ->> 'unidad', ''),
                 (select unidad from catalogo_signos_vitales
                   where codigo = v_fila ->> 'codigo')),
        coalesce(nullif(v_fila ->> 'medido_en', '')::timestamptz, now()),
        coalesce(nullif(v_fila ->> 'medido_por', '')::uuid, p_actor_id),
        coalesce(nullif(v_fila ->> 'origen', ''), 'medido'),
        nullif(v_fila ->> 'observacion', ''),
        coalesce(nullif(v_fila ->> 'estado_validacion', ''), 'valido')
      )
      on conflict (consulta_id, codigo) where deleted_at is null
      do update set valor = excluded.valor,
                    unidad = excluded.unidad,
                    medido_en = excluded.medido_en,
                    medido_por = excluded.medido_por,
                    origen = excluded.origen,
                    observacion = excluded.observacion,
                    estado_validacion = excluded.estado_validacion,
                    updated_at = now();
    end loop;

    -- Relación imposible: se comprueba con las dos mediciones ya guardadas.
    select max(valor) filter (where codigo = 'presion_sistolica'),
           max(valor) filter (where codigo = 'presion_diastolica')
      into v_sistolica, v_diastolica
      from signos_vitales_consulta
     where consulta_id = p_consulta_id and deleted_at is null;

    if v_sistolica is not null and v_diastolica is not null
       and v_diastolica >= v_sistolica then
      raise exception 'La diastólica (%) no puede igualar ni superar la sistólica (%).',
        v_diastolica, v_sistolica
        using errcode = 'CL006';
    end if;

    -- `consultas.signos_vitales` se conserva como resumen derivado para los
    -- lectores antiguos (detalle, PDF del expediente); la tabla es la verdad.
    select coalesce(jsonb_object_agg(codigo, valor), '{}'::jsonb)
      into v_signos
      from signos_vitales_consulta
     where consulta_id = p_consulta_id and deleted_at is null;

    update consultas
       set signos_vitales = case when v_signos = '{}'::jsonb then null else v_signos end,
           updated_at = now()
     where id = p_consulta_id;
  end if;

  -- 10.2 Condiciones descubiertas durante la consulta.
  if jsonb_exists(p_payload, 'condiciones_detectadas')
     and jsonb_typeof(p_payload -> 'condiciones_detectadas') = 'array' then

    v_conservados := coalesce((
      select array_agg((f ->> 'condicion_id')::uuid)
        from jsonb_array_elements(p_payload -> 'condiciones_detectadas') as f
       where nullif(f ->> 'condicion_id', '') is not null), '{}'::uuid[]);

    update condiciones_consulta
       set deleted_at = now(), updated_at = now()
     where consulta_id = p_consulta_id
       and deleted_at is null
       and not (condicion_id = any (v_conservados));

    for v_fila in
      select value from jsonb_array_elements(p_payload -> 'condiciones_detectadas')
    loop
      if nullif(v_fila ->> 'condicion_id', '') is null then
        continue;
      end if;

      insert into condiciones_consulta (
        consulta_id, condicion_id, severidad, notas, detectada_en,
        incorporar_al_expediente, confirmada_por, confirmada_en
      ) values (
        p_consulta_id,
        (v_fila ->> 'condicion_id')::uuid,
        coalesce(nullif(v_fila ->> 'severidad', ''), 'moderada'),
        nullif(v_fila ->> 'notas', ''),
        coalesce(nullif(v_fila ->> 'detectada_en', '')::timestamptz, now()),
        coalesce((v_fila ->> 'incorporar_al_expediente')::boolean, false),
        case when coalesce((v_fila ->> 'incorporar_al_expediente')::boolean, false)
             then p_actor_id end,
        case when coalesce((v_fila ->> 'incorporar_al_expediente')::boolean, false)
             then now() end
      )
      on conflict (consulta_id, condicion_id) where deleted_at is null
      do update set severidad = excluded.severidad,
                    notas = excluded.notas,
                    incorporar_al_expediente = excluded.incorporar_al_expediente,
                    confirmada_por = excluded.confirmada_por,
                    confirmada_en = excluded.confirmada_en,
                    updated_at = now();
    end loop;
  end if;

  -- 10.3 Hallazgos y ejecuciones sin pieza: lo que el catálogo declara global o
  -- de arcada. Antes solo existía la vía por diente, que es justo lo que la
  -- base ahora rechaza.
  if jsonb_exists(p_payload, 'generales')
     and jsonb_typeof(p_payload -> 'generales') = 'object' then

    v_conservados := coalesce((
      select array_agg((f ->> 'id')::uuid)
        from jsonb_array_elements(
               coalesce(p_payload -> 'generales' -> 'tratamientos', '[]'::jsonb)) as f
       where nullif(f ->> 'id', '') is not null), '{}'::uuid[]);

    update tratamientos_aplicados
       set deleted_at = now(), updated_at = now()
     where consulta_id = p_consulta_id
       and diente_id is null
       and deleted_at is null
       and not (id = any (v_conservados));

    for v_fila in
      select value from jsonb_array_elements(
        coalesce(p_payload -> 'generales' -> 'tratamientos', '[]'::jsonb))
    loop
      v_id := nullif(v_fila ->> 'id', '')::uuid;
      if v_id is null then
        insert into tratamientos_aplicados (
          tratamiento_id, consulta_id, precio_aplicado, notas, estado,
          item_plan_id, justificacion_no_planificada, doctor_ejecuta_id,
          fecha_ejecucion, created_at, updated_at
        ) values (
          (v_fila ->> 'tratamiento_id')::uuid,
          p_consulta_id,
          nullif(v_fila ->> 'precio_aplicado', '')::numeric,
          v_fila ->> 'notas',
          coalesce(nullif(v_fila ->> 'estado', ''), 'aplicado'),
          nullif(v_fila ->> 'item_plan_id', '')::uuid,
          v_fila ->> 'justificacion_no_planificada',
          coalesce(nullif(v_fila ->> 'doctor_ejecuta_id', '')::uuid, p_actor_id),
          coalesce(nullif(v_fila ->> 'fecha_ejecucion', '')::timestamptz, now()),
          now(), now()
        );
      else
        update tratamientos_aplicados
           set tratamiento_id = (v_fila ->> 'tratamiento_id')::uuid,
               precio_aplicado = nullif(v_fila ->> 'precio_aplicado', '')::numeric,
               notas = v_fila ->> 'notas',
               estado = coalesce(nullif(v_fila ->> 'estado', ''), estado),
               item_plan_id = nullif(v_fila ->> 'item_plan_id', '')::uuid,
               justificacion_no_planificada = v_fila ->> 'justificacion_no_planificada',
               deleted_at = null,
               updated_at = now()
         where id = v_id and consulta_id = p_consulta_id and diente_id is null;

        if not found then
          raise exception 'El tratamiento general % no pertenece a la consulta %.',
            v_id, p_consulta_id using errcode = 'CL004';
        end if;
      end if;
    end loop;

    v_conservados := coalesce((
      select array_agg((f ->> 'id')::uuid)
        from jsonb_array_elements(
               coalesce(p_payload -> 'generales' -> 'diagnosticos', '[]'::jsonb)) as f
       where nullif(f ->> 'id', '') is not null), '{}'::uuid[]);

    update diagnosticos_aplicados
       set deleted_at = now(), updated_at = now()
     where consulta_id = p_consulta_id
       and diente_id is null
       and deleted_at is null
       and not (id = any (v_conservados));

    for v_fila in
      select value from jsonb_array_elements(
        coalesce(p_payload -> 'generales' -> 'diagnosticos', '[]'::jsonb))
    loop
      v_id := nullif(v_fila ->> 'id', '')::uuid;
      if v_id is null then
        insert into diagnosticos_aplicados (
          diagnosis_id, severidad, fecha_aplicacion, notas, consulta_id,
          origen, created_at, updated_at
        ) values (
          (v_fila ->> 'diagnosis_id')::uuid,
          (v_fila ->> 'severidad')::severidad_diagnosis,
          coalesce(nullif(v_fila ->> 'fecha_aplicacion', '')::timestamptz, now()),
          v_fila ->> 'notas',
          p_consulta_id,
          coalesce(nullif(v_fila ->> 'origen', ''), 'preexistente'),
          now(), now()
        );
      else
        update diagnosticos_aplicados
           set diagnosis_id = (v_fila ->> 'diagnosis_id')::uuid,
               severidad = (v_fila ->> 'severidad')::severidad_diagnosis,
               notas = v_fila ->> 'notas',
               origen = coalesce(nullif(v_fila ->> 'origen', ''), origen),
               deleted_at = null,
               updated_at = now()
         where id = v_id and consulta_id = p_consulta_id and diente_id is null;

        if not found then
          raise exception 'El hallazgo general % no pertenece a la consulta %.',
            v_id, p_consulta_id using errcode = 'CL004';
        end if;
      end if;
    end loop;
  end if;

  -- 10.4 Receta: el bloqueo absoluto vive aquí, no solo en la pantalla.
  for v_fila in
    select r.items_receta
      from recetas r
     where r.consulta_id = p_consulta_id
       and r.deleted_at is null
       and r.estado = 'borrador'
  loop
    perform public.hfx_clin_003_validar_receta(p_consulta_id, v_fila, false);
  end loop;

  return public.hfx_clin_003_evaluar_alertas(p_consulta_id);
end;
$$;

alter function public.hfx_clin_003_aplicar_extras(uuid, uuid, jsonb) owner to postgres;

-- ---------------------------------------------------------------------------
-- 11. Incorporación de condiciones al expediente y cierre con barreras
-- ---------------------------------------------------------------------------

create or replace function public.hfx_clin_003_incorporar_condiciones(p_consulta_id uuid)
returns integer
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_record uuid;
  v_total  integer := 0;
begin
  select r.id into v_record
    from records r
    join consultas c on c.paciente_id = r.paciente_id
   where c.id = p_consulta_id and r.deleted_at is null
   limit 1;

  if v_record is null then
    return 0;
  end if;

  insert into record_condicion (record_id, condicion_id, fecha_deteccion, notas, activo)
  select v_record, cc.condicion_id, cc.detectada_en, cc.notas, true
    from condiciones_consulta cc
   where cc.consulta_id = p_consulta_id
     and cc.deleted_at is null
     and cc.incorporar_al_expediente
     and not exists (
       select 1 from record_condicion rc
        where rc.record_id = v_record and rc.condicion_id = cc.condicion_id
     );

  get diagnostics v_total = row_count;
  return v_total;
end;
$$;

alter function public.hfx_clin_003_incorporar_condiciones(uuid) owner to postgres;

-- Barreras que el cierre no puede saltarse.
create or replace function public.hfx_clin_003_barreras_de_cierre(p_consulta_id uuid)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_alerta record;
  v_items  jsonb;
begin
  -- Una alerta que exige acción no se cierra por cansancio: o se confirma, o se
  -- documenta.
  for v_alerta in
    select * from alertas_clinicas
     where consulta_id = p_consulta_id
       and estado = 'pendiente'
       and accion in ('confirmar', 'documentar', 'bloquear_electivo', 'referir')
     order by created_at
  loop
    raise exception 'Alerta clínica sin resolver: %. Confírmala o documenta la acción antes de cerrar.',
      v_alerta.mensaje
      using errcode = 'CL007';
  end loop;

  -- Lo que se va a emitir se valida entero: es un documento que sale de aquí.
  for v_items in
    select r.items_receta
      from recetas r
     where r.consulta_id = p_consulta_id
       and r.deleted_at is null
       and r.estado = 'borrador'
       and jsonb_array_length(coalesce(r.items_receta, '[]'::jsonb)) > 0
  loop
    perform public.hfx_clin_003_validar_receta(p_consulta_id, v_items, true);
  end loop;
end;
$$;

alter function public.hfx_clin_003_barreras_de_cierre(uuid) owner to postgres;

-- ---------------------------------------------------------------------------
-- 12. Las dos RPC clínicas, ahora con barreras
-- ---------------------------------------------------------------------------

create or replace function public.guardar_borrador_consulta(
  p_consulta_id uuid,
  p_version     integer default null,
  p_payload     jsonb default '{}'::jsonb
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_actor_id    uuid;
  v_version     integer;
  v_finalizada  boolean;
  v_resultado   jsonb;
  v_alertas     jsonb;
  v_actualizado timestamptz;
begin
  v_actor_id := public.hfx_clin_002_actor_clinico(p_consulta_id);

  select version, coalesce(finalizada, false)
    into v_version, v_finalizada
    from consultas
   where id = p_consulta_id and deleted_at is null
     for update;

  if v_finalizada then
    raise exception 'La consulta % ya fue finalizada y no admite cambios de borrador.', p_consulta_id
      using errcode = 'CL002';
  end if;

  if p_version is not null and p_version <> v_version then
    raise exception 'La consulta cambió en otra sesión (versión % ≠ %). Recarga antes de guardar.',
      p_version, v_version
      using errcode = 'CL001';
  end if;

  v_resultado := public.hfx_clin_002_aplicar_borrador(p_consulta_id, v_actor_id, p_payload);
  v_alertas := public.hfx_clin_003_aplicar_extras(p_consulta_id, v_actor_id, p_payload);

  update consultas
     set version = version + 1, updated_at = now()
   where id = p_consulta_id
  returning version, updated_at into v_version, v_actualizado;

  return v_resultado || jsonb_build_object(
    'consulta_id', p_consulta_id,
    'version', v_version,
    'actualizado_en', v_actualizado,
    'finalizada', false,
    'alertas', v_alertas
  );
end;
$$;

alter function public.guardar_borrador_consulta(uuid, integer, jsonb) owner to postgres;

create or replace function public.cerrar_consulta(
  p_consulta_id      uuid,
  p_version          integer default null,
  p_payload          jsonb default '{}'::jsonb,
  p_idempotencia_key text default null,
  p_metodo_pago      text default 'contado',
  p_nota             text default null
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_actor_id    uuid;
  v_version     integer;
  v_finalizada  boolean;
  v_cita_id     uuid;
  v_cierre_key  text;
  v_consumo     record;
  v_stock       integer;
  v_nombre      text;
  v_cuenta_id   uuid;
  v_recetas     integer := 0;
  v_facturables integer := 0;
  v_condiciones integer := 0;
begin
  v_actor_id := public.hfx_clin_002_actor_clinico(p_consulta_id);

  select version, coalesce(finalizada, false), cita_id, cierre_key
    into v_version, v_finalizada, v_cita_id, v_cierre_key
    from consultas
   where id = p_consulta_id and deleted_at is null
     for update;

  if v_finalizada then
    if p_idempotencia_key is null
       or v_cierre_key is null
       or v_cierre_key = p_idempotencia_key then
      return public.hfx_clin_002_resultado_cierre(p_consulta_id);
    end if;

    raise exception 'La consulta % ya fue finalizada por otro cierre.', p_consulta_id
      using errcode = 'CL002';
  end if;

  if p_version is not null and p_version <> v_version then
    raise exception 'La consulta cambió en otra sesión (versión % ≠ %). Recarga antes de cerrar.',
      p_version, v_version
      using errcode = 'CL001';
  end if;

  if v_cita_id is not null then
    perform 1 from citas where id = v_cita_id for update;
  end if;

  perform public.hfx_clin_002_aplicar_borrador(p_consulta_id, v_actor_id, p_payload);
  perform public.hfx_clin_003_aplicar_extras(p_consulta_id, v_actor_id, p_payload);

  -- Barreras clínicas antes de mover inventario o dinero: si algo falta, la
  -- consulta sigue abierta y nada cambió.
  perform public.hfx_clin_003_barreras_de_cierre(p_consulta_id);

  v_condiciones := public.hfx_clin_003_incorporar_condiciones(p_consulta_id);

  for v_consumo in
    select cc.consumible_id, cc.cantidad, cc.nombre
      from consumos_consulta cc
     where cc.consulta_id = p_consulta_id and cc.deleted_at is null
     order by cc.consumible_id
  loop
    select c.stock_actual, c.nombre into v_stock, v_nombre
      from consumibles c
     where c.id = v_consumo.consumible_id and c.deleted_at is null
       for update;

    if v_stock is null then
      raise exception 'El consumible % ya no está disponible en el inventario.',
        coalesce(v_consumo.nombre, v_consumo.consumible_id::text)
        using errcode = 'CL004';
    end if;

    if v_stock < v_consumo.cantidad then
      raise exception 'Stock insuficiente de %: quedan % y la consulta consume %.',
        coalesce(v_nombre, v_consumo.nombre, v_consumo.consumible_id::text),
        v_stock, v_consumo.cantidad
        using errcode = 'CL003';
    end if;

    insert into movimientos_stock_consumible (
      consumible_id, diferencia, motivo, creado_por, consulta_id,
      stock_anterior, stock_nuevo
    ) values (
      v_consumo.consumible_id, -v_consumo.cantidad, 'consumoClinico',
      v_actor_id, p_consulta_id, 0, 0
    )
    on conflict (consulta_id, consumible_id) where consulta_id is not null
    do nothing;
  end loop;

  update recetas
     set estado = 'emitida',
         emitida_at = now(),
         fecha_emision = coalesce(fecha_emision, now()),
         version = version + 1,
         updated_at = now()
   where consulta_id = p_consulta_id
     and deleted_at is null
     and estado = 'borrador'
     and jsonb_array_length(coalesce(items_receta, '[]'::jsonb)) > 0;
  get diagnostics v_recetas = row_count;

  update recetas
     set deleted_at = now(), updated_at = now()
   where consulta_id = p_consulta_id
     and deleted_at is null
     and estado = 'borrador';

  select count(*) into v_facturables
    from tratamientos_aplicados
   where consulta_id = p_consulta_id
     and deleted_at is null
     and coalesce(estado, 'aplicado') <> 'indicado';

  if v_facturables > 0 then
    v_cuenta_id := public.hfx_base_finalizar_consulta(p_consulta_id, p_metodo_pago, p_nota);
  elsif v_cita_id is not null then
    update citas
       set estado = 'completada'::estado_cita, updated_at = now()
     where id = v_cita_id
       and estado <> 'completada'::estado_cita
       and estado <> 'cancelada'::estado_cita;
  end if;

  update consultas
     set finalizada = true,
         finalizada_at = now(),
         cerrada_por = v_actor_id,
         cierre_key = p_idempotencia_key,
         version = version + 1,
         updated_at = now()
   where id = p_consulta_id;

  insert into auditoria_clinica (consulta_id, evento, actor_id, rol, metadata)
  values (
    p_consulta_id,
    'consulta_cerrada',
    v_actor_id,
    case when public.es_admin() then 'admin' else 'doctor' end,
    jsonb_build_object(
      'cuenta_id', v_cuenta_id,
      'recetas_emitidas', v_recetas,
      'condiciones_incorporadas', v_condiciones,
      'idempotencia_key', p_idempotencia_key
    )
  );

  return public.hfx_clin_002_resultado_cierre(p_consulta_id);
end;
$$;

alter function public.cerrar_consulta(uuid, integer, jsonb, text, text, text) owner to postgres;

-- ---------------------------------------------------------------------------
-- 13. Grants: cada función del cliente se concede una por una
-- ---------------------------------------------------------------------------

revoke all on function public.hfx_clin_003_validar_signo_vital() from public, anon, authenticated;
revoke all on function public.hfx_clin_003_validar_alcance() from public, anon, authenticated;
revoke all on function public.hfx_clin_003_coherencia_ejecucion() from public, anon, authenticated;
revoke all on function public.hfx_clin_003_exigir_consentimiento() from public, anon, authenticated;
revoke all on function public.hfx_clin_003_versionar_plan() from public, anon, authenticated;
revoke all on function public.hfx_clin_003_edad_paciente(uuid) from public, anon, authenticated;
revoke all on function public.hfx_clin_003_regla_aplica_edad(jsonb, numeric) from public, anon, authenticated;
revoke all on function public.hfx_clin_003_evaluar_alertas(uuid) from public, anon, authenticated;
revoke all on function public.hfx_clin_003_conflictos_receta(uuid, jsonb) from public, anon, authenticated;
revoke all on function public.hfx_clin_003_validar_receta(uuid, jsonb, boolean) from public, anon, authenticated;
revoke all on function public.hfx_clin_003_aplicar_extras(uuid, uuid, jsonb) from public, anon, authenticated;
revoke all on function public.hfx_clin_003_incorporar_condiciones(uuid) from public, anon, authenticated;
revoke all on function public.hfx_clin_003_barreras_de_cierre(uuid) from public, anon, authenticated;
revoke all on function public.resolver_alerta_clinica(uuid, text, text) from public, anon;
revoke all on function public.registrar_consentimiento_plan(uuid, text, text, text, text, text, jsonb)
  from public, anon;

grant execute on function public.hfx_clin_003_validar_signo_vital() to service_role;
grant execute on function public.hfx_clin_003_validar_alcance() to service_role;
grant execute on function public.hfx_clin_003_coherencia_ejecucion() to service_role;
grant execute on function public.hfx_clin_003_exigir_consentimiento() to service_role;
grant execute on function public.hfx_clin_003_versionar_plan() to service_role;
grant execute on function public.hfx_clin_003_edad_paciente(uuid) to service_role;
grant execute on function public.hfx_clin_003_regla_aplica_edad(jsonb, numeric) to service_role;
grant execute on function public.hfx_clin_003_evaluar_alertas(uuid) to service_role;
grant execute on function public.hfx_clin_003_conflictos_receta(uuid, jsonb) to service_role;
grant execute on function public.hfx_clin_003_validar_receta(uuid, jsonb, boolean) to service_role;
grant execute on function public.hfx_clin_003_aplicar_extras(uuid, uuid, jsonb) to service_role;
grant execute on function public.hfx_clin_003_incorporar_condiciones(uuid) to service_role;
grant execute on function public.hfx_clin_003_barreras_de_cierre(uuid) to service_role;

grant execute on function public.resolver_alerta_clinica(uuid, text, text)
  to authenticated, service_role;
grant execute on function public.registrar_consentimiento_plan(uuid, text, text, text, text, text, jsonb)
  to authenticated, service_role;

grant select on public.catalogo_signos_vitales to authenticated, service_role;
grant select on public.signos_vitales_consulta to authenticated, service_role;
grant select on public.reglas_clinicas to authenticated, service_role;
grant select on public.alertas_clinicas to authenticated, service_role;
grant select on public.condiciones_consulta to authenticated, service_role;
grant select on public.condiciones_activas_paciente to authenticated, service_role;
grant select on public.consentimientos_plan to authenticated, service_role;

grant insert, update, delete on public.signos_vitales_consulta to service_role;
grant insert, update, delete on public.condiciones_consulta to service_role;
grant insert, update on public.alertas_clinicas to service_role;
grant insert on public.consentimientos_plan to service_role;
grant insert, update, delete on public.reglas_clinicas to service_role;

notify pgrst, 'reload schema';

commit;
