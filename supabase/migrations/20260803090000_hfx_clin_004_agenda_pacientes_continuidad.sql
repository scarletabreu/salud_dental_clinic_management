-- HFX-CLIN-004 · Agenda, pacientes y continuidad operativa
--
-- La agenda comprobaba sus propias reglas en la pantalla y la base no imponía
-- ninguna: dos recepcionistas podían reservar el mismo intervalo, la función
-- heredada comparaba `fecha_hora` exacta, tenía un estado mal escrito y ni
-- siquiera estaba conectada como trigger. El alta de un paciente eran cinco
-- escrituras sueltas que una caída de red partía por la mitad, y el inicio de
-- una consulta no era idempotente: reintentar chocaba contra el índice único
-- en vez de reanudar lo que ya existía.
--
-- Esta migración traslada esas reglas a PostgreSQL:
--
--   * la duración de una cita deja de ser opcional y el solapamiento por
--     doctor lo rechaza una restricción de exclusión, no la pantalla;
--   * el ciclo de vida de la cita se valida en la base con el mismo grafo que
--     usa la aplicación;
--   * iniciar una consulta es una operación idempotente que bloquea la cita,
--     valida identidad y estado, y reanuda en vez de duplicar;
--   * el alta y la actualización de un paciente son transacciones únicas, con
--     identidad normalizada y control de versión;
--   * la emergencia/walk-in existe como operación clínica con evidencia, y no
--     como una edición manual en Supabase.
--
-- Códigos de error estables que añade este ticket (CL001–CL013 son de
-- HFX-CLIN-002 y HFX-CLIN-003):
--
--   CL014  el intervalo solicitado choca con otra cita del mismo doctor.
--   CL015  la cita no admite iniciar o reanudar una consulta.
--   CL016  transición de estado de cita no permitida.
--   CL017  identidad de paciente duplicada (cédula ya registrada).
--   CL018  datos mínimos del paciente ausentes o inválidos.
--   CL019  conflicto de versión de la ficha del paciente.

begin;

-- ---------------------------------------------------------------------------
-- 1. La duración de una cita es un dato obligatorio
-- ---------------------------------------------------------------------------
-- Sin duración no hay intervalo que comparar, y media agenda la traía nula.
-- 30 minutos es la duración que la propia pantalla ofrece por defecto: se
-- adopta como respaldo explícito en vez de dejar el dato en el aire.

update public.citas
   set duracion_minutos = 30
 where duracion_minutos is null
    or duracion_minutos <= 0;

alter table public.citas
  alter column duracion_minutos set default 30,
  alter column duracion_minutos set not null;

alter table public.citas
  drop constraint if exists citas_duracion_posible;
alter table public.citas
  add constraint citas_duracion_posible
  check (duracion_minutos > 0 and duracion_minutos <= 1440);

comment on column public.citas.duracion_minutos is
  'HFX-CLIN-004. Minutos que la cita ocupa la agenda del doctor. Obligatoria: define el intervalo que la restricción de exclusión compara.';

-- ---------------------------------------------------------------------------
-- 2. El fin de la cita, materializado
-- ---------------------------------------------------------------------------
-- `timestamptz + interval` es STABLE, no IMMUTABLE, así que no puede vivir en
-- una columna generada ni dentro del índice de exclusión. Se materializa en
-- una columna que mantiene un trigger, y el índice se construye sobre
-- `tstzrange(fecha_hora, fin)`, que sí es inmutable.

alter table public.citas
  add column if not exists fin timestamptz;

comment on column public.citas.fin is
  'HFX-CLIN-004. Derivada de fecha_hora + duracion_minutos. La mantiene el trigger trg_citas_fin; no se escribe desde el cliente.';

create or replace function public.hfx_clin_004_calcular_fin_cita()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.fin := new.fecha_hora + make_interval(mins => new.duracion_minutos::int);
  return new;
end;
$$;

drop trigger if exists trg_citas_fin on public.citas;
create trigger trg_citas_fin
  before insert or update of fecha_hora, duracion_minutos on public.citas
  for each row execute function public.hfx_clin_004_calcular_fin_cita();

update public.citas
   set fin = fecha_hora + make_interval(mins => duracion_minutos::int)
 where fin is distinct from
       fecha_hora + make_interval(mins => duracion_minutos::int);

alter table public.citas alter column fin set not null;

