-- SD-135 · Prueba funcional de la separación evaluación / plan / ejecución.
--
-- Se ejecuta sobre una base con `schema.sql` + la migración
-- 20260725120000_sd_135_evaluacion_plan_ejecucion.sql aplicados. Todo ocurre
-- dentro de una transacción que termina en ROLLBACK: no deja rastro.
--
--   psql -h 127.0.0.1 -p 54322 -U postgres -d <base> -v ON_ERROR_STOP=1 \
--        -f supabase/tests/sd_135_plan_tratamiento_test.sql
--
-- Verifica las tres reglas duras del ticket:
--   1. Un hallazgo de evaluación no genera tratamiento aplicado ni cuenta.
--   2. Una actividad propuesta no se puede vincular a una ejecución.
--   3. La pre-factura cobra la ejecución y solo la ejecución.

begin;

set local role postgres;

do $$
declare
  v_usuario_id    uuid := gen_random_uuid();
  v_doctor_id     uuid;
  v_paciente_id   uuid;
  v_consulta_id   uuid;
  v_odontograma_id uuid;
  v_diente_id     uuid;
  v_diagnosis_id  uuid;
  v_tratamiento_id uuid;
  v_evaluacion_id uuid;
  v_hallazgo_id   uuid;
  v_plan_id       uuid;
  v_item_id       uuid;
  v_cuenta_id     uuid;
  v_conteo        integer;
  v_total         numeric;
  v_fallo         boolean;
