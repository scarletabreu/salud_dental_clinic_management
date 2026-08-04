-- HFX-CLIN-003 · barreras activas de seguridad clínica.
-- Se ejecuta tras `supabase db reset` y revierte todos sus datos.
--
--   psql "$DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/hfx_clin_003_barreras_clinicas_test.sql

begin;
set local role postgres;

-- ---------------------------------------------------------------------------
-- 0.a · Se parte de un motor sin umbrales aprobados
-- ---------------------------------------------------------------------------
-- Esta prueba trata sobre *cómo* una regla entra en vigor: comprueba que sin
-- aprobación el motor calla y que aprobar una no aprueba las demás. Desde
-- HFX-CLIN-006 la instalación trae los umbrales ya aprobados por el dueño
-- clínico, de modo que sin este paso el escenario arrancaría con las barreras
-- puestas y no podría demostrar nada. Se retiran aquí, dentro de la
-- transacción que al final se revierte: la instalación real no se toca.
update public.reglas_clinicas
   set estado = 'pendiente_aprobacion'
 where estado = 'aprobada';

-- ---------------------------------------------------------------------------
-- 0 · Escenario: una doctora, una paciente embarazada, catálogo mínimo.
-- ---------------------------------------------------------------------------
do $$
declare
  v_doc         uuid := '40000000-0000-4000-8000-000000000001';
  v_paciente    uuid := '40000000-0000-4000-8000-000000000010';
  v_record      uuid;
  v_cita        uuid;
  v_consulta    uuid;
  v_odontograma uuid;
  v_diente      uuid;
begin
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    created_at, updated_at, raw_user_meta_data
  ) values
  (v_doc, '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'hfx003-doc@test.local', 'x', now(), now(),
   '{"rol":"doctor","nombre":"Dolores","apellido":"Segura","fecha_nacimiento":"1980-01-01","cedula":"HFX003-D1","username":"hfx003_d1","especialidad":"General"}');

  insert into public.personas (id, nombre, apellido, fecha_nacimiento, cedula)
  values (v_paciente, 'Paula', 'Gestante', date '1996-05-05', 'HFX003-P');
  insert into public.pacientes (id, genero) values (v_paciente, 'femenino');
  insert into public.records (paciente_id, tipo_sangre, cirugias_previas, historial_familiar)
  values (v_paciente, 'o_positivo', '{}', 'Sin antecedentes')
  returning id into v_record;

  insert into public.citas (persona_id, doctor_id, fecha_hora, duracion_minutos, estado)
  values (v_paciente, v_doc, now() + interval '1 day', 30, 'en_consulta')
  returning id into v_cita;

  insert into public.consultas (paciente_id, doctor_id, cita_id, fecha)
  values (v_paciente, v_doc, v_cita, now())
  returning id into v_consulta;

  insert into public.odontogramas (consulta_id) values (v_consulta)
  returning id into v_odontograma;
  insert into public.dientes (odontograma_id, fdi_code) values (v_odontograma, 36)
  returning id into v_diente;

  -- Catálogo clínico.
  insert into public.condiciones (id, nombre, tipo, categoria) values
    ('40000000-0000-4000-8000-000000000100', 'Embarazo HFX003', 'fisiologica', 'temporal'),
    ('40000000-0000-4000-8000-000000000101', 'Alergia a penicilina HFX003', 'alergica', 'cronica'),
    ('40000000-0000-4000-8000-000000000102', 'Hipertensión HFX003', 'patologica', 'cronica'),
    ('40000000-0000-4000-8000-000000000103', 'Diabetes HFX003', 'patologica', 'cronica');

  insert into public.medicinas (id, nombre, principio_activo) values
    ('40000000-0000-4000-8000-000000000200', 'Amoxicilina HFX003', 'amoxicilina'),
    ('40000000-0000-4000-8000-000000000201', 'Amoxil HFX003', 'amoxicilina'),
    ('40000000-0000-4000-8000-000000000202', 'Ibuprofeno HFX003', 'ibuprofeno'),
    ('40000000-0000-4000-8000-000000000203', 'Paracetamol HFX003', null),
    -- Dos marcas del mismo principio activo y sin contraindicación: así la
    -- duplicidad se prueba sola, sin que la tape un bloqueo absoluto.
    ('40000000-0000-4000-8000-000000000204', 'Naproxeno HFX003', 'naproxeno'),
    ('40000000-0000-4000-8000-000000000205', 'Naprox-Plus HFX003', 'naproxeno');

  -- Absoluta: alergia ↔ amoxicilina. Relativa: embarazo ↔ ibuprofeno.
  insert into public.contraindicaciones
    (condicion_id, medicina_id, descripcion, tipo_contraindicacion) values
    ('40000000-0000-4000-8000-000000000101', '40000000-0000-4000-8000-000000000200',
     'Reacción anafiláctica documentada', 'absoluta'),
    ('40000000-0000-4000-8000-000000000100', '40000000-0000-4000-8000-000000000202',
     'AINE desaconsejado en el tercer trimestre', 'relativa');

  insert into public.tratamientos (id, nombre, costo, alcance) values
    ('40000000-0000-4000-8000-000000000300', 'Profilaxis HFX003', 1200, 'global'),
    ('40000000-0000-4000-8000-000000000301', 'Resina HFX003', 2500, 'puntual');
  insert into public.diagnosticos (id, nombre, alcance, categoria) values
    ('40000000-0000-4000-8000-000000000400', 'Gingivitis generalizada HFX003', 'global', 'periodontitis'),
    ('40000000-0000-4000-8000-000000000401', 'Caries oclusal HFX003', 'puntual', 'caries');

  perform set_config('hfx003.doc', v_doc::text, true);
  perform set_config('hfx003.paciente', v_paciente::text, true);
  perform set_config('hfx003.record', v_record::text, true);
  perform set_config('hfx003.consulta', v_consulta::text, true);
  perform set_config('hfx003.diente', v_diente::text, true);