-- ---------------------------------------------------------------------------
-- 3. El solapamiento lo rechaza la base
-- ---------------------------------------------------------------------------
-- La pantalla mantiene su comprobación temprana para dar respuesta inmediata,
-- pero deja de ser la autoridad: dos clientes que consultan disponibilidad a
-- la vez ya no pueden insertar ambos.
--
-- Fuera del alcance de la restricción quedan, a propósito:
--
--   * las citas eliminadas y las terminales (cancelada, completada, no
--     asistida): su intervalo ya no reserva nada;
--   * las emergencias: una urgencia no reserva agenda, la interrumpe.
--     Bloquearlas obligaría a inventar un hueco antes de atender a alguien que
--     ya está en la clínica, que es justo lo que este ticket viene a resolver.

create extension if not exists btree_gist;

-- Una instancia con citas ya solapadas no puede adoptar la restricción en
-- silencio: se nombran las culpables y se detiene la migración, porque
-- decidir cuál se mueve o se cancela es una decisión clínica, no técnica.
do $$
declare
  v_conflictos text;
begin
  select string_agg(format('%s ↔ %s', a.id, b.id), ', ')
    into v_conflictos
    from public.citas a
    join public.citas b
      on b.doctor_id = a.doctor_id
     and b.id > a.id
     and tstzrange(a.fecha_hora, a.fin, '[)')
      && tstzrange(b.fecha_hora, b.fin, '[)')
   where a.deleted_at is null and b.deleted_at is null
     and coalesce(a.es_emergencia, false) = false
     and coalesce(b.es_emergencia, false) = false
     and a.estado::text not in ('cancelada', 'completada', 'no_asistio', 'no_asistida')
     and b.estado::text not in ('cancelada', 'completada', 'no_asistio', 'no_asistida');

  if v_conflictos is not null then
    raise exception
      'HFX-CLIN-004: hay citas solapadas que deben resolverse antes de imponer la restricción: %',
      v_conflictos
      using errcode = 'CL014';
  end if;
end;
$$;

alter table public.citas
  drop constraint if exists citas_sin_solape;
alter table public.citas
  add constraint citas_sin_solape
  exclude using gist (
    doctor_id with =,
    tstzrange(fecha_hora, fin, '[)') with &&
  )
  -- Los estados se comparan como enum y no como texto a propósito: `enum::text`
  -- es STABLE y un predicado de índice exige expresiones inmutables.
  where (
    deleted_at is null
    and coalesce(es_emergencia, false) = false
    and estado not in (
      'cancelada'::public.estado_cita,
      'completada'::public.estado_cita,
      'no_asistio'::public.estado_cita,
      'no_asistida'::public.estado_cita
    )
  );

comment on constraint citas_sin_solape on public.citas is
  'HFX-CLIN-004. Un doctor no puede tener dos citas vivas cuyos intervalos se crucen. Las citas consecutivas no se cruzan: el rango es semiabierto. Las emergencias quedan fuera a propósito.';

-- La función heredada comparaba `fecha_hora` exacta, comprobaba un estado
-- inexistente ('candelada') y nunca llegó a estar conectada. Dejarla ahí solo
-- podía inducir a reconectarla y sustituir la restricción real por una
-- comprobación que nunca funcionó.
drop function if exists public.validar_disponibilidad_doctor_simple() cascade;

-- ---------------------------------------------------------------------------
-- 4. El ciclo de vida de la cita, validado en la base
-- ---------------------------------------------------------------------------
-- El grafo es el mismo que impone `EstadoCita.transicionesPermitidas` en Dart.
-- Estaba solo en el cliente, así que cualquier REST directo podía saltar de
-- `programada` a `completada` sin que nadie hubiera atendido a nadie.

