-- SD-146 · Prueba del vínculo cita ↔ actividades planificadas.
--
-- Se ejecuta sobre una base con `schema.sql` + la migración
-- 20260730150000_sd_146_citas_actividades_planificadas.sql aplicados. Todo
-- ocurre dentro de una transacción que termina en ROLLBACK: no deja rastro.
--
--   psql -h 127.0.0.1 -p 54322 -U postgres -d <base> -v ON_ERROR_STOP=1 \
--        -f supabase/tests/sd_146_cita_actividades_test.sql
--
-- NO ejecutar contra la instancia real: inserta datos y el ROLLBACK no está
-- garantizado por la Management API.
--
-- Contrato que se verifica:
--   1. Una cita puede vincular varias actividades del plan de su paciente.
--   2. La actividad de OTRO paciente se rechaza (no se cruzan expedientes).
--   3. Una actividad retirada del plan (`deleted_at`) no se puede agendar.
--   4. Una actividad rechazada, cancelada o completada tampoco.
--   5. `resumen_actividades_cita` devuelve el nombre del tratamiento y la pieza.
--   6. `actividades_agendables_paciente` ofrece lo agendable y nada más.
--   7. El asistente (quien agenda) puede leer las vistas y gestionar vínculos.
--   8. Borrar la cita se lleva sus vínculos.

begin;

set local role postgres;

do $$
declare
  v_doctor_id      uuid := gen_random_uuid();
  v_paciente_a     uuid := gen_random_uuid();
  v_paciente_b     uuid := gen_random_uuid();
  v_asistente_id   uuid := gen_random_uuid();
  v_consulta_id    uuid;
  v_odontograma_id uuid;
  v_diente_id      uuid;
  v_tratamiento_id uuid;
  v_plan_a         uuid;
  v_plan_b         uuid;
  v_item_a1        uuid;
  v_item_a2        uuid;
  v_item_rechazado uuid;
  v_item_retirado  uuid;
  v_item_b         uuid;
  v_cita_id        uuid;
  v_conteo         integer;
  v_nombre         text;
  v_fdi            integer;
  v_fallo          boolean;