end;
$$;

-- ---------------------------------------------------------------------------
-- 1 · Un valor físicamente imposible no entra, venga de donde venga.
-- ---------------------------------------------------------------------------
do $$
declare
  v_consulta uuid := current_setting('hfx003.consulta')::uuid;
  v_fallo    boolean;
begin
  v_fallo := false;
  begin
    perform public.guardar_borrador_consulta(v_consulta, null, jsonb_build_object(
      'signos_vitales_medidos', jsonb_build_array(
        jsonb_build_object('codigo', 'temperatura', 'valor', 62)
      )));
    v_fallo := true;
  exception when sqlstate 'CL006' then null;
  end;
  if v_fallo then raise exception 'se aceptó una temperatura de 62 °C'; end if;

  v_fallo := false;
  begin
    insert into public.signos_vitales_consulta (consulta_id, codigo, valor, unidad)
    values (v_consulta, 'saturacion_o2', 130, '%');
    v_fallo := true;
  exception when sqlstate 'CL006' then null;
  end;
  if v_fallo then raise exception 'un INSERT directo coló una saturación de 130 %%'; end if;

  -- Relación imposible: la diastólica no puede alcanzar a la sistólica.
  v_fallo := false;
  begin
    perform public.guardar_borrador_consulta(v_consulta, null, jsonb_build_object(
      'signos_vitales_medidos', jsonb_build_array(
        jsonb_build_object('codigo', 'presion_sistolica', 'valor', 110),
        jsonb_build_object('codigo', 'presion_diastolica', 'valor', 115)
      )));
    v_fallo := true;
  exception when sqlstate 'CL006' then null;
  end;
  if v_fallo then raise exception 'se aceptó una diastólica mayor que la sistólica'; end if;

  if exists (select 1 from public.signos_vitales_consulta
              where consulta_id = v_consulta and deleted_at is null) then
    raise exception 'una medición rechazada dejó rastro en la consulta';
  end if;

  raise notice 'OK 1 · valores y relaciones imposibles se rechazan en la base';
end;
$$;

-- ---------------------------------------------------------------------------
-- 2 · Signos vitales válidos: se guardan estructurados y con su contexto.
-- ---------------------------------------------------------------------------
do $$
declare
  v_consulta uuid := current_setting('hfx003.consulta')::uuid;
  v_fila     record;
begin
  perform public.guardar_borrador_consulta(v_consulta, null, jsonb_build_object(
    'signos_vitales_medidos', jsonb_build_array(
      jsonb_build_object('codigo', 'presion_sistolica', 'valor', 165),
      jsonb_build_object('codigo', 'presion_diastolica', 'valor', 105),
      jsonb_build_object('codigo', 'pulso', 'valor', 108),
      jsonb_build_object('codigo', 'temperatura', 'valor', 38.6),
      jsonb_build_object('codigo', 'saturacion_o2', 'valor', 92, 'origen', 'dispositivo'),
      jsonb_build_object('codigo', 'dolor', 'valor', 9, 'origen', 'referido',
                         'observacion', 'Dolor pulsátil')
    )));

  select * into v_fila from public.signos_vitales_consulta
   where consulta_id = v_consulta and codigo = 'dolor' and deleted_at is null;

  if v_fila.unidad <> '/10' or v_fila.origen <> 'referido'
     or v_fila.medido_por is null or v_fila.observacion is null then
    raise exception 'la medición no conservó unidad, origen, actor u observación: %', v_fila;
  end if;

  -- El resumen derivado sigue alimentando a los lectores antiguos.
  if (select (signos_vitales ->> 'pulso')::numeric from public.consultas where id = v_consulta) <> 108 then
    raise exception 'consultas.signos_vitales no refleja la medición guardada';
  end if;

  raise notice 'OK 2 · la medición guarda valor, unidad, momento, actor y origen';
end;
$$;

-- ---------------------------------------------------------------------------
-- 3 · El motor solo evalúa reglas aprobadas y con parámetros.
-- ---------------------------------------------------------------------------
do $$
declare
  v_consulta uuid := current_setting('hfx003.consulta')::uuid;
  v_alertas  jsonb;
  v_propia   jsonb;