create or replace function public.hfx_clin_004_estado_cita_canonico(p_estado text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case p_estado
           when 'pendiente'   then 'programada'
           when 'atendida'    then 'completada'
           when 'no_asistida' then 'no_asistio'
           else p_estado
         end;
$$;

create or replace function public.hfx_clin_004_validar_transicion_cita()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_desde text := public.hfx_clin_004_estado_cita_canonico(old.estado::text);
  v_hasta text := public.hfx_clin_004_estado_cita_canonico(new.estado::text);
  v_permitidas text[];
begin
  if v_desde = v_hasta then
    return new;
  end if;

  v_permitidas := case v_desde
    when 'programada'  then array['confirmada', 'en_espera', 'cancelada', 'no_asistio']
    when 'confirmada'  then array['en_espera', 'cancelada', 'no_asistio']
    when 'en_espera'   then array['en_consulta', 'cancelada', 'no_asistio']
    when 'en_consulta' then array['completada', 'cancelada']
    else array[]::text[]
  end;

  if not (v_hasta = any(v_permitidas)) then
    raise exception
      'La cita está en "%" y no puede pasar a "%".', v_desde, v_hasta
      using errcode = 'CL016';
  end if;

  return new;
end;
$$;

comment on function public.hfx_clin_004_validar_transicion_cita() is
  'HFX-CLIN-004. Mismo grafo que EstadoCita en Dart. `programada → en_espera` existe porque el paciente puede llegar sin haber confirmado.';

-- Antes de encender el grafo hay que dejar coherente lo que ya existe: una
-- cita con una consulta abierta está, por definición, en consulta. Sin este
-- realineamiento, cerrar esas consultas heredadas exigiría una transición que
-- el grafo prohíbe y quedarían imposibles de finalizar.
update public.citas c
   set estado = 'en_consulta', updated_at = now()
 where c.deleted_at is null
   and c.estado in (
     'programada'::public.estado_cita,
     'confirmada'::public.estado_cita,
     'en_espera'::public.estado_cita,
     'pendiente'::public.estado_cita
   )
   and exists (
     select 1 from public.consultas k
      where k.cita_id = c.id
        and k.deleted_at is null
        and coalesce(k.finalizada, false) = false
   );

drop trigger if exists trg_citas_transicion on public.citas;
create trigger trg_citas_transicion
  before update of estado on public.citas
  for each row execute function public.hfx_clin_004_validar_transicion_cita();

-- ---------------------------------------------------------------------------
-- 5. Iniciar o reanudar la consulta de una cita, sin duplicar
-- ---------------------------------------------------------------------------
-- El índice `consultas_cita_vigente_uk` (HFX-CLIN-002) impide la segunda
-- consulta vigente, pero convertía un reintento legítimo —doble toque, red
-- lenta, vuelta atrás— en un error de clave duplicada. Esta RPC resuelve el
-- caso: bloquea la cita, valida identidad y estado, y devuelve la consulta que
-- ya existe en lugar de intentar crear otra.

create or replace function public.iniciar_consulta_de_cita(
  p_cita_id uuid,
  p_dientes jsonb default '[]'::jsonb,
  p_documentos jsonb default '[]'::jsonb,
  p_temp_condiciones jsonb default '[]'::jsonb,
  p_motivo_consulta text default null,
  p_tipo_atencion public.tipo_atencion_clinica default 'consulta'
) returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_cita        public.citas%rowtype;
  v_consulta_id uuid;
  v_finalizada  boolean;
  v_estado      text;
begin
  if not public.es_contexto_interno()
     and (auth.uid() is null or not public.es_doctor()) then
    raise exception 'Sesión clínica activa requerida.' using errcode = '42501';
  end if;

  -- El bloqueo es lo que hace segura la comprobación siguiente: dos pestañas
  -- que pulsen "Iniciar consulta" a la vez se serializan aquí, y la segunda ve
  -- la consulta que creó la primera.
  select * into v_cita
    from public.citas
   where id = p_cita_id and deleted_at is null
   for update;
  if not found then
    raise exception 'La cita ya no existe o fue eliminada.' using errcode = 'CL015';
  end if;

  if not public.es_contexto_interno()
     and v_cita.doctor_id is distinct from auth.uid() then
    raise exception 'No puede atender una cita asignada a otro doctor.'
      using errcode = '42501';
  end if;

  select c.id, coalesce(c.finalizada, false)
    into v_consulta_id, v_finalizada
    from public.consultas c
   where c.cita_id = p_cita_id
     and c.deleted_at is null
   order by coalesce(c.finalizada, false), c.created_at desc
   limit 1;

  -- Reanudar es la respuesta correcta al reintento, y también la única forma
  -- de volver a una consulta que quedó abierta ayer.
  if found and not v_finalizada then
    return jsonb_build_object(
      'consulta_id', v_consulta_id,
      'estado', 'reanudada',
      'cita_estado', v_cita.estado::text
    );
  end if;

  -- Una cita ya atendida no se reabre: se consulta. Quien llame decide si
  -- navega al detalle, pero no puede escribir sobre ella.
  if found and v_finalizada then
    return jsonb_build_object(
      'consulta_id', v_consulta_id,
      'estado', 'finalizada',
      'cita_estado', v_cita.estado::text
    );
  end if;

  -- La llegada es un hecho clínico, no un trámite de recepción: sin ella nadie
  -- puede afirmar que el paciente está presente. Se exige explícitamente en vez
  -- de darla por supuesta, y el doctor que trabaja solo la registra él mismo
  -- con `registrar_llegada_cita`.
  v_estado := public.hfx_clin_004_estado_cita_canonico(v_cita.estado::text);
  if v_estado in ('cancelada', 'completada', 'no_asistio') then
    raise exception
      'La cita está "%" y no admite iniciar una consulta.', v_estado
      using errcode = 'CL015';
  end if;
  if v_estado not in ('en_espera', 'en_consulta') then
    raise exception
      'La cita está "%": registra la llegada del paciente antes de iniciar la consulta.',
      v_estado
      using errcode = 'CL015';
  end if;

  v_consulta_id := public.crear_consulta_completa(
    v_cita.persona_id,
    v_cita.doctor_id,
    v_cita.id,
    -- La consulta hereda la fecha agendada, no la del clic (SD-160).
    v_cita.fecha_hora,
    coalesce(nullif(btrim(coalesce(p_motivo_consulta, '')), ''), v_cita.motivo),
    coalesce(p_temp_condiciones, '[]'::jsonb),
    coalesce(p_dientes, '[]'::jsonb),
    coalesce(p_documentos, '[]'::jsonb),
    p_tipo_atencion
  );

  -- La transición viaja dentro de la misma transacción que la creación: no
  -- puede quedar una consulta abierta sobre una cita que sigue "en espera".
  if v_estado <> 'en_consulta' then
    update public.citas
       set estado = 'en_consulta',
           updated_at = now()
     where id = p_cita_id;
  end if;

  insert into public.auditoria_clinica (consulta_id, evento, actor_id, rol, metadata)
  values (
    v_consulta_id,
    'consulta_iniciada',
    auth.uid(),
    case when public.es_admin() then 'admin' else 'doctor' end,
    jsonb_build_object(
      'cita_id', p_cita_id,
      'es_emergencia', coalesce(v_cita.es_emergencia, false),
      'estado_cita_previo', v_estado
    )
  );

  return jsonb_build_object(
    'consulta_id', v_consulta_id,
    'estado', 'creada',
    'cita_estado', 'en_consulta'
  );
end;
$$;

comment on function public.iniciar_consulta_de_cita(
  uuid, jsonb, jsonb, jsonb, text, public.tipo_atencion_clinica
) is
  'HFX-CLIN-004. Idempotente: crea, reanuda o señala finalizada. Bloquea la cita y mueve su estado en la misma transacción.';

-- ---------------------------------------------------------------------------
-- 6. Identidad del paciente: normalización y unicidad
-- ---------------------------------------------------------------------------
-- Se define explícitamente qué es único y qué no:
--
--   * cédula: única entre personas vivas. Se comparan sin separadores y en
--     mayúsculas, no solo sus dígitos: quitar las letras fundiría en una sola
--     identidad documentos distintos que no son cédulas dominicanas
--     (pasaportes, identificadores internos). Dos fichas con la misma cédula
--     son la misma persona registrada dos veces.
--   * teléfono y correo: se normalizan pero NO son únicos. Una familia comparte
--     teléfono y correo con normalidad; exigir unicidad ahí impediría registrar
--     a los hijos de un mismo paciente.

create or replace function public.hfx_clin_004_normalizar_cedula(p_cedula text)
returns text
language sql
immutable
set search_path = ''
as $$
  select nullif(
    upper(regexp_replace(coalesce(p_cedula, ''), '[\s\-\._]', '', 'g')),
    ''
  );
$$;

create or replace function public.hfx_clin_004_normalizar_telefono(p_telefono text)
returns text
language sql
immutable
set search_path = ''
as $$
  select nullif(regexp_replace(coalesce(p_telefono, ''), '[^0-9]', '', 'g'), '');
$$;

create or replace function public.hfx_clin_004_normalizar_email(p_email text)
returns text
language sql
immutable
set search_path = ''
as $$
  select nullif(lower(btrim(coalesce(p_email, ''))), '');
$$;

do $$
declare
  v_duplicadas text;
begin
  select string_agg(cedula_normalizada, ', ')
    into v_duplicadas
    from (
      select public.hfx_clin_004_normalizar_cedula(cedula) as cedula_normalizada
        from public.personas
       where deleted_at is null
         and public.hfx_clin_004_normalizar_cedula(cedula) is not null
       group by 1
      having count(*) > 1
    ) d;

  if v_duplicadas is not null then
    raise exception
      'HFX-CLIN-004: hay cédulas repetidas entre personas vivas; deben unificarse antes de imponer la unicidad: %',
      v_duplicadas
      using errcode = 'CL017';
  end if;
end;
$$;

create unique index if not exists personas_cedula_normalizada_uk
  on public.personas (public.hfx_clin_004_normalizar_cedula(cedula))
  where deleted_at is null
    and public.hfx_clin_004_normalizar_cedula(cedula) is not null;

-- Control de versión de la ficha, para que dos ediciones simultáneas no se
-- pisen en silencio. Mismo contrato que `consultas.version` (HFX-CLIN-002).
alter table public.pacientes
  add column if not exists version integer not null default 1;

comment on column public.pacientes.version is
  'HFX-CLIN-004. Versión optimista de la ficha. La incrementa actualizar_paciente; un desajuste devuelve CL019.';

-- Los contactos de la ficha (principal y de emergencia) se reconcilian juntos:
-- el formulario los edita en bloque y partirlos en varias llamadas era una de
-- las vías por las que una edición se quedaba a medias.
--
-- El primero es el principal. Los que traen `id` se actualizan en su sitio; los
-- que no, se crean. No se borra ninguno: un teléfono retirado de la ficha sigue
-- siendo el que consta en visitas anteriores.
create or replace function public.hfx_clin_004_sincronizar_contactos(
  p_persona_id uuid,
  p_contactos jsonb
) returns void
language plpgsql
set search_path = public
as $$
declare
  v_contacto   jsonb;
  v_indice     integer := 0;
  v_telefono   text;
  v_id         uuid;
begin
  for v_contacto in
    select * from jsonb_array_elements(coalesce(p_contactos, '[]'::jsonb))
  loop
    v_telefono := public.hfx_clin_004_normalizar_telefono(
      v_contacto ->> 'numero_telefono'
    );
    v_id := nullif(v_contacto ->> 'id', '')::uuid;

    if v_telefono is null then
      v_indice := v_indice + 1;
      continue;
    end if;

    if v_id is not null and exists (
      select 1 from public.contactos where id = v_id
    ) then
      update public.contactos
         set numero_telefono = v_telefono,
             email = public.hfx_clin_004_normalizar_email(v_contacto ->> 'email'),
             direccion = nullif(btrim(coalesce(v_contacto ->> 'direccion', '')), ''),
             updated_at = now()
       where id = v_id;
    else
      insert into public.contactos (email, numero_telefono, direccion)
      values (
        public.hfx_clin_004_normalizar_email(v_contacto ->> 'email'),
        v_telefono,
        nullif(btrim(coalesce(v_contacto ->> 'direccion', '')), '')
      )
      returning id into v_id;

      insert into public.persona_contactos (
        persona_id, contacto_id, es_principal, es_emergencia
      )
      values (
        p_persona_id, v_id, v_indice = 0,
        coalesce((v_contacto ->> 'es_emergencia')::boolean, v_indice > 0)
      );
    end if;

    v_indice := v_indice + 1;
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- 7. Alta de paciente: una transacción o ninguna escritura
-- ---------------------------------------------------------------------------
-- Antes eran cinco llamadas encadenadas desde el cliente con un `rollback`
-- manual a mano en el `catch`. Una caída de red entre dos de ellas dejaba
-- persona o contacto huérfanos, invisibles para la aplicación y bloqueando la
-- cédula para siempre.
--
-- La foto se mantiene deliberadamente fuera: solo puede subirse cuando ya
-- existe un id confirmado, y su única ruta de escritura sigue siendo
-- `PacienteFotoStorage`.

create or replace function public.registrar_paciente(p_payload jsonb)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_persona_id  uuid;
  v_record_id   uuid;
  v_cedula      text;
  v_telefono    text;
  v_condicion   jsonb;
begin
  if not public.es_contexto_interno()
     and (auth.uid() is null
          or not (public.es_admin() or public.es_doctor() or public.es_asistente())) then
    raise exception 'Sesión activa requerida para registrar un paciente.'
      using errcode = '42501';
  end if;

  if nullif(btrim(coalesce(p_payload ->> 'nombre', '')), '') is null
     or nullif(btrim(coalesce(p_payload ->> 'apellido', '')), '') is null then
    raise exception 'El paciente necesita nombre y apellido.' using errcode = 'CL018';
  end if;

  if p_payload ->> 'fecha_nacimiento' is null then
    raise exception 'El paciente necesita fecha de nacimiento.' using errcode = 'CL018';
  end if;

  v_cedula := public.hfx_clin_004_normalizar_cedula(p_payload ->> 'cedula');
  v_telefono := public.hfx_clin_004_normalizar_telefono(
    p_payload #>> '{contactos,0,numero_telefono}'
  );
  if v_telefono is null then
    raise exception 'El paciente necesita al menos un teléfono de contacto.'
      using errcode = 'CL018';
  end if;

  if v_cedula is not null and exists (
    select 1 from public.personas
     where deleted_at is null
       and public.hfx_clin_004_normalizar_cedula(cedula) = v_cedula
  ) then
    raise exception 'Ya existe un registro con esa cédula.' using errcode = 'CL017';
  end if;

  insert into public.personas (nombre, apellido, fecha_nacimiento, cedula, estatus)
  values (
    btrim(p_payload ->> 'nombre'),
    btrim(p_payload ->> 'apellido'),
    (p_payload ->> 'fecha_nacimiento')::date,
    coalesce(btrim(p_payload ->> 'cedula'), ''),
    coalesce(nullif(p_payload ->> 'estatus', ''), 'activo')::public.estatus_persona
  )
  returning id into v_persona_id;

  perform public.hfx_clin_004_sincronizar_contactos(
    v_persona_id, p_payload -> 'contactos'
  );

  insert into public.pacientes (
    id, genero, tipo_paciente, trabajo, referencia, peso, altura,
    created_at, updated_at
  )
  values (
    v_persona_id,
    coalesce(nullif(p_payload ->> 'genero', ''), 'otro')::public.genero,
    coalesce(nullif(p_payload ->> 'tipo_paciente', ''), 'integrado')::public.tipo_paciente,
    coalesce(p_payload ->> 'trabajo', ''),
    coalesce(p_payload ->> 'referencia', ''),
    (p_payload ->> 'peso')::numeric,
    (p_payload ->> 'altura')::numeric,
    now(), now()
  );

  -- El expediente nace con el paciente: sin él, el asistente que registra al
  -- paciente no puede crearlo después (RLS de `records` es clínica) y la
  -- primera consulta se encontraba una ficha a medias.
  insert into public.records (
    paciente_id, tipo_sangre, cant_hijos, cirugias_previas, historial_familiar
  )
  values (
    v_persona_id,
    coalesce(nullif(p_payload #>> '{record,tipo_sangre}', ''), 'desconocido')::public.tipo_sangre,
    coalesce((p_payload #>> '{record,cant_hijos}')::integer, 0),
    coalesce(
      (select array_agg(value)
         from jsonb_array_elements_text(
           coalesce(p_payload #> '{record,cirugias_previas}', '[]'::jsonb)
         )),
      '{}'::text[]
    ),
    coalesce(p_payload #>> '{record,historial_familiar}', '')
  )
  returning id into v_record_id;

  for v_condicion in
    select * from jsonb_array_elements(coalesce(p_payload -> 'condiciones', '[]'::jsonb))
  loop
    insert into public.record_condicion (record_id, condicion_id, notas)
    values (
      v_record_id,
      (v_condicion ->> 'condicion_id')::uuid,
      nullif(btrim(coalesce(v_condicion ->> 'notas', '')), '')
    );
  end loop;

  return jsonb_build_object(
    'paciente_id', v_persona_id,
    'record_id', v_record_id,
    'version', 1
  );
end;
$$;

comment on function public.registrar_paciente(jsonb) is
  'HFX-CLIN-004. Alta completa del paciente en una transacción: persona, contacto principal, ficha, expediente y condiciones iniciales.';

-- ---------------------------------------------------------------------------
-- 8. Actualización de paciente con control de versión
-- ---------------------------------------------------------------------------

create or replace function public.actualizar_paciente(
  p_paciente_id uuid,
  p_version integer,
  p_payload jsonb
) returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_version_actual integer;
  v_cedula         text;
begin
  if not public.es_contexto_interno()
     and (auth.uid() is null
          or not (public.es_admin() or public.es_doctor() or public.es_asistente())) then
    raise exception 'Sesión activa requerida para editar un paciente.'
      using errcode = '42501';
  end if;

  select version into v_version_actual
    from public.pacientes
   where id = p_paciente_id and deleted_at is null
   for update;
  if not found then
    raise exception 'El paciente no existe o fue dado de baja.' using errcode = 'P0002';
  end if;

  if p_version is not null and p_version <> v_version_actual then
    raise exception
      'La ficha cambió mientras la editabas. Recárgala para no perder lo que guardó el otro actor.'
      using errcode = 'CL019';
  end if;

  v_cedula := public.hfx_clin_004_normalizar_cedula(p_payload ->> 'cedula');
  if v_cedula is not null and exists (
    select 1 from public.personas
     where deleted_at is null
       and id <> p_paciente_id
       and public.hfx_clin_004_normalizar_cedula(cedula) = v_cedula
  ) then
    raise exception 'Ya existe otro registro con esa cédula.' using errcode = 'CL017';
  end if;

  update public.personas
     set nombre = coalesce(nullif(btrim(coalesce(p_payload ->> 'nombre', '')), ''), nombre),
         apellido = coalesce(nullif(btrim(coalesce(p_payload ->> 'apellido', '')), ''), apellido),
         fecha_nacimiento = coalesce((p_payload ->> 'fecha_nacimiento')::date, fecha_nacimiento),
         cedula = coalesce(p_payload ->> 'cedula', cedula),
         estatus = coalesce(
           nullif(p_payload ->> 'estatus', '')::public.estatus_persona, estatus
         ),
         updated_at = now()
   where id = p_paciente_id;

  update public.pacientes
     set genero = coalesce(nullif(p_payload ->> 'genero', '')::public.genero, genero),
         tipo_paciente = coalesce(
           nullif(p_payload ->> 'tipo_paciente', '')::public.tipo_paciente, tipo_paciente
         ),
         trabajo = coalesce(p_payload ->> 'trabajo', trabajo),
         referencia = coalesce(p_payload ->> 'referencia', referencia),
         peso = coalesce((p_payload ->> 'peso')::numeric, peso),
         altura = coalesce((p_payload ->> 'altura')::numeric, altura),
         -- Las columnas `foto_*` no se tocan: su única ruta de escritura es
         -- `PacienteFotoStorage`, que las mantiene en sincronía con Storage.
         version = version + 1,
         updated_at = now()
   where id = p_paciente_id;

  if p_payload ? 'contactos' then
    perform public.hfx_clin_004_sincronizar_contactos(
      p_paciente_id, p_payload -> 'contactos'
    );
  end if;

  select version into v_version_actual
    from public.pacientes where id = p_paciente_id;

  return jsonb_build_object('paciente_id', p_paciente_id, 'version', v_version_actual);
end;
$$;

comment on function public.actualizar_paciente(uuid, integer, jsonb) is
  'HFX-CLIN-004. Actualización transaccional con versión optimista: o se aplica entera, o no queda ficha parcial.';

-- ---------------------------------------------------------------------------
-- 9. Emergencia / walk-in
-- ---------------------------------------------------------------------------
-- Hasta ahora atender a alguien que llegaba sin cita exigía inventar una cita
-- en el pasado o editar filas en Supabase. La urgencia pasa a ser una
-- operación con nombre, autor y evidencia: crea la cita marcada como
-- emergencia y la deja ya en espera, porque el paciente está presente.

create or replace function public.registrar_cita_emergencia(
  p_paciente_id uuid,
  p_doctor_id uuid default null,
  p_motivo text default null,
  p_duracion_minutos integer default 30
) returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_doctor_id uuid;
  v_cita_id   uuid;
begin
  if not public.es_contexto_interno()
     and (auth.uid() is null
          or not (public.es_admin() or public.es_doctor() or public.es_asistente())) then
    raise exception 'Sesión activa requerida para registrar una emergencia.'
      using errcode = '42501';
  end if;

  -- Sin doctor explícito, la emergencia es de quien la registra si ejerce.
  -- Un asistente tiene que decir a quién se la asigna: no puede firmar por
  -- nadie ni dejar la urgencia sin responsable.
  v_doctor_id := coalesce(p_doctor_id, auth.uid());
  if v_doctor_id is null then
    raise exception 'La emergencia necesita un doctor responsable.'
      using errcode = 'CL018';
  end if;
  if not exists (
    select 1 from public.doctores where id = v_doctor_id and deleted_at is null
  ) then
    raise exception 'El responsable indicado no es un doctor activo.'
      using errcode = 'CL018';
  end if;

  if not exists (
    select 1 from public.pacientes where id = p_paciente_id and deleted_at is null
  ) then
    raise exception 'El paciente de la emergencia no existe.' using errcode = 'P0002';
  end if;

  insert into public.citas (
    persona_id, doctor_id, fecha_hora, duracion_minutos,
    es_emergencia, estado, motivo, created_at, updated_at
  )
  values (
    p_paciente_id, v_doctor_id, now(), greatest(coalesce(p_duracion_minutos, 30), 1),
    true, 'en_espera',
    coalesce(nullif(btrim(coalesce(p_motivo, '')), ''), 'Emergencia'),
    now(), now()
  )
  returning id into v_cita_id;

  return jsonb_build_object(
    'cita_id', v_cita_id,
    'doctor_id', v_doctor_id,
    'paciente_id', p_paciente_id
  );
end;
$$;

comment on function public.registrar_cita_emergencia(uuid, uuid, text, integer) is
  'HFX-CLIN-004. Crea la cita de urgencia ya en espera y marcada como emergencia. Queda fuera de la restricción de solapamiento a propósito.';

-- ---------------------------------------------------------------------------
-- 10. Registrar la llegada del paciente
-- ---------------------------------------------------------------------------
-- El doctor que trabaja sin asistente dependía de recepción para que su propia
-- cita llegara a `en_espera`, y sin ese estado no podía iniciar la consulta.

create or replace function public.registrar_llegada_cita(p_cita_id uuid)
returns jsonb
language plpgsql security definer
set search_path = public
as $$
declare
  v_cita   public.citas%rowtype;
  v_estado text;
begin
  if not public.es_contexto_interno()
     and (auth.uid() is null
          or not (public.es_admin() or public.es_doctor() or public.es_asistente())) then
    raise exception 'Sesión activa requerida para registrar la llegada.'
      using errcode = '42501';
  end if;

  select * into v_cita
    from public.citas
   where id = p_cita_id and deleted_at is null
   for update;
  if not found then
    raise exception 'La cita ya no existe o fue eliminada.' using errcode = 'CL015';
  end if;

  -- Un doctor registra la llegada de sus pacientes; quien gestiona la agenda
  -- completa (admin y asistente) la de cualquiera.
  if not public.es_contexto_interno()
     and not (public.es_admin() or public.es_asistente())
     and v_cita.doctor_id is distinct from auth.uid() then
    raise exception 'No puede registrar la llegada de una cita ajena.'
      using errcode = '42501';
  end if;

  v_estado := public.hfx_clin_004_estado_cita_canonico(v_cita.estado::text);
  if v_estado = 'en_espera' then
    return jsonb_build_object('cita_id', p_cita_id, 'estado', 'en_espera',
                             'ya_registrada', true);
  end if;

  update public.citas
     set estado = 'en_espera', updated_at = now()
   where id = p_cita_id;

  return jsonb_build_object('cita_id', p_cita_id, 'estado', 'en_espera',
                           'ya_registrada', false);
end;
$$;

comment on function public.registrar_llegada_cita(uuid) is
  'HFX-CLIN-004. Idempotente. El doctor puede marcar la llegada de sus propias citas sin depender de recepción.';

-- ---------------------------------------------------------------------------
-- 11. Exposición: una por una, nunca por defecto
-- ---------------------------------------------------------------------------

revoke all on function public.iniciar_consulta_de_cita(
  uuid, jsonb, jsonb, jsonb, text, public.tipo_atencion_clinica
) from public, anon, authenticated;
revoke all on function public.registrar_paciente(jsonb) from public, anon, authenticated;
revoke all on function public.actualizar_paciente(uuid, integer, jsonb)
  from public, anon, authenticated;
revoke all on function public.registrar_cita_emergencia(uuid, uuid, text, integer)
  from public, anon, authenticated;
revoke all on function public.registrar_llegada_cita(uuid) from public, anon, authenticated;

grant execute on function public.iniciar_consulta_de_cita(
  uuid, jsonb, jsonb, jsonb, text, public.tipo_atencion_clinica
) to authenticated, service_role;
grant execute on function public.registrar_paciente(jsonb)
  to authenticated, service_role;
grant execute on function public.actualizar_paciente(uuid, integer, jsonb)
  to authenticated, service_role;
grant execute on function public.registrar_cita_emergencia(uuid, uuid, text, integer)
  to authenticated, service_role;
grant execute on function public.registrar_llegada_cita(uuid)
  to authenticated, service_role;

-- Las de normalización las usan los índices y las pruebas; no mutan nada.
grant execute on function public.hfx_clin_004_normalizar_cedula(text)
  to authenticated, service_role;
grant execute on function public.hfx_clin_004_normalizar_telefono(text)
  to authenticated, service_role;
grant execute on function public.hfx_clin_004_normalizar_email(text)
  to authenticated, service_role;
grant execute on function public.hfx_clin_004_estado_cita_canonico(text)
  to authenticated, service_role;

commit;
