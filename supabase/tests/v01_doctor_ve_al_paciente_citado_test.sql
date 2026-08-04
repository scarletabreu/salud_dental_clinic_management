-- V-01 · Un doctor ve a los pacientes que tiene citados.
--
-- Fija la regla que desbloquea la primera consulta: sin cita el doctor no ve al
-- paciente; con una cita viva a su nombre sí, y por eso puede abrir el
-- expediente y atender. Antes de esta regla la pantalla de consulta quedaba en
-- un indicador de carga permanente, sin salida.
--
-- Se ejecuta tras `supabase db reset` y revierte todos sus datos.
--
--   psql "$DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/v01_doctor_ve_al_paciente_citado_test.sql

begin;
set local role postgres;

-- ---------------------------------------------------------------------------
-- 0 · Escenario: dos doctoras y un paciente al que ninguna ha atendido nunca.
-- ---------------------------------------------------------------------------
do $$
declare
  v_doc_citada uuid := '5a000000-0000-4000-8000-000000000001';
  v_doc_ajena  uuid := '5a000000-0000-4000-8000-000000000002';
  v_paciente   uuid := '5a000000-0000-4000-8000-000000000010';
begin
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    created_at, updated_at, raw_user_meta_data
  ) values
  (v_doc_citada, '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'v01-citada@test.local', 'x', now(), now(),
   '{"rol":"doctor","nombre":"Dalia","apellido":"Citada","fecha_nacimiento":"1980-01-01","cedula":"V01-DC","username":"v01_dc","especialidad":"General"}'),
  (v_doc_ajena, '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'v01-ajena@test.local', 'x', now(), now(),
   '{"rol":"doctor","nombre":"Elsa","apellido":"Ajena","fecha_nacimiento":"1981-01-01","cedula":"V01-DA","username":"v01_da","especialidad":"General"}');

  insert into public.personas (id, nombre, apellido, fecha_nacimiento, cedula)
  values (v_paciente, 'Nuevo', 'Paciente', date '1992-05-05', '00500000001');
  insert into public.pacientes (id, genero) values (v_paciente, 'femenino');

  perform set_config('v01.doc_citada', v_doc_citada::text, true);
  perform set_config('v01.doc_ajena', v_doc_ajena::text, true);
  perform set_config('v01.paciente', v_paciente::text, true);
end;
$$;

-- ---------------------------------------------------------------------------
-- 1 · Sin cita, el doctor no ve al paciente. La regla sigue cerrada.
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('v01.doc_citada'), 'role', 'authenticated')::text,
  true
);

do $$
begin
  if public.puede_ver_paciente(current_setting('v01.paciente')::uuid) then
    raise exception
      'FALLO: un doctor sin cita ni asignación ve al paciente; la regla quedó abierta de más';
  end if;
  raise notice 'OK 1 · sin cita ni asignación el doctor no ve al paciente';
end;
$$;

-- ---------------------------------------------------------------------------
-- 2 · Con una cita a su nombre, el doctor sí lo ve y `pacientes` lo devuelve.
-- ---------------------------------------------------------------------------
set local role postgres;
do $$
declare
  v_cita uuid;
begin
  insert into public.citas (persona_id, doctor_id, fecha_hora, duracion_minutos)
  values (
    current_setting('v01.paciente')::uuid,
    current_setting('v01.doc_citada')::uuid,
    date_trunc('hour', now()) + interval '1 day',
    30
  ) returning id into v_cita;
  perform set_config('v01.cita', v_cita::text, true);
end;
$$;

set local role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('v01.doc_citada'), 'role', 'authenticated')::text,
  true
);

do $$
declare
  v_paciente uuid := current_setting('v01.paciente')::uuid;
begin
  if not public.puede_ver_paciente(v_paciente) then
    raise exception 'FALLO: el doctor citado sigue sin ver a su paciente';
  end if;

  -- La comprobación que importa de verdad: es la RLS de `pacientes` la que
  -- decidía el bloqueo, y es la consulta exacta que hace el cliente antes de
  -- abrir la consulta (`esPersonaSinFichaClinica`).
  if not exists (select 1 from public.pacientes where id = v_paciente) then
    raise exception
      'FALLO: `pacientes` sigue vacía para el doctor citado; la pantalla de consulta seguiría en blanco';
  end if;

  raise notice 'OK 2 · con la cita, el doctor ve al paciente y `pacientes` lo devuelve';
end;
$$;

-- ---------------------------------------------------------------------------
-- 3 · La cita de una doctora no le abre el paciente a otra.
-- ---------------------------------------------------------------------------
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('v01.doc_ajena'), 'role', 'authenticated')::text,
  true
);

do $$
declare
  v_paciente uuid := current_setting('v01.paciente')::uuid;
begin
  if public.puede_ver_paciente(v_paciente) then
    raise exception
      'FALLO: la cita de una doctora le abre el paciente a otra; el alcance por doctor se perdió';
  end if;
  if exists (select 1 from public.pacientes where id = v_paciente) then
    raise exception 'FALLO: `pacientes` devuelve al paciente de una cita ajena';
  end if;
  raise notice 'OK 3 · la cita ajena no da acceso';
end;
$$;

-- ---------------------------------------------------------------------------
-- 4 · Una cita borrada deja de dar acceso.
-- ---------------------------------------------------------------------------
set local role postgres;
update public.citas
   set deleted_at = now()
 where id = current_setting('v01.cita')::uuid;

set local role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('v01.doc_citada'), 'role', 'authenticated')::text,
  true
);

do $$
begin
  if public.puede_ver_paciente(current_setting('v01.paciente')::uuid) then
    raise exception 'FALLO: una cita borrada sigue dando acceso al paciente';
  end if;
  raise notice 'OK 4 · la cita borrada retira el acceso';
end;
$$;

rollback;