begin
  -- La comprobación se hace con una regla propia y no con las que trae la
  -- instalación: desde HFX-CLIN-006 los umbrales de fábrica están aprobados y
  -- disparan sobre estos mismos signos, así que contar el total no diría nada
  -- sobre si el motor respeta el estado de aprobación.
  insert into public.reglas_clinicas (
    codigo, version, nombre, categoria, tipo, accion, severidad, estado
  ) values (
    'HFX003_PRUEBA_PULSO', 1, 'Pulso fuera de rango (prueba)',
    'signo_vital', 'valor_critico', 'documentar', 'critica',
    'pendiente_aprobacion'
  );

  -- Sin aprobar y sin parámetros, el motor no inventa nada.
  v_alertas := public.hfx_clin_003_evaluar_alertas(v_consulta);
  if v_alertas @> '[{"regla":"HFX003_PRUEBA_PULSO"}]'::jsonb then
    raise exception 'una regla sin aprobar produjo alertas: %', v_alertas;
  end if;

  -- El dueño clínico aprueba el umbral: a partir de ahí el dato no pasa callado.
  update public.reglas_clinicas
     set parametros = jsonb_build_object('codigo', 'pulso', 'min', 50, 'max', 100),
         estado = 'aprobada',
         aprobada_en = now(),
         fuente = 'Aprobación de prueba HFX-CLIN-003'
   where codigo = 'HFX003_PRUEBA_PULSO' and version = 1;

  v_alertas := public.hfx_clin_003_evaluar_alertas(v_consulta);
  select value into v_propia
    from jsonb_array_elements(v_alertas)
   where value ->> 'regla' = 'HFX003_PRUEBA_PULSO';

  if v_propia is null then
    raise exception 'la regla aprobada no produjo su alerta: %', v_alertas;
  end if;
  if (v_propia -> 'disparador' ->> 'valor')::numeric <> 108 then
    raise exception 'la alerta no dice qué dato la disparó: %', v_propia;
  end if;
  if v_propia ->> 'accion' <> 'documentar' then
    raise exception 'la alerta perdió la acción que exige: %', v_propia;
  end if;

  raise notice 'OK 3 · sin aprobación no hay umbral; con aprobación la alerta nombra el dato';
end;
$$;

-- ---------------------------------------------------------------------------
-- 4 · Una alerta que exige acción documentada bloquea el cierre.
-- ---------------------------------------------------------------------------
do $$
declare
  v_consulta uuid := current_setting('hfx003.consulta')::uuid;
  v_alerta   uuid;
  v_fallo    boolean := false;
begin
  begin
    perform public.cerrar_consulta(v_consulta, null, '{}'::jsonb, 'hfx003-cierre-1');
    v_fallo := true;
  exception when sqlstate 'CL007' then null;
  end;
  if v_fallo then raise exception 'la consulta cerró con una alerta pendiente'; end if;

  if (select finalizada from public.consultas where id = v_consulta) then
    raise exception 'el cierre bloqueado dejó la consulta finalizada';
  end if;

  select id into v_alerta from public.alertas_clinicas
   where consulta_id = v_consulta and estado = 'pendiente';

  -- Documentar sin justificación no es documentar.
  v_fallo := false;
  begin
    perform public.resolver_alerta_clinica(v_alerta, 'documentada', '   ');
    v_fallo := true;
  exception when sqlstate 'CL007' then null;
  end;
  if v_fallo then raise exception 'se documentó una alerta sin justificación'; end if;

  perform public.resolver_alerta_clinica(
    v_alerta, 'documentada',
    'Taquicardia por ansiedad; se pospone el tratamiento electivo y se refiere a control.');

  if not exists (select 1 from public.auditoria_clinica
                  where consulta_id = v_consulta and evento = 'alerta_resuelta') then
    raise exception 'resolver la alerta no dejó auditoría';
  end if;

  raise notice 'OK 4 · la alerta exige acción documentada y bloquea el cierre hasta resolverla';
end;
$$;

-- ---------------------------------------------------------------------------
-- 5 · Una condición descubierta hoy participa de inmediato.
-- ---------------------------------------------------------------------------
do $$
declare
  v_consulta uuid := current_setting('hfx003.consulta')::uuid;
  v_fallo    boolean := false;
