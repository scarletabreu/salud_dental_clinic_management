-- SD-169 · Prueba funcional del trigger que cancela las citas de un paciente
-- inactivo (`tr_paciente_inactivo_cancela_citas`).
--
-- Se ejecuta sobre una base con `schema.sql` + la migración
-- 20260730120000_sd_169_reparar_trigger_paciente_inactivo.sql aplicados (y la
-- de SD-160, que aporta el trigger de cancelación bloqueada). Todo ocurre
-- dentro de una transacción que termina en ROLLBACK: no deja rastro.
--
--   psql -h 127.0.0.1 -p 54322 -U postgres -d <base> -v ON_ERROR_STOP=1 \
--        -f supabase/tests/sd_169_paciente_inactivo_test.sql
--
-- Cubre el camino completo, que hasta SD-169 no tenía ninguna prueba: por eso
-- el defecto sobrevivió al renombrado del enum de SD-81.
--
--   1. Desactivar un paciente sin citas futuras no falla.
--   2. Sus citas futuras vivas (programada, confirmada, en_espera) quedan
--      canceladas.
--   3. La cita cuya consulta sigue abierta NO se cancela y NO hace fallar la
--      desactivación (regla de SD-160).
--   4. `en_consulta`, los estados terminales, las citas pasadas y las de otros
--      pacientes quedan intactos.
--   5. Reactivar al paciente no toca ninguna cita.
--   6. Un update que reenvía `estatus` sin cambiarlo (lo que hace la app en
--      cada edición de persona) no vuelve a barrer la agenda.

begin;

set local role postgres;

do $$
declare
  v_doctor_id      uuid := gen_random_uuid();
  v_paciente_id    uuid := gen_random_uuid();
  v_otro_pac_id    uuid := gen_random_uuid();
  v_cita_prog      uuid;
  v_cita_conf      uuid;
  v_cita_espera    uuid;
  v_cita_consulta  uuid;  -- en_consulta ahora mismo
  v_cita_abierta   uuid;  -- futura, pero con consulta abierta
  v_cita_pasada    uuid;
  v_cita_completa  uuid;
  v_cita_otro      uuid;
  v_estado         text;
  v_conteo         integer;
