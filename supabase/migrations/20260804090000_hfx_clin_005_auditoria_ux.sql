-- HFX-CLIN-005 · Auditoría, UX, accesibilidad y rendimiento
--
-- Los tickets anteriores dejaron `auditoria_clinica` con tres eventos sueltos
-- —`consulta_iniciada`, `consulta_cerrada`, `alerta_resuelta`— escritos a mano
-- dentro de tres RPC. Todo lo demás que le ocurre a una consulta (un
-- diagnóstico que se retira, una receta que se anula, un plan que el paciente
-- acepta, una corrección administrativa) no dejaba rastro consultable, y lo
-- que ocurre *antes* de que exista la consulta —la llegada del paciente— no
-- tenía dónde anclarse porque `consulta_id` era obligatorio.
--
-- Esta migración convierte la auditoría en una línea de tiempo real:
--
--   * el evento puede colgar de una cita, de una consulta o de ambas;
--   * los eventos los escriben triggers sobre las tablas de destino, no las
--     RPC. Da igual si el cambio entró por `guardar_borrador_consulta`, por
--     una corrección administrativa o por REST directo: queda registrado;
--   * `linea_tiempo_consulta` devuelve la historia completa de una consulta
--     con actor, rol, fecha y motivo, resolviendo el nombre del actor sin
--     exponer cédula ni ningún otro dato de su ficha.
--
-- Sobre la autoría: el trigger toma `auth.uid()`, que sobrevive a
-- `SECURITY DEFINER` porque sale del JWT y no del rol de PostgreSQL. Cuando no
-- hay sesión —una migración, una prueba SQL, el service role— el evento se
-- registra con actor nulo y rol `sistema`. Es preferible a atribuirle el acto
-- a alguien: una auditoría que inventa autores no sirve como auditoría.

begin;

-- ---------------------------------------------------------------------------
-- 1. El evento deja de exigir consulta
-- ---------------------------------------------------------------------------
-- La llegada del paciente es el primer hecho clínico del día y ocurre cuando
-- todavía no hay consulta. Sin esto, el timeline empezaría por el medio.

alter table public.auditoria_clinica
  alter column consulta_id drop not null;

alter table public.auditoria_clinica
  add column if not exists cita_id uuid
    references public.citas(id) on delete cascade;

alter table public.auditoria_clinica
  drop constraint if exists auditoria_clinica_ancla;
alter table public.auditoria_clinica
  add constraint auditoria_clinica_ancla
  check (consulta_id is not null or cita_id is not null);

create index if not exists auditoria_clinica_cita_idx
  on public.auditoria_clinica (cita_id, created_at);

-- El índice de HFX-CLIN-002 ordena descendente; la línea de tiempo se lee en
-- orden cronológico y merece el suyo.
create index if not exists auditoria_clinica_consulta_cronologico_idx
  on public.auditoria_clinica (consulta_id, created_at);

comment on column public.auditoria_clinica.cita_id is
  'HFX-CLIN-005. Ancla del evento cuando ocurre antes de existir la consulta (creación de la cita, llegada, reprogramación).';

-- Ver los eventos de una cita es ver la agenda: mismas condiciones que
-- `citas_select`. Un doctor no descubre por el timeline las citas de otro.
drop policy if exists auditoria_clinica_select on public.auditoria_clinica;
create policy auditoria_clinica_select on public.auditoria_clinica
  for select to authenticated
  using (
    (consulta_id is not null and public.puede_ver_consulta(consulta_id))
    or (cita_id is not null and exists (
      select 1 from public.citas c
       where c.id = auditoria_clinica.cita_id
         and (
           public.es_admin()
           or public.es_asistente()
           or (public.es_doctor() and c.doctor_id = auth.uid())
         )
    ))
  );