begin
  -- El expediente no tiene la alergia: se descubre durante la consulta.
  perform public.guardar_borrador_consulta(v_consulta, null, jsonb_build_object(
    'condiciones_detectadas', jsonb_build_array(
      jsonb_build_object('condicion_id', '40000000-0000-4000-8000-000000000101',
                         'severidad', 'severa',
                         'notas', 'Refiere edema tras amoxicilina',
                         'incorporar_al_expediente', true),
      jsonb_build_object('condicion_id', '40000000-0000-4000-8000-000000000100',
                         'severidad', 'moderada')
    )));

  if (select count(*) from public.condiciones_activas_paciente
       where paciente_id = current_setting('hfx003.paciente')::uuid
         and origen = 'consulta') <> 2 then
    raise exception 'la condición descubierta hoy no cuenta como activa';
  end if;

  -- Y bloquea de inmediato: sin esperar al cierre ni a que alguien la copie
  -- al expediente.
  begin
    perform public.guardar_borrador_consulta(v_consulta, null, jsonb_build_object(
      'recetas', jsonb_build_array(jsonb_build_object(
        'items_receta', jsonb_build_array(jsonb_build_object(
          'medicamento_id', '40000000-0000-4000-8000-000000000200',
          'nombre_medicamento', 'Amoxicilina HFX003',
          'dosis_cantidad', 1, 'dosis_unidad', 'tableta',
          'via_administracion', 'oral', 'frecuencia_horas', 8,
          'duracion_dias', 7, 'cantidad_total', 21,
          'justificacion_riesgo', 'El paciente insiste'
        ))))));
    v_fallo := true;
  exception when sqlstate 'CL010' then null;
  end;
  if v_fallo then
    raise exception 'una contraindicación absoluta se saltó con una justificación';
  end if;

  raise notice 'OK 5 · la condición descubierta hoy contraindica sin bypass posible';
end;
$$;

-- ---------------------------------------------------------------------------
-- 6 · Riesgo relativo: justificación por medicamento, no una nota global.
-- ---------------------------------------------------------------------------
do $$
declare
  v_consulta uuid := current_setting('hfx003.consulta')::uuid;
  v_fallo    boolean := false;
begin
  begin
    perform public.guardar_borrador_consulta(v_consulta, null, jsonb_build_object(
      'recetas', jsonb_build_array(jsonb_build_object(
        'justificacion_contraindicaciones', 'Justificación general de la receta',
        'items_receta', jsonb_build_array(jsonb_build_object(
          'medicamento_id', '40000000-0000-4000-8000-000000000202',
          'nombre_medicamento', 'Ibuprofeno HFX003',
          'dosis_cantidad', 1, 'dosis_unidad', 'tableta',
          'via_administracion', 'oral', 'frecuencia_horas', 8,
          'duracion_dias', 5, 'cantidad_total', 15
        ))))));
    v_fallo := true;
  exception when sqlstate 'CL011' then null;
  end;
  if v_fallo then
    raise exception 'un riesgo relativo pasó sin justificación propia del medicamento';
  end if;

  perform public.guardar_borrador_consulta(v_consulta, null, jsonb_build_object(
    'recetas', jsonb_build_array(jsonb_build_object(
      'items_receta', jsonb_build_array(jsonb_build_object(
        'medicamento_id', '40000000-0000-4000-8000-000000000202',
        'nombre_medicamento', 'Ibuprofeno HFX003',
        'dosis_cantidad', 1, 'dosis_unidad', 'tableta',
        'via_administracion', 'oral', 'frecuencia_horas', 8,
        'duracion_dias', 5, 'cantidad_total', 15,
        'justificacion_riesgo', 'Segundo trimestre, dosis mínima y por 5 días.'
      ))))));

  raise notice 'OK 6 · el riesgo relativo exige justificación por medicamento y la conserva';
end;
$$;

-- ---------------------------------------------------------------------------
-- 7 · Duplicidad y cantidad incoherente se detienen al emitir.
-- ---------------------------------------------------------------------------
do $$
declare
  v_consulta uuid := current_setting('hfx003.consulta')::uuid;
  v_fallo    boolean;
  v_base     jsonb;