begin
  -- ---------------------------------------------------------------- montaje
  -- `usuarios` cuelga de `personas`, y `doctores` de `usuarios`.
  insert into personas (id, nombre, apellido, fecha_nacimiento, cedula, created_at, updated_at)
  values (v_doctor_id, 'Ana', 'Prueba', date '1990-01-01', 'SD169-DOC', now(), now());
  insert into usuarios (id, username, created_at, updated_at)
  values (v_doctor_id, 'sd169_doctor', now(), now());
  insert into doctores (id, especialidad, updated_at)
  values (v_doctor_id, 'General', now());

  insert into personas (id, nombre, apellido, fecha_nacimiento, cedula, created_at, updated_at)
  values (v_paciente_id, 'Luis', 'Paciente', date '1995-05-05', 'SD169-PAC', now(), now());
  insert into pacientes (id, genero, created_at, updated_at)
  values (v_paciente_id, 'masculino', now(), now());

  insert into personas (id, nombre, apellido, fecha_nacimiento, cedula, created_at, updated_at)
  values (v_otro_pac_id, 'Rosa', 'Ajena', date '1988-03-03', 'SD169-OTRO', now(), now());
  insert into pacientes (id, genero, created_at, updated_at)
  values (v_otro_pac_id, 'femenino', now(), now());

  -- ------------------------------------------- 1. sin citas: no debe fallar
  update personas set estatus = 'inactivo' where id = v_paciente_id;

  -- Se devuelve a activo para montar el escenario real.
  update personas set estatus = 'activo' where id = v_paciente_id;

  -- ------------------------------------------------------------- escenario
  insert into citas (persona_id, doctor_id, fecha_hora, estado, created_at)
  values (v_paciente_id, v_doctor_id, now() + interval '3 days', 'programada', now())
  returning id into v_cita_prog;

  insert into citas (persona_id, doctor_id, fecha_hora, estado, created_at)
  values (v_paciente_id, v_doctor_id, now() + interval '5 days', 'confirmada', now())
  returning id into v_cita_conf;

  insert into citas (persona_id, doctor_id, fecha_hora, estado, created_at)
  values (v_paciente_id, v_doctor_id, now() + interval '2 hours', 'en_espera', now())
  returning id into v_cita_espera;

  -- El paciente está siendo atendido ahora mismo: un cambio administrativo no
  -- puede cerrarle la cita por debajo.
  insert into citas (persona_id, doctor_id, fecha_hora, estado, created_at)
  values (v_paciente_id, v_doctor_id, now() + interval '1 hour', 'en_consulta', now())
  returning id into v_cita_consulta;

  -- Cita futura, viva, pero con una consulta abierta colgando: es la que
  -- haría saltar tr_bloquear_cancelacion_con_consulta_abierta (SD-160).
  insert into citas (persona_id, doctor_id, fecha_hora, estado, created_at)
  values (v_paciente_id, v_doctor_id, now() + interval '4 days', 'programada', now())
  returning id into v_cita_abierta;

  insert into consultas (paciente_id, doctor_id, cita_id, fecha, motivo_consulta, finalizada, created_at, updated_at)
  values (v_paciente_id, v_doctor_id, v_cita_abierta, now(), 'Endodoncia en curso', false, now(), now());

  -- Cita pasada todavía en programada: es historia de agenda, no la reescribe
  -- una baja administrativa.
  insert into citas (persona_id, doctor_id, fecha_hora, estado, created_at)
  values (v_paciente_id, v_doctor_id, now() - interval '2 days', 'programada', now())
  returning id into v_cita_pasada;

  -- Estado terminal: intocable.
  insert into citas (persona_id, doctor_id, fecha_hora, estado, created_at)
  values (v_paciente_id, v_doctor_id, now() + interval '6 days', 'completada', now())
  returning id into v_cita_completa;

  -- Cita de OTRO paciente en la misma agenda.
  insert into citas (persona_id, doctor_id, fecha_hora, estado, created_at)
  values (v_otro_pac_id, v_doctor_id, now() + interval '3 days', 'programada', now())
  returning id into v_cita_otro;

  -- ------------------------------------------------ 2..4 la desactivación
  -- Si el trigger vuelve a apuntar a una columna inexistente o choca contra la
  -- regla de SD-160, este único update aborta y la prueba muere aquí.
  update personas set estatus = 'inactivo' where id = v_paciente_id;

  select estado::text into v_estado from citas where id = v_cita_prog;
  if v_estado <> 'cancelada' then
    raise exception 'La cita programada quedó en %, se esperaba cancelada.', v_estado;
  end if;

  select estado::text into v_estado from citas where id = v_cita_conf;
  if v_estado <> 'cancelada' then
    raise exception 'La cita confirmada quedó en %, se esperaba cancelada.', v_estado;
  end if;

  select estado::text into v_estado from citas where id = v_cita_espera;
  if v_estado <> 'cancelada' then
    raise exception 'La cita en_espera quedó en %, se esperaba cancelada.', v_estado;
  end if;

  select estado::text into v_estado from citas where id = v_cita_consulta;
  if v_estado <> 'en_consulta' then
    raise exception 'Se canceló una cita en_consulta (quedó en %).', v_estado;
  end if;

  select estado::text into v_estado from citas where id = v_cita_abierta;
  if v_estado <> 'programada' then
    raise exception
      'La cita con consulta abierta quedó en %; debía seguir viva para que la cierre el flujo clínico.',
      v_estado;
  end if;

  select estado::text into v_estado from citas where id = v_cita_pasada;
  if v_estado <> 'programada' then
    raise exception 'Se canceló una cita pasada (quedó en %).', v_estado;
  end if;

  select estado::text into v_estado from citas where id = v_cita_completa;
  if v_estado <> 'completada' then
    raise exception 'Se tocó una cita en estado terminal (quedó en %).', v_estado;
  end if;

  select estado::text into v_estado from citas where id = v_cita_otro;
  if v_estado <> 'programada' then
    raise exception 'Se cancelaron citas de otro paciente (quedó en %).', v_estado;
  end if;

  -- `updated_at` deja rastro del cambio automático.
  select count(*) into v_conteo
  from citas
  where id in (v_cita_prog, v_cita_conf, v_cita_espera) and updated_at is not null;
  if v_conteo <> 3 then
    raise exception 'La cancelación automática no selló updated_at en las 3 citas (solo %).', v_conteo;
  end if;

  -- ----------------------------------------------- 5. reactivar no cancela
  update citas set estado = 'programada', updated_at = now() where id = v_cita_prog;
  update personas set estatus = 'activo' where id = v_paciente_id;

  select estado::text into v_estado from citas where id = v_cita_prog;
  if v_estado <> 'programada' then
    raise exception 'Reactivar al paciente cambió una cita a %.', v_estado;
  end if;

  -- ------------------------- 6. reenviar el mismo estatus no barre la agenda
  -- La app manda `estatus` en cada update de persona; sin la guarda de
  -- transición, editar un teléfono cancelaría las citas otra vez.
  update personas set estatus = 'inactivo' where id = v_paciente_id;   -- transición real
  update citas set estado = 'programada', updated_at = now() where id = v_cita_prog;
  update personas set estatus = 'inactivo', nombre = 'Luis Alberto' where id = v_paciente_id;

  select estado::text into v_estado from citas where id = v_cita_prog;
  if v_estado <> 'programada' then
    raise exception
      'Un update sin cambio de estatus volvió a cancelar la agenda (la cita quedó en %).',
      v_estado;
  end if;

  raise notice 'SD-169 OK · baja del paciente: 3 citas canceladas; en_consulta, consulta abierta, pasada, terminal y ajena intactas';
end $$;

rollback;
