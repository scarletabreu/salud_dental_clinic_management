-- HFX-QA-103 · Prueba de la matriz de permisos por rol.
--
--   psql -h 127.0.0.1 -p 54322 -U postgres -d postgres -v ON_ERROR_STOP=1 \
--        -f supabase/tests/hfx_qa_103_matriz_permisos_test.sql
--
-- NO ejecutar contra la instancia real: inserta datos.
--
-- Contrato que se verifica:
--   1. D8 · El doctor lee el catálogo pero no lo escribe; el admin sí.
--   2. D8 · Los `*_aplicados` siguen siendo del doctor: la regla es del
--      catálogo, no de lo clínico.
--   3. D11 · TEMPORAL: cualquier doctor lee cualquier consulta.
--   4. D12 · La asistente sólo ve las citas de los doctores que asiste.
--   5. D12 · La asistente cambia los estados administrativos y no los clínicos.
--   6. D12 · El doctor sólo lleva su propia cita a en_espera o cancelada.
--   7. D10 · El doctor inserta citas normales en su propia agenda.

begin;

set local role postgres;

do $$
declare
  v_admin       uuid := gen_random_uuid();
  v_doctor      uuid := gen_random_uuid();
  v_doctor_otro uuid := gen_random_uuid();
  v_asistente   uuid := gen_random_uuid();
  v_paciente    uuid := gen_random_uuid();
  v_tratamiento uuid;
  v_consulta    uuid;
  v_cita_propia uuid;
  v_cita_ajena  uuid;
  v_conteo      integer;
  v_fallo       boolean;