begin
  -- Mismo principio activo en dos marcas distintas.
  v_fallo := false;
  begin
    perform public.hfx_clin_003_validar_receta(v_consulta, jsonb_build_array(
      jsonb_build_object('medicamento_id', '40000000-0000-4000-8000-000000000204',
        'nombre_medicamento', 'Naproxeno HFX003', 'dosis_cantidad', 1,
        'dosis_unidad', 'tableta', 'via_administracion', 'oral',
        'frecuencia_horas', 8, 'duracion_dias', 7, 'cantidad_total', 21),
      jsonb_build_object('medicamento_id', '40000000-0000-4000-8000-000000000205',
        'nombre_medicamento', 'Naprox-Plus HFX003', 'dosis_cantidad', 1,
        'dosis_unidad', 'tableta', 'via_administracion', 'oral',
        'frecuencia_horas', 12, 'duracion_dias', 7, 'cantidad_total', 14)
    ), true);
    v_fallo := true;
  exception when sqlstate 'CL009' then null;
       when sqlstate 'CL010' then
         raise exception 'la duplicidad quedó tapada por la contraindicación';
  end;
  if v_fallo then raise exception 'se recetaron dos marcas del mismo principio activo'; end if;

  -- Cantidad que no alcanza para el tratamiento indicado.
  v_fallo := false;
  begin
    perform public.hfx_clin_003_validar_receta(v_consulta, jsonb_build_array(
      jsonb_build_object('medicamento_id', '40000000-0000-4000-8000-000000000203',
        'nombre_medicamento', 'Paracetamol HFX003', 'dosis_cantidad', 1,
        'dosis_unidad', 'tableta', 'via_administracion', 'oral',
        'frecuencia_horas', 6, 'duracion_dias', 5, 'cantidad_total', 6)
    ), true);
    v_fallo := true;
  exception when sqlstate 'CL008' then null;
  end;
  if v_fallo then raise exception 'se despachó menos cantidad de la que exige la pauta'; end if;

  -- Renglón sin vía de administración.
  v_fallo := false;
  begin
    perform public.hfx_clin_003_validar_receta(v_consulta, jsonb_build_array(
      jsonb_build_object('medicamento_id', '40000000-0000-4000-8000-000000000203',
        'nombre_medicamento', 'Paracetamol HFX003', 'dosis_cantidad', 1,
        'dosis_unidad', 'tableta', 'frecuencia_horas', 6,
        'duracion_dias', 5, 'cantidad_total', 20)
    ), true);
    v_fallo := true;
  exception when sqlstate 'CL008' then null;
  end;
  if v_fallo then raise exception 'se emitió un renglón sin vía de administración'; end if;

  -- Sin principio activo en catálogo no se afirma nada: el renglón es válido y
  -- la falta de información se informa en la pantalla, no se disfraza aquí.
  v_base := jsonb_build_array(
    jsonb_build_object('medicamento_id', '40000000-0000-4000-8000-000000000203',
      'nombre_medicamento', 'Paracetamol HFX003', 'dosis_cantidad', 1,
      'dosis_unidad', 'tableta', 'via_administracion', 'oral',
      'frecuencia_horas', 6, 'duracion_dias', 5, 'cantidad_total', 20));
  perform public.hfx_clin_003_validar_receta(v_consulta, v_base, true);

  raise notice 'OK 7 · duplicidad, cantidad incoherente y renglón incompleto se detienen';
end;
$$;

-- ---------------------------------------------------------------------------
-- 8 · Alcance clínico: la base rechaza la combinación imposible.
-- ---------------------------------------------------------------------------
do $$
declare
  v_consulta uuid := current_setting('hfx003.consulta')::uuid;
  v_diente   uuid := current_setting('hfx003.diente')::uuid;
  v_fallo    boolean;
begin
  -- Un tratamiento global colgado de una pieza.
  v_fallo := false;
  begin
    insert into public.tratamientos_aplicados
      (tratamiento_id, consulta_id, diente_id, estado, precio_aplicado)
    values ('40000000-0000-4000-8000-000000000300', v_consulta, v_diente, 'aplicado', 1200);
    v_fallo := true;
  exception when sqlstate 'CL012' then null;
  end;
  if v_fallo then raise exception 'un tratamiento global se asignó a una pieza'; end if;

  -- Un hallazgo puntual sin cara.
  v_fallo := false;
  begin
    insert into public.diagnosticos_aplicados
      (diagnosis_id, severidad, consulta_id, diente_id)
    values ('40000000-0000-4000-8000-000000000401', 'moderada', v_consulta, v_diente);
    v_fallo := true;
  exception when sqlstate 'CL012' then null;
  end;
  if v_fallo then raise exception 'un hallazgo puntual se guardó sin superficie'; end if;

  -- La vía correcta para lo global: el payload lo registra sin pieza.
  perform public.guardar_borrador_consulta(v_consulta, null, jsonb_build_object(
    'generales', jsonb_build_object(
      'tratamientos', jsonb_build_array(jsonb_build_object(
        'tratamiento_id', '40000000-0000-4000-8000-000000000300',
        'precio_aplicado', 1200, 'estado', 'completado')),
      'diagnosticos', jsonb_build_array(jsonb_build_object(
        'diagnosis_id', '40000000-0000-4000-8000-000000000400',
        'severidad', 'moderada')))));

  if not exists (
    select 1 from public.tratamientos_aplicados
     where consulta_id = v_consulta and diente_id is null and deleted_at is null
       and tratamiento_id = '40000000-0000-4000-8000-000000000300'
       and esta_terminado) then
    raise exception 'el tratamiento global no se registró sin pieza, o su estado no cuadra';
  end if;

  if not exists (
    select 1 from public.diagnosticos_aplicados
     where consulta_id = v_consulta and diente_id is null and deleted_at is null) then
    raise exception 'el hallazgo global no se registró sin pieza';
  end if;

  raise notice 'OK 8 · el alcance del catálogo manda, y lo global tiene su propia vía';
end;
$$;

-- ---------------------------------------------------------------------------
-- 9 · Consentimiento: sin evidencia no hay plan aceptado.
-- ---------------------------------------------------------------------------
do $$
declare
  v_plan   uuid;
  v_item   uuid;
  v_res    jsonb;
  v_fallo  boolean := false;
  v_version integer;