-- ---------------------------------------------------------------------------
-- 1.bis La auditoría es de sólo lectura para el cliente
-- ---------------------------------------------------------------------------
-- Las tres tablas de auditoría heredaban el `grant all` que el esquema da a
-- `authenticated` y se apoyaban únicamente en RLS. Para INSERT/UPDATE/DELETE
-- eso basta —sin política, RLS los rechaza—, pero TRUNCATE no pasa por RLS:
-- cualquier sesión autenticada podía vaciar el historial clínico completo. Una
-- auditoría que el auditado puede borrar no es una auditoría.
--
-- Escribir sigue siendo posible sólo desde las RPC y los triggers, que son
-- `SECURITY DEFINER` y corren como el propietario.

revoke insert, update, delete, truncate
  on public.auditoria_clinica,
     public.auditoria_correcciones_clinicas,
     public.auditoria_operaciones_admin
  from authenticated, anon;

-- ---------------------------------------------------------------------------
-- 2. Un único punto de escritura
-- ---------------------------------------------------------------------------

create or replace function public.hfx_clin_005_registrar_evento(
  p_evento      text,
  p_consulta_id uuid,
  p_cita_id     uuid,
  p_metadata    jsonb default '{}'::jsonb
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_consulta_id is null and p_cita_id is null then
    return;
  end if;

  insert into public.auditoria_clinica (
    consulta_id, cita_id, evento, actor_id, rol, metadata
  )
  values (
    p_consulta_id,
    p_cita_id,
    p_evento,
    auth.uid(),
    case
      when auth.uid() is null then 'sistema'
      when public.es_admin() then 'admin'
      when public.es_doctor() then 'doctor'
      when public.es_asistente() then 'asistente'
      else 'desconocido'
    end,
    coalesce(p_metadata, '{}'::jsonb)
  );
end;
$$;

comment on function public.hfx_clin_005_registrar_evento(text, uuid, uuid, jsonb) is
  'HFX-CLIN-005. Escribe un evento de auditoría resolviendo actor y rol de la sesión. Sin sesión el rol es "sistema" y el actor queda nulo.';

revoke all on function public.hfx_clin_005_registrar_evento(text, uuid, uuid, jsonb) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3. Triggers de auditoría
-- ---------------------------------------------------------------------------
-- Escriben desde las tablas y no desde las RPC a propósito: el rastro no puede
-- depender de que la escritura haya entrado por el camino previsto.

-- 3.1 Consulta guardada -------------------------------------------------------
-- `version` sólo la incrementa `guardar_borrador_consulta`. El cierre lo firma
-- la RPC con `consulta_cerrada`; aquí se ignora para no duplicarlo.

create or replace function public.hfx_clin_005_auditar_consulta()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.version is distinct from old.version
     and coalesce(new.finalizada, false) = coalesce(old.finalizada, false)
  then
    perform public.hfx_clin_005_registrar_evento(
      'consulta_guardada', new.id, new.cita_id,
      jsonb_build_object('version', new.version)
    );
  end if;
  return null;
end;
$$;

drop trigger if exists hfx_clin_005_auditar_consulta on public.consultas;
create trigger hfx_clin_005_auditar_consulta
  after update on public.consultas
  for each row execute function public.hfx_clin_005_auditar_consulta();

-- 3.2 Cita: creación, llegada y cambios de estado -----------------------------

create or replace function public.hfx_clin_005_auditar_cita()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_evento text;
begin
  if tg_op = 'INSERT' then
    perform public.hfx_clin_005_registrar_evento(
      'cita_creada', null, new.id,
      jsonb_build_object(
        'estado', new.estado,
        'es_emergencia', coalesce(new.es_emergencia, false),
        'duracion_minutos', new.duracion_minutos
      )
    );
    return null;
  end if;

  if new.deleted_at is not null and old.deleted_at is null then
    perform public.hfx_clin_005_registrar_evento(
      'cita_eliminada', null, new.id, '{}'::jsonb
    );
    return null;
  end if;

  if new.estado is distinct from old.estado then
    v_evento := case new.estado::text
      when 'en_espera'   then 'cita_llegada'
      when 'en_consulta' then 'cita_en_consulta'
      when 'completada'  then 'cita_completada'
      when 'cancelada'   then 'cita_cancelada'
      when 'no_asistio'  then 'cita_no_asistio'
      when 'no_asistida' then 'cita_no_asistio'
      else 'cita_estado_cambiado'
    end;
    perform public.hfx_clin_005_registrar_evento(
      v_evento, null, new.id,
      jsonb_build_object('estado_previo', old.estado, 'estado', new.estado)
    );
  elsif new.fecha_hora is distinct from old.fecha_hora
     or new.doctor_id is distinct from old.doctor_id
  then
    perform public.hfx_clin_005_registrar_evento(
      'cita_reprogramada', null, new.id,
      jsonb_build_object(
        'fecha_hora_previa', old.fecha_hora,
        'fecha_hora', new.fecha_hora,
        'cambio_doctor', new.doctor_id is distinct from old.doctor_id
      )
    );
  end if;

  return null;
end;
$$;

drop trigger if exists hfx_clin_005_auditar_cita on public.citas;
create trigger hfx_clin_005_auditar_cita
  after insert or update on public.citas
  for each row execute function public.hfx_clin_005_auditar_cita();

-- 3.3 Diagnósticos ------------------------------------------------------------

create or replace function public.hfx_clin_005_auditar_diagnostico()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_nombre text;
begin
  select d.nombre into v_nombre
    from public.diagnosticos d where d.id = new.diagnosis_id;

  if tg_op = 'INSERT' then
    perform public.hfx_clin_005_registrar_evento(
      'diagnostico_agregado', new.consulta_id, null,
      jsonb_build_object(
        'diagnostico', v_nombre,
        'severidad', new.severidad,
        'diente_id', new.diente_id,
        'superficie', new.superficie
      )
    );
  elsif new.deleted_at is not null and old.deleted_at is null then
    perform public.hfx_clin_005_registrar_evento(
      'diagnostico_retirado', new.consulta_id, null,
      jsonb_build_object('diagnostico', v_nombre, 'diente_id', new.diente_id)
    );
  end if;
  return null;
end;
$$;

drop trigger if exists hfx_clin_005_auditar_diagnostico on public.diagnosticos_aplicados;
create trigger hfx_clin_005_auditar_diagnostico
  after insert or update on public.diagnosticos_aplicados
  for each row execute function public.hfx_clin_005_auditar_diagnostico();

-- 3.4 Tratamientos ejecutados -------------------------------------------------

create or replace function public.hfx_clin_005_auditar_tratamiento()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_nombre text;
begin
  select t.nombre into v_nombre
    from public.tratamientos t where t.id = new.tratamiento_id;

  if tg_op = 'INSERT' then
    perform public.hfx_clin_005_registrar_evento(
      'tratamiento_ejecutado', new.consulta_id, null,
      jsonb_build_object(
        'tratamiento', v_nombre,
        'estado', new.estado,
        'diente_id', new.diente_id,
        'superficie', new.superficie,
        'planificado', new.item_plan_id is not null
      )
    );
  elsif new.deleted_at is not null and old.deleted_at is null then
    perform public.hfx_clin_005_registrar_evento(
      'tratamiento_anulado', new.consulta_id, null,
      jsonb_build_object('tratamiento', v_nombre)
    );
  elsif new.estado is distinct from old.estado
     or new.esta_terminado is distinct from old.esta_terminado
  then
    perform public.hfx_clin_005_registrar_evento(
      'tratamiento_actualizado', new.consulta_id, null,
      jsonb_build_object(
        'tratamiento', v_nombre,
        'estado_previo', old.estado,
        'estado', new.estado
      )
    );
  end if;
  return null;
end;
$$;

drop trigger if exists hfx_clin_005_auditar_tratamiento on public.tratamientos_aplicados;
create trigger hfx_clin_005_auditar_tratamiento
  after insert or update on public.tratamientos_aplicados
  for each row execute function public.hfx_clin_005_auditar_tratamiento();

-- 3.5 Recetas -----------------------------------------------------------------
-- El borrador no genera evento: se reescribe en cada autoguardado y llenaría la
-- línea de tiempo de ruido. Lo que se audita es el acto médico: emitir, anular
-- o reemplazar.

create or replace function public.hfx_clin_005_auditar_receta()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_estado_previo text := case tg_op when 'INSERT' then null else old.estado end;
begin
  if new.estado is not distinct from v_estado_previo then
    return null;
  end if;

  if new.estado not in ('emitida', 'anulada', 'reemplazada') then
    return null;
  end if;

  perform public.hfx_clin_005_registrar_evento(
    'receta_' || new.estado, new.consulta_id, null,
    jsonb_build_object(
      'receta_id', new.id,
      'items', jsonb_array_length(coalesce(new.items_receta, '[]'::jsonb)),
      'motivo', new.motivo_anulacion,
      'reemplaza_a', new.receta_reemplazada_id
    )
  );
  return null;
end;
$$;

drop trigger if exists hfx_clin_005_auditar_receta on public.recetas;
create trigger hfx_clin_005_auditar_receta
  after insert or update on public.recetas
  for each row execute function public.hfx_clin_005_auditar_receta();

-- 3.6 Plan de tratamiento -----------------------------------------------------

create or replace function public.hfx_clin_005_auditar_plan()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_estado_previo text := case tg_op when 'INSERT' then null else old.estado::text end;
  v_evento text;
begin
  if new.estado::text is not distinct from v_estado_previo then
    return null;
  end if;

  v_evento := case new.estado::text
    when 'propuesto' then 'plan_propuesto'
    when 'aceptado'  then 'plan_aceptado'
    when 'rechazado' then 'plan_rechazado'
    else null
  end;
  if v_evento is null then
    return null;
  end if;

  perform public.hfx_clin_005_registrar_evento(
    v_evento, new.consulta_origen_id, null,
    jsonb_build_object(
      'plan_id', new.id,
      'version', new.version,
      'motivo', new.motivo_rechazo
    )
  );
  return null;
end;
$$;

drop trigger if exists hfx_clin_005_auditar_plan on public.planes_tratamiento;
create trigger hfx_clin_005_auditar_plan
  after insert or update on public.planes_tratamiento
  for each row execute function public.hfx_clin_005_auditar_plan();

-- 3.7 Consentimiento ----------------------------------------------------------

create or replace function public.hfx_clin_005_auditar_consentimiento()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_consulta uuid;
begin
  select p.consulta_origen_id into v_consulta
    from public.planes_tratamiento p where p.id = new.plan_id;

  perform public.hfx_clin_005_registrar_evento(
    'consentimiento_' || new.decision, v_consulta, null,
    jsonb_build_object(
      'plan_id', new.plan_id,
      'version_plan', new.version_plan,
      'metodo', new.metodo,
      'relacion_con_paciente', new.relacion_con_paciente,
      'total_aceptado', new.total_aceptado,
      'motivo', new.motivo_rechazo
    )
  );
  return null;
end;
$$;

drop trigger if exists hfx_clin_005_auditar_consentimiento on public.consentimientos_plan;
create trigger hfx_clin_005_auditar_consentimiento
  after insert on public.consentimientos_plan
  for each row execute function public.hfx_clin_005_auditar_consentimiento();

-- 3.8 Alerta clínica emitida --------------------------------------------------
-- La resolución ya la firma `resolver_alerta_clinica`; falta el momento en que
-- la regla saltó.

create or replace function public.hfx_clin_005_auditar_alerta()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.hfx_clin_005_registrar_evento(
    'alerta_emitida', new.consulta_id, null,
    jsonb_build_object(
      'alerta_id', new.id,
      'regla', new.regla_codigo,
      'severidad', new.severidad,
      'accion', new.accion
    )
  );
  return null;
end;
$$;

drop trigger if exists hfx_clin_005_auditar_alerta on public.alertas_clinicas;
create trigger hfx_clin_005_auditar_alerta
  after insert on public.alertas_clinicas
  for each row execute function public.hfx_clin_005_auditar_alerta();

-- 3.9 Corrección administrativa -----------------------------------------------
-- HFX-CLIN-001 ya la registra en su propia tabla; el timeline la necesita en la
-- misma línea que el resto para que se lea junto a lo que corrigió.

create or replace function public.hfx_clin_005_auditar_correccion()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.hfx_clin_005_registrar_evento(
    'correccion_administrativa', new.consulta_id, null,
    jsonb_build_object(
      'motivo', new.motivo,
      'autor_original_id', new.autor_original_id,
      'campos', (
        select coalesce(jsonb_agg(k order by k), '[]'::jsonb)
          from jsonb_object_keys(coalesce(new.datos_nuevos, '{}'::jsonb)) as k
      )
    )
  );
  return null;
end;
$$;

drop trigger if exists hfx_clin_005_auditar_correccion on public.auditoria_correcciones_clinicas;
create trigger hfx_clin_005_auditar_correccion
  after insert on public.auditoria_correcciones_clinicas
  for each row execute function public.hfx_clin_005_auditar_correccion();

-- ---------------------------------------------------------------------------
-- 4. La línea de tiempo
-- ---------------------------------------------------------------------------
-- Devuelve los eventos de la consulta y los de su cita en una sola lectura
-- cronológica. Resuelve el nombre del actor —un timeline con UUID no lo lee
-- nadie— y nada más de su ficha: ni cédula, ni teléfono, ni correo.

create or replace function public.linea_tiempo_consulta(p_consulta_id uuid)
returns table (
  id           uuid,
  evento       text,
  categoria    text,
  ocurrido_en  timestamptz,
  actor_id     uuid,
  actor_nombre text,
  rol          text,
  motivo       text,
  metadata     jsonb
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_cita_id uuid;
begin
  if not public.es_contexto_interno()
     and not public.puede_ver_consulta(p_consulta_id) then
    raise exception 'CL020: la consulta no existe o no es visible para este usuario'
      using errcode = 'check_violation';
  end if;

  select c.cita_id into v_cita_id
    from public.consultas c where c.id = p_consulta_id;

  return query
  select a.id,
         a.evento,
         case
           when a.evento like 'cita_%' then 'agenda'
           when a.evento like 'plan_%'
             or a.evento like 'consentimiento_%' then 'plan'
           when a.evento like 'receta_%' then 'receta'
           when a.evento like 'alerta_%' then 'alerta'
           when a.evento like 'correccion_%' then 'correccion'
           else 'clinico'
         end as categoria,
         a.created_at,
         a.actor_id,
         nullif(btrim(coalesce(p.nombre, '') || ' ' || coalesce(p.apellido, '')), ''),
         a.rol,
         nullif(btrim(coalesce(a.metadata ->> 'motivo', '')), ''),
         a.metadata
    from public.auditoria_clinica a
    left join public.personas p on p.id = a.actor_id
   where a.consulta_id = p_consulta_id
      or (v_cita_id is not null and a.cita_id = v_cita_id)
   order by a.created_at, a.id;
end;
$$;

comment on function public.linea_tiempo_consulta(uuid) is
  'HFX-CLIN-005. Historia cronológica de una consulta y de su cita, con actor, rol, fecha y motivo. Comprueba visibilidad antes de devolver nada.';

revoke all on function public.linea_tiempo_consulta(uuid) from public, anon;
grant execute on function public.linea_tiempo_consulta(uuid) to authenticated, service_role;

commit;