begin
  -- --------------------------------------------------------------- montaje
  insert into personas (id, nombre, apellido, fecha_nacimiento, cedula, created_at, updated_at)
  values (v_admin,       'Delia', 'Dirección', date '1975-01-01', 'QA103-AD', now(), now()),
         (v_doctor,      'Ada',   'Doctora',   date '1985-01-01', 'QA103-DO', now(), now()),
         (v_doctor_otro, 'Beto',  'Doctor',    date '1986-01-01', 'QA103-DB', now(), now()),
         (v_asistente,   'Clara', 'Recepción', date '1990-01-01', 'QA103-AS', now(), now()),
         (v_paciente,    'Zoila', 'Paciente',  date '1995-05-05', 'QA103-PA', now(), now());

  insert into usuarios (id, username, created_at, updated_at)
  values (v_admin, 'qa103_admin', now(), now()),
         (v_doctor, 'qa103_doctor', now(), now()),
         (v_doctor_otro, 'qa103_doctor_b', now(), now()),
         (v_asistente, 'qa103_asistente', now(), now());

  insert into doctores (id, especialidad, updated_at)
  values (v_admin, 'General', now()),
         (v_doctor, 'General', now()),
         (v_doctor_otro, 'General', now());
  insert into admins (id, departamento, updated_at)
  values (v_admin, 'Dirección', now());
  insert into asistentes (id, turno, updated_at)
  values (v_asistente, 'matutino', now());

  insert into pacientes (id, genero, created_at, updated_at)
  values (v_paciente, 'femenino', now(), now());

  -- La asistente asiste sólo a `v_doctor`.
  insert into doctor_asistentes (doctor_id, asistente_id)
  values (v_doctor, v_asistente);

  insert into tratamientos (nombre, costo, alcance, created_at, updated_at)
  values ('QA103 resina', 1500, 'puntual', now(), now())
  returning id into v_tratamiento;

  insert into consultas (paciente_id, doctor_id, fecha, motivo_consulta, created_at, updated_at)
  values (v_paciente, v_doctor, now(), 'Dolor', now(), now())
  returning id into v_consulta;

  insert into citas (persona_id, doctor_id, fecha_hora, duracion_minutos, estado, created_at, updated_at)
  values (v_paciente, v_doctor, now() + interval '1 day', 30, 'programada', now(), now())
  returning id into v_cita_propia;

  insert into citas (persona_id, doctor_id, fecha_hora, duracion_minutos, estado, created_at, updated_at)
  values (v_paciente, v_doctor_otro, now() + interval '2 day', 30, 'programada', now(), now())
  returning id into v_cita_ajena;

  -- --------------------------------- 1. D8 · catálogo de sólo lectura
  set local role authenticated;
  perform set_config('request.jwt.claims',
                     json_build_object('sub', v_doctor)::text, true);

  select count(*) into v_conteo from tratamientos where id = v_tratamiento;
  if v_conteo <> 1 then
    raise exception 'HFX-QA-103: el doctor no puede leer el catálogo (% filas).', v_conteo;
  end if;

  update tratamientos set costo = 9999 where id = v_tratamiento;
  if found then
    raise exception 'HFX-QA-103: el doctor cambió el precio de un tratamiento.';
  end if;

  delete from tratamientos where id = v_tratamiento;
  if found then
    raise exception 'HFX-QA-103: el doctor borró un tratamiento del catálogo.';
  end if;

  v_fallo := false;
  begin
    insert into tratamientos (nombre, costo, alcance, created_at, updated_at)
    values ('QA103 intruso', 1, 'puntual', now(), now());
  exception when insufficient_privilege or check_violation then v_fallo := true;
  end;
  if not v_fallo then
    raise exception 'HFX-QA-103: el doctor creó un tratamiento.';
  end if;
  raise notice 'OK 1 · D8: el doctor lee el catálogo y no lo escribe.';

  -- --------------------------- 2. lo clínico sigue siendo del doctor
  insert into diagnosticos_aplicados (diagnosis_id, severidad, fecha_aplicacion,
                                      notas, consulta_id, origen, created_at, updated_at)
  select d.id, 'moderada', now(), '', v_consulta, 'preexistente', now(), now()
    from diagnosticos d limit 1;
  raise notice 'OK 2 · D8: los *_aplicados siguen siendo del doctor.';

  -- ------------------------------- 3. D11 (TEMPORAL) · lectura abierta
  perform set_config('request.jwt.claims',
                     json_build_object('sub', v_doctor_otro)::text, true);
  select count(*) into v_conteo from consultas where id = v_consulta;
  if v_conteo <> 1 then
    raise exception
      'HFX-QA-103: D11 dice que cualquier doctor lee cualquier consulta (% filas).', v_conteo;
  end if;
  raise notice 'OK 3 · D11 (TEMPORAL): el doctor lee consultas ajenas.';

  -- ----------------------------- 4. D12 · alcance de la asistente
  perform set_config('request.jwt.claims',
                     json_build_object('sub', v_asistente)::text, true);

  select count(*) into v_conteo from citas where id = v_cita_propia;
  if v_conteo <> 1 then
    raise exception 'HFX-QA-103: la asistente no ve la cita del doctor que asiste.';
  end if;

  select count(*) into v_conteo from citas where id = v_cita_ajena;
  if v_conteo <> 0 then
    raise exception
      'HFX-QA-103: la asistente ve la cita de un doctor que NO asiste (% filas).', v_conteo;
  end if;
  raise notice 'OK 4 · D12: la asistente sólo ve la agenda de los doctores que asiste.';

  -- ------------------- 5. D12 · qué estados puede cambiar la asistente
  update citas set estado = 'confirmada' where id = v_cita_propia;
  if not found then
    raise exception 'HFX-QA-103: la asistente no pudo confirmar una cita suya.';
  end if;

  -- Se pasa por `en_espera` porque el grafo de estados (HFX-CLIN-004) no
  -- admite `confirmada → en_consulta`: así el intento siguiente lo rechaza la
  -- matriz de roles y no el grafo, que es lo que esta prueba mide.
  update citas set estado = 'en_espera' where id = v_cita_propia;

  v_fallo := false;
  begin
    update citas set estado = 'en_consulta' where id = v_cita_propia;
  exception when insufficient_privilege then v_fallo := true;
  end;
  if not v_fallo then
    raise exception
      'HFX-QA-103: la asistente puso una cita en_consulta; eso lo produce la RPC clínica.';
  end if;
  raise notice 'OK 5 · D12: la asistente cambia lo administrativo y no lo clínico.';

  -- ------------------------ 6. D12 · qué estados puede cambiar el doctor
  perform set_config('request.jwt.claims',
                     json_build_object('sub', v_doctor)::text, true);

  -- `no_asistio` sí es legal en el grafo desde `en_espera`; lo que lo rechaza
  -- aquí es la matriz de roles: marcar la inasistencia es administrativo.
  v_fallo := false;
  begin
    update citas set estado = 'no_asistio' where id = v_cita_propia;
  exception when insufficient_privilege then v_fallo := true;
  end;
  if not v_fallo then
    raise exception 'HFX-QA-103: el doctor marcó no_asistio; eso es administrativo.';
  end if;

  update citas set estado = 'cancelada' where id = v_cita_propia;
  if not found then
    raise exception 'HFX-QA-103: el doctor no pudo cancelar su propia cita.';
  end if;
  raise notice 'OK 6 · D12: el doctor sólo lleva su cita a en_espera o cancelada.';

  -- --------------------------- 7. D10 · el doctor agenda en su agenda
  insert into citas (persona_id, doctor_id, fecha_hora, duracion_minutos,
                     es_emergencia, estado, created_at, updated_at)
  values (v_paciente, v_doctor, now() + interval '3 day', 30, false,
          'programada', now(), now());

  v_fallo := false;
  begin
    insert into citas (persona_id, doctor_id, fecha_hora, duracion_minutos,
                       es_emergencia, estado, created_at, updated_at)
    values (v_paciente, v_doctor_otro, now() + interval '4 day', 30, false,
            'programada', now(), now());
  exception when insufficient_privilege or check_violation then v_fallo := true;
  end;
  if not v_fallo then
    raise exception 'HFX-QA-103: el doctor agendó en la agenda de otro doctor.';
  end if;
  raise notice 'OK 7 · D10: el doctor agenda citas normales, sólo en su agenda.';
end;
$$;

rollback;