begin
  insert into public.planes_tratamiento (paciente_id, doctor_id, consulta_origen_id, fecha_propuesta)
  values (current_setting('hfx003.paciente')::uuid, current_setting('hfx003.doc')::uuid,
          current_setting('hfx003.consulta')::uuid, now())
  returning id into v_plan;

  insert into public.items_plan_tratamiento
    (plan_id, tratamiento_id, diente_id, superficie, estado, precio_estimado, doctor_propone_id)
  values (v_plan, '40000000-0000-4000-8000-000000000301',
          current_setting('hfx003.diente')::uuid, 'oclusal', 'propuesto', 2500,
          current_setting('hfx003.doc')::uuid)
  returning id into v_item;

  update public.planes_tratamiento set estado = 'propuesto' where id = v_plan;

  begin
    update public.planes_tratamiento set estado = 'aceptado' where id = v_plan;
    v_fallo := true;
  exception when sqlstate 'CL013' then null;
  end;
  if v_fallo then raise exception 'un plan se aceptó sin consentimiento registrado'; end if;

  -- Con sesión real de la doctora: la evidencia tiene que decir quién la
  -- registró, y eso sale de la sesión, no del payload.
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', current_setting('hfx003.doc'), 'role', 'authenticated')::text,
    true);

  v_res := public.registrar_consentimiento_plan(
    v_plan, 'aceptado', 'Paula Gestante', 'firma_fisica', 'titular');

  perform set_config('role', 'postgres', true);

  if (v_res ->> 'total_aceptado')::numeric <> 2500 then
    raise exception 'el consentimiento no congeló el precio aceptado: %', v_res;
  end if;
  if (select estado::text from public.planes_tratamiento where id = v_plan) <> 'aceptado' then
    raise exception 'el consentimiento no aplicó la decisión al plan';
  end if;
  if not exists (
    select 1 from public.consentimientos_plan
     where plan_id = v_plan and persona_acepta = 'Paula Gestante'
       and metodo = 'firma_fisica' and registrado_por is not null) then
    raise exception 'el consentimiento no guardó quién aceptó ni por qué medio';
  end if;

  -- Cambiar el precio invalida lo aceptado: el paciente vio otra cosa.
  select version into v_version from public.planes_tratamiento where id = v_plan;
  update public.items_plan_tratamiento set precio_estimado = 4000 where id = v_item;
  if (select version from public.planes_tratamiento where id = v_plan) <= v_version then
    raise exception 'cambiar el precio no subió la versión del plan';
  end if;

  update public.planes_tratamiento set estado = 'propuesto' where id = v_plan;
  v_fallo := false;
  begin
    update public.planes_tratamiento set estado = 'aceptado' where id = v_plan;
    v_fallo := true;
  exception when sqlstate 'CL013' then null;
  end;
  if v_fallo then
    raise exception 'el consentimiento de una versión anterior siguió valiendo';
  end if;

  raise notice 'OK 9 · el consentimiento guarda evidencia, versión y precios, y caduca al cambiar el plan';
end;
$$;

-- ---------------------------------------------------------------------------
-- 10 · Cierre: incorpora lo confirmado y no factura lo que no se ejecutó.
-- ---------------------------------------------------------------------------
do $$
declare
  v_consulta uuid := current_setting('hfx003.consulta')::uuid;
  v_res      jsonb;
begin
  v_res := public.cerrar_consulta(v_consulta, null, '{}'::jsonb, 'hfx003-cierre-ok');

  if not (v_res ->> 'finalizada')::boolean then
    raise exception 'la consulta no cerró tras resolver la alerta: %', v_res;
  end if;

  -- La alergia se marcó para incorporar; el embarazo no.
  if not exists (
    select 1 from public.record_condicion
     where record_id = current_setting('hfx003.record')::uuid
       and condicion_id = '40000000-0000-4000-8000-000000000101') then
    raise exception 'la condición confirmada no llegó al expediente';
  end if;
  if exists (
    select 1 from public.record_condicion
     where record_id = current_setting('hfx003.record')::uuid
       and condicion_id = '40000000-0000-4000-8000-000000000100') then
    raise exception 'una condición no confirmada se coló en el expediente';
  end if;

  if (select count(*) from public.recetas
       where consulta_id = v_consulta and estado = 'emitida' and deleted_at is null) <> 1 then
    raise exception 'la receta válida no se emitió al cerrar';
  end if;

  raise notice 'OK 10 · el cierre incorpora lo confirmado y emite la receta validada';
end;
$$;

-- ---------------------------------------------------------------------------
-- 11 · Escenario 2: un adulto hipertenso y diabético, y un niño de 8 años.
-- ---------------------------------------------------------------------------
do $$
declare
  v_doc      uuid := current_setting('hfx003.doc')::uuid;
  v_adulto   uuid := '40000000-0000-4000-8000-000000000020';
  v_nino     uuid := '40000000-0000-4000-8000-000000000030';
  v_record   uuid;
  v_cita     uuid;
  v_consulta uuid;