begin
  -- ---------------------------------------------------------------- montaje
  -- `usuarios` cuelga de `personas`, y `doctores` de `usuarios`.
  insert into personas (id, nombre, apellido, fecha_nacimiento, cedula, created_at, updated_at)
  values (v_usuario_id, 'Ana', 'Prueba', date '1990-01-01', 'SD135-DOC', now(), now());

  insert into usuarios (id, username, created_at, updated_at)
  values (v_usuario_id, 'sd135_doctor', now(), now());

  insert into doctores (id, especialidad, updated_at)
  values (v_usuario_id, 'General', now()) returning id into v_doctor_id;

  v_paciente_id := gen_random_uuid();
  insert into personas (id, nombre, apellido, fecha_nacimiento, cedula, created_at, updated_at)
  values (v_paciente_id, 'Luis', 'Paciente', date '1995-05-05', 'SD135-PAC', now(), now());
  insert into pacientes (id, genero, created_at, updated_at)
  values (v_paciente_id, 'masculino', now(), now());

  insert into consultas (paciente_id, doctor_id, fecha, motivo_consulta, created_at, updated_at)
  values (v_paciente_id, v_doctor_id, now(), 'Dolor molar', now(), now())
  returning id into v_consulta_id;

  insert into odontogramas (consulta_id, created_at, updated_at)
  values (v_consulta_id, now(), now()) returning id into v_odontograma_id;

  insert into dientes (odontograma_id, fdi_code, created_at, updated_at)
  values (v_odontograma_id, 36, now(), now()) returning id into v_diente_id;

  insert into diagnosticos (nombre, severidad_default, alcance, categoria, created_at, updated_at)
  values ('Caries oclusal SD135', 'moderada', 'puntual', 'caries', now(), now())
  returning id into v_diagnosis_id;

  insert into tratamientos (nombre, costo, alcance, created_at, updated_at)
  values ('Resina SD135', 2500.00, 'puntual', now(), now())
  returning id into v_tratamiento_id;

  -- ------------------------------------------- 1. evaluación con hallazgos
  insert into evaluaciones_clinicas (paciente_id, consulta_id, doctor_id, fecha, motivo)
  values (v_paciente_id, v_consulta_id, v_doctor_id, now(), 'Dolor molar')
  returning id into v_evaluacion_id;

  -- Tres hallazgos: la evaluación registra cuanto haga falta.
  insert into diagnosticos_aplicados (
    diagnosis_id, evaluacion_id, consulta_id, diente_id, superficie,
    severidad, fecha_aplicacion, origen, created_at, updated_at
  )
  select v_diagnosis_id, v_evaluacion_id, v_consulta_id, v_diente_id,
         cara::tipo_superficie, 'moderada', now(), 'estaConsulta', now(), now()
  from unnest(array['oclusal','mesial','distal']) as cara;

  select id into v_hallazgo_id
  from diagnosticos_aplicados
  where evaluacion_id = v_evaluacion_id and superficie = 'oclusal';

  select count(*) into v_conteo
  from diagnosticos_aplicados
  where evaluacion_id = v_evaluacion_id and deleted_at is null;
  if v_conteo <> 3 then
    raise exception 'Se esperaban 3 hallazgos en la evaluación, hay %.', v_conteo;
  end if;

  -- REGLA 1: registrar hallazgos no creó ejecución ni cuenta.
  select count(*) into v_conteo
  from tratamientos_aplicados where consulta_id = v_consulta_id and deleted_at is null;
  if v_conteo <> 0 then
    raise exception 'Un hallazgo generó % tratamiento(s) aplicado(s). Debe generar 0.', v_conteo;
  end if;

  select count(*) into v_conteo from cuentas where consulta_id = v_consulta_id;
  if v_conteo <> 0 then
    raise exception 'Un hallazgo generó % cuenta(s). Debe generar 0.', v_conteo;
  end if;

  -- --------------------------------------- 2. plan: solo lo que se trata
  insert into planes_tratamiento (
    paciente_id, evaluacion_id, consulta_origen_id, doctor_id, estado, fecha_propuesta
  ) values (
    v_paciente_id, v_evaluacion_id, v_consulta_id, v_doctor_id, 'propuesto', now()
  ) returning id into v_plan_id;

  -- De los tres hallazgos se decide tratar uno.
  insert into items_plan_tratamiento (
    plan_id, tratamiento_id, diagnostico_aplicado_id, diente_id, superficie,
    estado, precio_estimado, doctor_propone_id, fecha_propuesta
  ) values (
    v_plan_id, v_tratamiento_id, v_hallazgo_id, v_diente_id, 'oclusal',
    'propuesto', 2500.00, v_doctor_id, now()
  ) returning id into v_item_id;

  -- El plan tampoco factura por sí mismo.
  select count(*) into v_conteo from cuentas where consulta_id = v_consulta_id;
  if v_conteo <> 0 then
    raise exception 'Proponer una actividad generó una cuenta. Debe generar 0.';
  end if;

  -- REGLA 2: una propuesta no admite ejecución vinculada.
  v_fallo := false;
  begin
    insert into tratamientos_aplicados (
      tratamiento_id, item_plan_id, consulta_id, diente_id, superficie,
      es_continuo, esta_terminado, precio_aplicado, estado,
      doctor_ejecuta_id, fecha_ejecucion, created_at, updated_at
    ) values (
      v_tratamiento_id, v_item_id, v_consulta_id, v_diente_id, 'oclusal',
      false, true, 2500.00, 'aplicado', v_doctor_id, now(), now(), now()
    );
    v_fallo := true;
  exception when others then
    null; -- el trigger trg_item_plan_ejecutable hizo su trabajo
  end;
  if v_fallo then
    raise exception 'Se pudo ejecutar una actividad todavía en estado propuesto.';
  end if;

  -- REGLA extra: el eje de ejecución ya no admite intenciones.
  v_fallo := false;
  begin
    insert into tratamientos_aplicados (
      tratamiento_id, consulta_id, diente_id, es_continuo, esta_terminado,
      precio_aplicado, estado, created_at, updated_at
    ) values (
      v_tratamiento_id, v_consulta_id, v_diente_id, false, false,
      2500.00, 'indicado', now(), now()
    );
    v_fallo := true;
  exception when check_violation then
    null;
  end;
  if v_fallo then
    raise exception 'Se aceptó un tratamiento_aplicado en estado «indicado».';
  end if;

  -- ------------------------------------------------- 3. aceptar y ejecutar
  update items_plan_tratamiento
  set estado = 'aceptado', fecha_aceptacion = now(), updated_at = now()
  where id = v_item_id;

  insert into tratamientos_aplicados (
    tratamiento_id, item_plan_id, consulta_id, diente_id, superficie,
    es_continuo, esta_terminado, precio_aplicado, estado,
    doctor_ejecuta_id, fecha_ejecucion, created_at, updated_at
  ) values (
    v_tratamiento_id, v_item_id, v_consulta_id, v_diente_id, 'oclusal',
    false, true, 2500.00, 'aplicado', v_doctor_id, now(), now(), now()
  );

  update items_plan_tratamiento
  set estado = 'completado', fecha_completado = now(), updated_at = now()
  where id = v_item_id;

  -- Un segundo item queda propuesto y nunca se ejecuta: no debe facturar.
  insert into items_plan_tratamiento (
    plan_id, tratamiento_id, diente_id, estado, precio_estimado,
    doctor_propone_id, fecha_propuesta
  ) values (
    v_plan_id, v_tratamiento_id, v_diente_id, 'propuesto', 9999.00,
    v_doctor_id, now()
  );

  -- ---------------------------------------------------- 4. la pre-factura
  v_cuenta_id := finalizar_consulta(v_consulta_id, 'Contado', 'Prueba SD-135');

  select monto_total into v_total from cuentas where id = v_cuenta_id;
  if v_total <> 2500.00 then
    raise exception 'La pre-factura cobró % en vez de 2500.00 (solo lo ejecutado).', v_total;
  end if;

  select count(*) into v_conteo from items_cuenta where cuenta_id = v_cuenta_id;
  if v_conteo <> 1 then
    raise exception 'La pre-factura tiene % ítems; debía tener 1 (una sola ejecución).', v_conteo;
  end if;

  -- Idempotencia: reintentar no duplica la cuenta.
  if finalizar_consulta(v_consulta_id, 'Contado', null) <> v_cuenta_id then
    raise exception 'finalizar_consulta creó una segunda cuenta para la consulta.';
  end if;

  -- La auditoría quedó registrada en los tres ejes.
  select count(*) into v_conteo
  from tratamientos_aplicados
  where consulta_id = v_consulta_id
    and deleted_at is null
    and doctor_ejecuta_id is not null
    and fecha_ejecucion is not null;
  if v_conteo <> 1 then
    raise exception 'La ejecución no quedó auditada (doctor y fecha).';
  end if;

  raise notice 'SD-135 OK · evaluación 3 hallazgos → plan 2 actividades → 1 ejecución → cuenta 2500.00';
end $$;

rollback;