begin
  -- ---------------------------------------------------------------- montaje
  insert into personas (id, nombre, apellido, fecha_nacimiento, cedula, created_at, updated_at)
  values (v_doctor_id, 'Ana', 'Doctora SD146', date '1985-01-01', 'SD146-DOC', now(), now());
  insert into usuarios (id, username, created_at, updated_at)
  values (v_doctor_id, 'sd146_doctor', now(), now());
  insert into doctores (id, especialidad, updated_at)
  values (v_doctor_id, 'General', now());

  -- Las vistas de resumen llevan dentro la comprobación de rol de
  -- `citas_select` (`es_admin() or es_doctor() or es_asistente()`), que se
  -- resuelve con `auth.uid()`. Sin identidad devuelven cero filas —también para
  -- `postgres`—, así que la prueba se hace pasar por el doctor recién creado.
  perform set_config('request.jwt.claims',
                     json_build_object('sub', v_doctor_id)::text, true);

  insert into personas (id, nombre, apellido, fecha_nacimiento, cedula, created_at, updated_at)
  values (v_paciente_a, 'Luis', 'Paciente A', date '1995-05-05', 'SD146-PAC-A', now(), now());
  insert into pacientes (id, genero, created_at, updated_at)
  values (v_paciente_a, 'masculino', now(), now());

  insert into personas (id, nombre, apellido, fecha_nacimiento, cedula, created_at, updated_at)
  values (v_paciente_b, 'Rosa', 'Paciente B', date '1992-02-02', 'SD146-PAC-B', now(), now());
  insert into pacientes (id, genero, created_at, updated_at)
  values (v_paciente_b, 'femenino', now(), now());

  insert into consultas (paciente_id, doctor_id, fecha, motivo_consulta, created_at, updated_at)
  values (v_paciente_a, v_doctor_id, now(), 'Dolor molar', now(), now())
  returning id into v_consulta_id;

  insert into odontogramas (consulta_id, created_at, updated_at)
  values (v_consulta_id, now(), now()) returning id into v_odontograma_id;

  insert into dientes (odontograma_id, fdi_code, created_at, updated_at)
  values (v_odontograma_id, 36, now(), now()) returning id into v_diente_id;

  insert into tratamientos (nombre, costo, alcance, created_at, updated_at)
  values ('Resina SD146', 2500.00, 'puntual', now(), now())
  returning id into v_tratamiento_id;

  insert into planes_tratamiento (paciente_id, doctor_id, estado, fecha_propuesta)
  values (v_paciente_a, v_doctor_id, 'propuesto', now()) returning id into v_plan_a;

  insert into planes_tratamiento (paciente_id, doctor_id, estado, fecha_propuesta)
  values (v_paciente_b, v_doctor_id, 'propuesto', now()) returning id into v_plan_b;

  insert into items_plan_tratamiento (plan_id, tratamiento_id, diente_id, superficie,
    estado, precio_estimado, orden, doctor_propone_id, fecha_propuesta)
  values (v_plan_a, v_tratamiento_id, v_diente_id, 'oclusal', 'aceptado', 2500, 1,
          v_doctor_id, now())
  returning id into v_item_a1;

  insert into items_plan_tratamiento (plan_id, tratamiento_id, estado, precio_estimado,
    orden, doctor_propone_id, fecha_propuesta)
  values (v_plan_a, v_tratamiento_id, 'propuesto', 1800, 2, v_doctor_id, now())
  returning id into v_item_a2;

  insert into items_plan_tratamiento (plan_id, tratamiento_id, estado, precio_estimado,
    orden, doctor_propone_id, fecha_propuesta, fecha_rechazo, motivo_rechazo)
  values (v_plan_a, v_tratamiento_id, 'rechazado', 1000, 3, v_doctor_id, now(), now(), 'Costo')
  returning id into v_item_rechazado;

  insert into items_plan_tratamiento (plan_id, tratamiento_id, estado, precio_estimado,
    orden, doctor_propone_id, fecha_propuesta, deleted_at)
  values (v_plan_a, v_tratamiento_id, 'aceptado', 900, 4, v_doctor_id, now(), now())
  returning id into v_item_retirado;

  insert into items_plan_tratamiento (plan_id, tratamiento_id, estado, precio_estimado,
    orden, doctor_propone_id, fecha_propuesta)
  values (v_plan_b, v_tratamiento_id, 'aceptado', 3000, 1, v_doctor_id, now())
  returning id into v_item_b;

  insert into citas (persona_id, doctor_id, fecha_hora, duracion_minutos, es_emergencia,
    estado, created_at, updated_at)
  values (v_paciente_a, v_doctor_id, now() + interval '1 day', 45, false, 'programada',
          now(), now())
  returning id into v_cita_id;

  -- --------------------------------------------- 1. varias actividades por cita
  insert into citas_items_plan (cita_id, item_plan_id)
  values (v_cita_id, v_item_a1), (v_cita_id, v_item_a2);

  select count(*) into v_conteo from citas_items_plan where cita_id = v_cita_id;
  if v_conteo <> 2 then
    raise exception 'Se esperaban 2 vínculos en la cita, hay %.', v_conteo;
  end if;
  raise notice 'OK 1 · una cita vincula varias actividades de su paciente.';

  -- ----------------------------------------------- 2. actividad de otro paciente
  v_fallo := false;
  begin
    insert into citas_items_plan (cita_id, item_plan_id) values (v_cita_id, v_item_b);
  exception when others then
    v_fallo := true;
  end;
  if not v_fallo then
    raise exception 'Se vinculó la actividad de otro paciente. El trigger debe rechazarla.';
  end if;
  raise notice 'OK 2 · la actividad de otro paciente se rechaza.';

  -- ------------------------------------------------- 3. actividad retirada
  v_fallo := false;
  begin
    insert into citas_items_plan (cita_id, item_plan_id) values (v_cita_id, v_item_retirado);
  exception when others then
    v_fallo := true;
  end;
  if not v_fallo then
    raise exception 'Se agendó una actividad retirada del plan.';
  end if;
  raise notice 'OK 3 · una actividad retirada del plan no se puede agendar.';

  -- ------------------------------------------------- 4. actividad rechazada
  v_fallo := false;
  begin
    insert into citas_items_plan (cita_id, item_plan_id) values (v_cita_id, v_item_rechazado);
  exception when others then
    v_fallo := true;
  end;
  if not v_fallo then
    raise exception 'Se agendó una actividad rechazada.';
  end if;
  raise notice 'OK 4 · una actividad rechazada no se puede agendar.';

  -- --------------------------------------- 5. la vista trae nombre y pieza
  select tratamiento_nombre, fdi_diente into v_nombre, v_fdi
  from resumen_actividades_cita
  where cita_id = v_cita_id and item_plan_id = v_item_a1;

  if v_nombre is distinct from 'Resina SD146' then
    raise exception 'resumen_actividades_cita no trae el nombre del tratamiento (dio %).', v_nombre;
  end if;
  if v_fdi is distinct from 36 then
    raise exception 'resumen_actividades_cita no trae la pieza FDI (dio %).', v_fdi;
  end if;

  select count(*) into v_conteo from resumen_actividades_cita where cita_id = v_cita_id;
  if v_conteo <> 2 then
    raise exception 'La vista devolvió % filas para la cita, se esperaban 2.', v_conteo;
  end if;
  raise notice 'OK 5 · resumen_actividades_cita devuelve el resumen completo.';

  -- ------------------------------ 6. lo agendable del paciente y nada más
  select count(*) into v_conteo
  from actividades_agendables_paciente where paciente_id = v_paciente_a;
  if v_conteo <> 2 then
    raise exception 'actividades_agendables_paciente devolvió % filas, se esperaban 2 '
      '(la rechazada y la retirada no cuentan).', v_conteo;
  end if;
  raise notice 'OK 6 · actividades_agendables_paciente excluye lo rechazado y lo retirado.';

  -- ----------------------- 7. el asistente, que es quien agenda, puede hacerlo
  --
  -- Es la razón de ser de las vistas: `items_plan_tratamiento` y `tratamientos`
  -- son admin-or-doctor, así que sin ellas el asistente no vería nada que elegir.
  insert into personas (id, nombre, apellido, fecha_nacimiento, cedula, created_at, updated_at)
  values (v_asistente_id, 'Elsa', 'Asistente SD146', date '1993-03-03', 'SD146-ASI',
          now(), now());
  insert into usuarios (id, username, created_at, updated_at)
  values (v_asistente_id, 'sd146_asistente', now(), now());
  insert into asistentes (id, turno, updated_at)
  values (v_asistente_id, 'matutino', now());

  perform set_config('request.jwt.claims',
                     json_build_object('sub', v_asistente_id)::text, true);
  set local role authenticated;

  select count(*) into v_conteo
  from actividades_agendables_paciente where paciente_id = v_paciente_a;
  if v_conteo <> 2 then
    raise exception 'El asistente vio % actividades agendables, se esperaban 2.', v_conteo;
  end if;

  select count(*) into v_conteo from resumen_actividades_cita where cita_id = v_cita_id;
  if v_conteo <> 2 then
    raise exception 'El asistente vio % filas de resumen, se esperaban 2.', v_conteo;
  end if;

  -- Y puede desvincular y volver a vincular: gestionar la agenda es su trabajo.
  delete from citas_items_plan
   where cita_id = v_cita_id and item_plan_id = v_item_a2;
  insert into citas_items_plan (cita_id, item_plan_id) values (v_cita_id, v_item_a2);

  reset role;
  perform set_config('request.jwt.claims',
                     json_build_object('sub', v_doctor_id)::text, true);
  raise notice 'OK 7 · el asistente puede leer el resumen y gestionar los vínculos.';

  -- ------------------------------------------ 8. el borrado arrastra el vínculo
  delete from citas where id = v_cita_id;
  select count(*) into v_conteo from citas_items_plan where cita_id = v_cita_id;
  if v_conteo <> 0 then
    raise exception 'Borrar la cita dejó % vínculo(s) huérfano(s).', v_conteo;
  end if;
  raise notice 'OK 8 · borrar la cita se lleva sus vínculos.';
end;
$$;

rollback;