begin
  -- Adulto con hipertensión y diabetes ya en el expediente.
  insert into public.personas (id, nombre, apellido, fecha_nacimiento, cedula)
  values (v_adulto, 'Hilario', 'Tenso', date '1965-03-02', 'HFX003-A');
  insert into public.pacientes (id, genero) values (v_adulto, 'masculino');
  insert into public.records (paciente_id, tipo_sangre, cirugias_previas, historial_familiar)
  values (v_adulto, 'a_positivo', '{}', 'Cardiopatía familiar')
  returning id into v_record;

  insert into public.record_condicion (record_id, condicion_id, activo) values
    (v_record, '40000000-0000-4000-8000-000000000102', true),
    (v_record, '40000000-0000-4000-8000-000000000103', true);

  insert into public.citas (persona_id, doctor_id, fecha_hora, duracion_minutos, estado)
  values (v_adulto, v_doc, now() + interval '2 day', 30, 'en_consulta')
  returning id into v_cita;
  insert into public.consultas (paciente_id, doctor_id, cita_id, fecha)
  values (v_adulto, v_doc, v_cita, now())
  returning id into v_consulta;
  perform set_config('hfx003.consulta_adulto', v_consulta::text, true);

  -- Niño de 8 años, sin condiciones.
  insert into public.personas (id, nombre, apellido, fecha_nacimiento, cedula)
  values (v_nino, 'Nico', 'Pequeño', (current_date - interval '8 years')::date, 'HFX003-N');
  insert into public.pacientes (id, genero) values (v_nino, 'masculino');
  insert into public.records (paciente_id, tipo_sangre, cirugias_previas, historial_familiar)
  values (v_nino, 'o_positivo', '{}', 'Sin antecedentes');

  insert into public.citas (persona_id, doctor_id, fecha_hora, duracion_minutos, estado)
  values (v_nino, v_doc, now() + interval '3 day', 30, 'en_consulta')
  returning id into v_cita;
  insert into public.consultas (paciente_id, doctor_id, cita_id, fecha)
  values (v_nino, v_doc, v_cita, now())
  returning id into v_consulta;
  perform set_config('hfx003.consulta_nino', v_consulta::text, true);

  -- La edad se calcula del expediente, no se supone.
  if round(public.hfx_clin_003_edad_paciente(v_nino)) <> 8 then
    raise exception 'la edad del paciente pediátrico no se calculó bien: %',
      public.hfx_clin_003_edad_paciente(v_nino);
  end if;
  if public.hfx_clin_003_edad_paciente(v_adulto) < 55 then
    raise exception 'la edad del adulto no se calculó bien';
  end if;

  raise notice 'OK 11 · el escenario de hipertensión, diabetes y pediatría queda montado';
end;
$$;

-- ---------------------------------------------------------------------------
-- 12 · Hipertensión y diabetes: cada condición aprobada alerta por su cuenta.
-- ---------------------------------------------------------------------------
do $$
declare
  v_consulta uuid := current_setting('hfx003.consulta_adulto')::uuid;
  v_alertas  jsonb;
  v_codigos  text[];
begin
  perform public.guardar_borrador_consulta(v_consulta, null, jsonb_build_object(
    'signos_vitales_medidos', jsonb_build_array(
      jsonb_build_object('codigo', 'presion_sistolica', 'valor', 168),
      jsonb_build_object('codigo', 'presion_diastolica', 'valor', 104),
      jsonb_build_object('codigo', 'pulso', 'valor', 76)
    )));

  -- Con las combinaciones pendientes de aprobar, el motor calla.
  v_alertas := public.hfx_clin_003_evaluar_alertas(v_consulta);
  select coalesce(array_agg(a ->> 'regla'), '{}')
    into v_codigos from jsonb_array_elements(v_alertas) a;
  if 'COMB_HIPERTENSION_SIGNOS' = any (v_codigos)
     or 'COMB_DIABETES_SIGNOS' = any (v_codigos) then
    raise exception 'una combinación sin aprobar produjo alerta: %', v_alertas;
  end if;

  -- El dueño clínico aprueba la de hipertensión.
  update public.reglas_clinicas
     set parametros = jsonb_build_object(
           'condicion', 'Hipertensión HFX003',
           'signos', jsonb_build_array(
             jsonb_build_object('codigo', 'presion_sistolica', 'max', 140))),
         estado = 'aprobada', aprobada_en = now(),
         fuente = 'Aprobación de prueba HFX-CLIN-003'
   where codigo = 'COMB_HIPERTENSION_SIGNOS' and version = 1;

  v_alertas := public.hfx_clin_003_evaluar_alertas(v_consulta);
  if not exists (
    select 1 from jsonb_array_elements(v_alertas) a
     where a ->> 'regla' = 'COMB_HIPERTENSION_SIGNOS'
       and a -> 'disparador' ->> 'codigo' = 'presion_sistolica'
       and (a -> 'disparador' ->> 'valor')::numeric = 168
       and a ->> 'accion' = 'documentar') then
    raise exception 'la hipertensión con presión alterada no alertó: %', v_alertas;
  end if;

  -- La diabetes sigue pendiente: aprobar una regla no aprueba las demás.
  if exists (select 1 from jsonb_array_elements(v_alertas) a
              where a ->> 'regla' = 'COMB_DIABETES_SIGNOS') then
    raise exception 'la diabetes alertó sin estar aprobada: %', v_alertas;
  end if;

  update public.reglas_clinicas
     set parametros = jsonb_build_object(
           'condicion', 'Diabetes HFX003',
           'signos', jsonb_build_array(
             jsonb_build_object('codigo', 'pulso', 'max', 70))),
         estado = 'aprobada', aprobada_en = now(),
         fuente = 'Aprobación de prueba HFX-CLIN-003'
   where codigo = 'COMB_DIABETES_SIGNOS' and version = 1;

  v_alertas := public.hfx_clin_003_evaluar_alertas(v_consulta);
  if not exists (select 1 from jsonb_array_elements(v_alertas) a
                  where a ->> 'regla' = 'COMB_DIABETES_SIGNOS'
                    and a -> 'disparador' ->> 'condicion' = 'Diabetes HFX003') then
    raise exception 'la diabetes aprobada no alertó con el pulso fuera de rango: %', v_alertas;
  end if;

  -- Y el cierre no pasa mientras las dos sigan pendientes de documentar.
  begin
    perform public.cerrar_consulta(v_consulta, null, '{}'::jsonb, 'hfx003-adulto-1');
    raise exception 'la consulta cerró con dos alertas críticas pendientes';
  exception when sqlstate 'CL007' then null;
  end;

  raise notice 'OK 12 · hipertensión y diabetes alertan por separado y detienen el cierre';
end;
$$;

-- ---------------------------------------------------------------------------
-- 13 · Pediatría: sin peso registrado no se dosifica.
-- ---------------------------------------------------------------------------
do $$
declare
  v_nino    uuid := current_setting('hfx003.consulta_nino')::uuid;
  v_adulto  uuid := current_setting('hfx003.consulta_adulto')::uuid;
  v_alertas jsonb;
  v_receta  jsonb;
  v_fallo   boolean := false;
begin
  v_receta := jsonb_build_array(jsonb_build_object(
    'medicamento_id', '40000000-0000-4000-8000-000000000203',
    'nombre_medicamento', 'Paracetamol HFX003', 'dosis_cantidad', 1,
    'dosis_unidad', 'tableta', 'via_administracion', 'oral',
    'frecuencia_horas', 8, 'duracion_dias', 5, 'cantidad_total', 15));

  -- Mientras la regla siga pendiente no hay barrera inventada.
  perform public.hfx_clin_003_validar_receta(v_nino, v_receta, true);

  update public.reglas_clinicas
     set parametros = jsonb_build_object('codigo', 'peso',
                                         'exige_al_recetar', true,
                                         'edad_max_anios', 12),
         estado = 'aprobada', aprobada_en = now(),
         fuente = 'Aprobación de prueba HFX-CLIN-003'
   where codigo = 'PED_PESO_REQUERIDO' and version = 1;

  -- Aprobada: al niño no se le receta sin peso.
  begin
    perform public.hfx_clin_003_validar_receta(v_nino, v_receta, true);
    v_fallo := true;
  exception when sqlstate 'CL012' then null;
  end;
  if v_fallo then raise exception 'se emitió una receta pediátrica sin peso registrado'; end if;

  -- Y el motor lo dice antes, como alerta explicable.
  v_alertas := public.hfx_clin_003_evaluar_alertas(v_nino);
  if not exists (select 1 from jsonb_array_elements(v_alertas) a
                  where a ->> 'regla' = 'PED_PESO_REQUERIDO'
                    and (a -> 'disparador' ->> 'faltante')::boolean
                    and a -> 'disparador' ->> 'codigo' = 'peso') then
    raise exception 'faltando el peso, el motor no avisó: %', v_alertas;
  end if;

  -- La misma regla no toca al adulto: la franja etaria manda.
  perform public.hfx_clin_003_validar_receta(v_adulto, v_receta, true);
  if exists (select 1 from public.alertas_clinicas
              where consulta_id = v_adulto and regla_codigo = 'PED_PESO_REQUERIDO'
                and estado <> 'obsoleta') then
    raise exception 'una regla pediátrica alcanzó a un adulto';
  end if;

  -- Con el peso registrado, la receta sale y la alerta deja de exigir acción.
  perform public.guardar_borrador_consulta(v_nino, null, jsonb_build_object(
    'signos_vitales_medidos', jsonb_build_array(
      jsonb_build_object('codigo', 'peso', 'valor', 26.5)
    )));

  perform public.hfx_clin_003_validar_receta(v_nino, v_receta, true);

  v_alertas := public.hfx_clin_003_evaluar_alertas(v_nino);
  if exists (select 1 from jsonb_array_elements(v_alertas) a
              where a ->> 'regla' = 'PED_PESO_REQUERIDO') then
    raise exception 'la alerta siguió viva después de registrar el peso: %', v_alertas;
  end if;
  if not exists (select 1 from public.alertas_clinicas
                  where consulta_id = v_nino and regla_codigo = 'PED_PESO_REQUERIDO'
                    and estado = 'obsoleta') then
    raise exception 'la alerta resuelta se borró en vez de quedar como obsoleta';
  end if;

  raise notice 'OK 13 · sin peso no hay dosificación pediátrica, y con peso la barrera se retira';
end;
$$;

rollback;
