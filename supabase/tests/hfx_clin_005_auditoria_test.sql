-- HFX-CLIN-005 · auditoría clínica y línea de tiempo.
-- Se ejecuta tras `supabase db reset` y revierte todos sus datos.
--
--   psql "$DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/hfx_clin_005_auditoria_test.sql

begin;
set local role postgres;

-- ---------------------------------------------------------------------------
-- 0 · Escenario: una doctora, otra doctora ajena, una asistente, un paciente.
-- ---------------------------------------------------------------------------
do $$
declare
  v_doc       uuid := '50500000-0000-4000-8000-000000000001';
  v_doc_ajena uuid := '50500000-0000-4000-8000-000000000002';
  v_asistente uuid := '50500000-0000-4000-8000-000000000003';
  v_admin     uuid := '50500000-0000-4000-8000-000000000004';
  v_paciente  uuid := '50500000-0000-4000-8000-000000000010';
  v_diag      uuid;
  v_trat      uuid;
begin
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    created_at, updated_at, raw_user_meta_data
  ) values
  (v_doc, '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'hfx005-doc@test.local', 'x', now(), now(),
   '{"rol":"doctor","nombre":"Aida","apellido":"Auditoría","fecha_nacimiento":"1980-01-01","cedula":"HFX005-DA","username":"hfx005_da","especialidad":"General"}'),
  (v_doc_ajena, '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'hfx005-ajena@test.local', 'x', now(), now(),
   '{"rol":"doctor","nombre":"Bruna","apellido":"Ajena","fecha_nacimiento":"1981-01-01","cedula":"HFX005-DB","username":"hfx005_db","especialidad":"General"}'),
  (v_asistente, '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'hfx005-asis@test.local', 'x', now(), now(),
   '{"rol":"asistente","nombre":"Clara","apellido":"Recepción","fecha_nacimiento":"1990-01-01","cedula":"HFX005-AS","username":"hfx005_as","turno":"matutino"}'),
  (v_admin, '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'hfx005-admin@test.local', 'x', now(), now(),
   '{"rol":"admin","nombre":"Delia","apellido":"Dirección","fecha_nacimiento":"1975-01-01","cedula":"HFX005-AD","username":"hfx005_ad","especialidad":"General","departamento":"Dirección"}');

  insert into public.personas (id, nombre, apellido, fecha_nacimiento, cedula)
  values (v_paciente, 'Pablo', 'Paciente', date '1990-03-03', '00500000001');
  insert into public.pacientes (id, genero) values (v_paciente, 'masculino');
  insert into public.records (paciente_id, tipo_sangre, cirugias_previas, historial_familiar)
  values (v_paciente, 'o_positivo', '{}', 'Sin antecedentes');

  insert into public.diagnosticos (nombre, severidad_default, alcance, categoria)
  values ('HFX005 caries', 'moderada', 'puntual', 'caries')
  returning id into v_diag;

  insert into public.tratamientos (nombre, costo, alcance)
  values ('HFX005 resina', 1500, 'puntual')
  returning id into v_trat;

  -- Desde HFX-QA-103 el alcance de una asistente son los doctores que asiste
  -- (defecto D12): sin esta asignación no vería —ni podría tocar— la agenda.
  insert into public.doctor_asistentes (doctor_id, asistente_id)
  values (v_doc, v_asistente), (v_doc_ajena, v_asistente);

  perform set_config('hfx005.doc', v_doc::text, true);
  perform set_config('hfx005.doc_ajena', v_doc_ajena::text, true);
  perform set_config('hfx005.asistente', v_asistente::text, true);
  perform set_config('hfx005.admin', v_admin::text, true);
  perform set_config('hfx005.paciente', v_paciente::text, true);
  perform set_config('hfx005.diagnostico', v_diag::text, true);
  perform set_config('hfx005.tratamiento', v_trat::text, true);
end;
$$;

-- ---------------------------------------------------------------------------
-- 1 · La agenda deja rastro antes de que exista la consulta.
-- ---------------------------------------------------------------------------
-- Es la razón por la que `consulta_id` dejó de ser obligatorio: la llegada del
-- paciente es el primer hecho del día y no tiene consulta donde colgarse.
set local role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('hfx005.asistente'), 'role', 'authenticated')::text,
  true
);

do $$
declare
  v_cita  uuid;
  v_base  timestamptz := date_trunc('hour', now()) + interval '1 day';
begin
  insert into public.citas (persona_id, doctor_id, fecha_hora, duracion_minutos, motivo)
  values (current_setting('hfx005.paciente')::uuid,
          current_setting('hfx005.doc')::uuid, v_base, 60, 'Dolor')
  returning id into v_cita;
  perform set_config('hfx005.cita', v_cita::text, true);

  if not exists (
    select 1 from public.auditoria_clinica
     where cita_id = v_cita and evento = 'cita_creada'
       and consulta_id is null
       and rol = 'asistente'
       and actor_id = current_setting('hfx005.asistente')::uuid
  ) then
    raise exception 'crear la cita no dejó evento, o no lo firmó la asistente';
  end if;

  perform public.registrar_llegada_cita(v_cita);

  if not exists (
    select 1 from public.auditoria_clinica
     where cita_id = v_cita and evento = 'cita_llegada'
       and metadata ->> 'estado' = 'en_espera'
  ) then
    raise exception 'la llegada del paciente no quedó auditada';
  end if;

  raise notice 'OK 1 · la cita y la llegada se auditan sin consulta que las ancle';
end;
$$;

-- ---------------------------------------------------------------------------
-- 2 · Reprogramar es un evento distinto de cambiar de estado.
-- ---------------------------------------------------------------------------
-- Sin rol y sin claims: es el contexto de una migración o de un script de
-- mantenimiento, donde no hay nadie a quien atribuirle el cambio.
set local role postgres;
select set_config('request.jwt.claims', '', true);

do $$
declare
  v_cita uuid := current_setting('hfx005.cita')::uuid;
begin
  update public.citas
     set fecha_hora = fecha_hora + interval '2 hours'
   where id = v_cita;

  if not exists (
    select 1 from public.auditoria_clinica
     where cita_id = v_cita and evento = 'cita_reprogramada'
       and (metadata ->> 'cambio_doctor')::boolean = false
  ) then
    raise exception 'mover la hora de la cita no generó cita_reprogramada';
  end if;

  -- Sin sesión el evento no inventa un autor.
  if not exists (
    select 1 from public.auditoria_clinica
     where cita_id = v_cita and evento = 'cita_reprogramada'
       and actor_id is null and rol = 'sistema'
  ) then
    raise exception 'un evento sin sesión se atribuyó a alguien';
  end if;

  raise notice 'OK 2 · reprogramar se distingue del cambio de estado y no inventa autor';
end;
$$;

-- ---------------------------------------------------------------------------
-- 3 · El trabajo clínico de la consulta se audita solo.
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('hfx005.doc'), 'role', 'authenticated')::text,
  true
);

do $$
declare
  v_consulta uuid;
  v_diente   uuid;
  v_inicio   jsonb;
begin
  v_inicio := public.iniciar_consulta_de_cita(
    current_setting('hfx005.cita')::uuid,
    '[{"fdi_code": 36}]'::jsonb
  );
  v_consulta := (v_inicio ->> 'consulta_id')::uuid;
  perform set_config('hfx005.consulta', v_consulta::text, true);

  select d.id into v_diente
    from public.dientes d
    join public.odontogramas o on o.id = d.odontograma_id
   where o.consulta_id = v_consulta
   order by d.fdi_code
   limit 1;

  insert into public.diagnosticos_aplicados (
    diagnosis_id, severidad, consulta_id, diente_id, superficie
  ) values (
    current_setting('hfx005.diagnostico')::uuid, 'moderada', v_consulta,
    v_diente, 'oclusal'
  );

  if not exists (
    select 1 from public.auditoria_clinica
     where consulta_id = v_consulta and evento = 'diagnostico_agregado'
       and metadata ->> 'diagnostico' = 'HFX005 caries'
       and rol = 'doctor'
  ) then
    raise exception 'el diagnóstico no quedó en la línea de tiempo';
  end if;

  update public.diagnosticos_aplicados
     set deleted_at = now()
   where consulta_id = v_consulta;

  if not exists (
    select 1 from public.auditoria_clinica
     where consulta_id = v_consulta and evento = 'diagnostico_retirado'
  ) then
    raise exception 'retirar el diagnóstico no dejó rastro';
  end if;

  insert into public.tratamientos_aplicados (
    tratamiento_id, consulta_id, diente_id, superficie, estado,
    precio_aplicado, doctor_ejecuta_id, fecha_ejecucion
  ) values (
    current_setting('hfx005.tratamiento')::uuid, v_consulta, v_diente,
    'oclusal', 'aplicado', 1500, current_setting('hfx005.doc')::uuid, now()
  );

  if not exists (
    select 1 from public.auditoria_clinica
     where consulta_id = v_consulta and evento = 'tratamiento_ejecutado'
       and (metadata ->> 'planificado')::boolean = false
  ) then
    raise exception 'la ejecución del tratamiento no quedó auditada';
  end if;

  raise notice 'OK 3 · diagnóstico y tratamiento se auditan desde la tabla, no desde la RPC';
end;
$$;

-- ---------------------------------------------------------------------------
-- 4 · El autoguardado se ve una vez por versión, no una vez por campo.
-- ---------------------------------------------------------------------------
do $$
declare
  v_consulta uuid := current_setting('hfx005.consulta')::uuid;
  v_antes    int;
  v_despues  int;
begin
  select count(*) into v_antes
    from public.auditoria_clinica
   where consulta_id = v_consulta and evento = 'consulta_guardada';

  perform public.guardar_borrador_consulta(
    v_consulta, null, jsonb_build_object('notas', 'Primera nota')
  );
  perform public.guardar_borrador_consulta(
    v_consulta, null, jsonb_build_object('notas', 'Segunda nota')
  );

  select count(*) into v_despues
    from public.auditoria_clinica
   where consulta_id = v_consulta and evento = 'consulta_guardada';

  if v_despues - v_antes <> 2 then
    raise exception 'dos guardados produjeron % eventos', v_despues - v_antes;
  end if;

  raise notice 'OK 4 · cada guardado confirmado deja exactamente un evento';
end;
$$;

-- ---------------------------------------------------------------------------
-- 5 · La receta audita el acto médico, no el borrador.
-- ---------------------------------------------------------------------------
set local role postgres;
do $$
declare
  v_consulta uuid := current_setting('hfx005.consulta')::uuid;
  v_receta   uuid;
begin
  insert into public.recetas (
    consulta_id, paciente_id, doctor_id, estado, items_receta, fecha_emision
  ) values (
    v_consulta, current_setting('hfx005.paciente')::uuid,
    current_setting('hfx005.doc')::uuid, 'borrador',
    '[{"nombre_medicamento":"Ibuprofeno"}]'::jsonb, now()
  ) returning id into v_receta;

  if exists (
    select 1 from public.auditoria_clinica
     where consulta_id = v_consulta and evento like 'receta_%'
  ) then
    raise exception 'un borrador de receta ensució la línea de tiempo';
  end if;

  update public.recetas
     set estado = 'emitida', emitida_at = now()
   where id = v_receta;

  if not exists (
    select 1 from public.auditoria_clinica
     where consulta_id = v_consulta and evento = 'receta_emitida'
       and (metadata ->> 'items')::int = 1
  ) then
    raise exception 'emitir la receta no quedó auditado';
  end if;

  update public.recetas
     set estado = 'anulada', motivo_anulacion = 'Dosis equivocada'
   where id = v_receta;

  if not exists (
    select 1 from public.auditoria_clinica
     where consulta_id = v_consulta and evento = 'receta_anulada'
       and metadata ->> 'motivo' = 'Dosis equivocada'
  ) then
    raise exception 'anular la receta no conservó el motivo';
  end if;

  raise notice 'OK 5 · la receta audita emisión y anulación, y el borrador no';
end;
$$;

-- ---------------------------------------------------------------------------
-- 6 · El plan y su consentimiento entran en la misma historia.
-- ---------------------------------------------------------------------------
do $$
declare
  v_consulta uuid := current_setting('hfx005.consulta')::uuid;
  v_plan     uuid;
begin
  insert into public.planes_tratamiento (
    paciente_id, consulta_origen_id, doctor_id, estado
  ) values (
    current_setting('hfx005.paciente')::uuid, v_consulta,
    current_setting('hfx005.doc')::uuid, 'borrador'
  ) returning id into v_plan;
  perform set_config('hfx005.plan', v_plan::text, true);

  update public.planes_tratamiento
     set estado = 'propuesto', fecha_propuesta = now()
   where id = v_plan;

  if not exists (
    select 1 from public.auditoria_clinica
     where consulta_id = v_consulta and evento = 'plan_propuesto'
  ) then
    raise exception 'proponer el plan no dejó evento';
  end if;

  insert into public.consentimientos_plan (
    plan_id, version_plan, decision, items, total_aceptado,
    persona_acepta, relacion_con_paciente, metodo, registrado_por
  ) values (
    v_plan, 1, 'aceptado', '[]'::jsonb, 1500, 'Pablo Paciente',
    'titular', 'firma_fisica', current_setting('hfx005.doc')::uuid
  );

  if not exists (
    select 1 from public.auditoria_clinica
     where consulta_id = v_consulta and evento = 'consentimiento_aceptado'
       and metadata ->> 'metodo' = 'firma_fisica'
  ) then
    raise exception 'el consentimiento no llegó a la línea de tiempo de la consulta';
  end if;

  raise notice 'OK 6 · plan y consentimiento se leen junto al resto de la consulta';
end;
$$;

-- ---------------------------------------------------------------------------
-- 7 · La corrección administrativa aparece sin borrar al autor original.
-- ---------------------------------------------------------------------------
do $$
declare
  v_consulta uuid := current_setting('hfx005.consulta')::uuid;
begin
  insert into public.auditoria_correcciones_clinicas (
    consulta_id, autor_original_id, corregido_por, motivo,
    datos_anteriores, datos_nuevos
  ) values (
    v_consulta, current_setting('hfx005.doc')::uuid,
    current_setting('hfx005.admin')::uuid, 'Pieza equivocada',
    '{"notas":"antes"}'::jsonb, '{"notas":"después"}'::jsonb
  );

  if not exists (
    select 1 from public.auditoria_clinica
     where consulta_id = v_consulta and evento = 'correccion_administrativa'
       and metadata ->> 'motivo' = 'Pieza equivocada'
       and (metadata ->> 'autor_original_id')::uuid = current_setting('hfx005.doc')::uuid
  ) then
    raise exception 'la corrección administrativa no entró en la línea de tiempo';
  end if;

  raise notice 'OK 7 · la corrección se ve y conserva al autor original';
end;
$$;

-- ---------------------------------------------------------------------------
-- 8 · La línea de tiempo se lee completa, en orden y con nombres.
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('hfx005.doc'), 'role', 'authenticated')::text,
  true
);

do $$
declare
  v_consulta uuid := current_setting('hfx005.consulta')::uuid;
  v_eventos  text[];
  v_previo   timestamptz := '-infinity';
  v_fila     record;
begin
  select array_agg(evento) into v_eventos
    from public.linea_tiempo_consulta(v_consulta);

  -- La historia empieza en la agenda y no en la consulta.
  if not (v_eventos @> array['cita_creada', 'cita_llegada', 'consulta_iniciada',
                             'diagnostico_agregado', 'diagnostico_retirado',
                             'tratamiento_ejecutado', 'consulta_guardada',
                             'receta_emitida', 'receta_anulada',
                             'plan_propuesto', 'consentimiento_aceptado',
                             'correccion_administrativa']) then
    raise exception 'faltan eventos en la línea de tiempo: %', v_eventos;
  end if;

  for v_fila in select * from public.linea_tiempo_consulta(v_consulta) loop
    if v_fila.ocurrido_en < v_previo then
      raise exception 'la línea de tiempo no está en orden cronológico';
    end if;
    v_previo := v_fila.ocurrido_en;

    if v_fila.evento = 'diagnostico_agregado' then
      if v_fila.actor_nombre <> 'Aida Auditoría' then
        raise exception 'el actor no se resolvió a un nombre legible: %', v_fila.actor_nombre;
      end if;
      if v_fila.categoria <> 'clinico' then
        raise exception 'categoría inesperada: %', v_fila.categoria;
      end if;
    end if;

    if v_fila.evento = 'correccion_administrativa'
       and v_fila.motivo <> 'Pieza equivocada' then
      raise exception 'la corrección perdió su motivo en la línea de tiempo';
    end if;
  end loop;

  raise notice 'OK 8 · la línea de tiempo es completa, cronológica y legible';
end;
$$;

-- ---------------------------------------------------------------------------
-- 9 · La historia clínica ajena — alcance TEMPORAL de la decisión D11.
-- ---------------------------------------------------------------------------
-- TEMPORAL (QA 1-ago-2026): la clínica decidió que, por ahora, cualquier
-- doctor lee cualquier consulta. Antes esta prueba afirmaba lo contrario y era
-- correcta; se invierte junto con la policy `consulta_select` y
-- `puede_ver_consulta`, y las tres se revierten a la vez cuando llegue el
-- modelo definitivo de alcance clínico.
--
-- Lo que NO cambia y esta prueba sigue fijando: leer no es escribir. La doctora
-- ajena ve la línea de tiempo, pero no puede firmar nada sobre esa consulta.
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('hfx005.doc_ajena'), 'role', 'authenticated')::text,
  true
);

do $$
declare
  v_consulta uuid := current_setting('hfx005.consulta')::uuid;
begin
  perform public.linea_tiempo_consulta(v_consulta);

  if not exists (select 1 from public.auditoria_clinica where consulta_id = v_consulta) then
    raise exception
      'la doctora ajena no vio los eventos: la decisión D11 abre la LECTURA a todo doctor';
  end if;

  -- El límite sigue en pie: mirar no es firmar.
  begin
    update public.consultas set notas = 'intruso' where id = v_consulta;
    if found then
      raise exception 'una doctora ajena escribió sobre una consulta que no es suya';
    end if;
  exception when insufficient_privilege or check_violation then null;
  end;

  raise notice 'OK 9 · D11 (TEMPORAL): el doctor lee cualquier consulta, pero sólo firma la suya';
end;
$$;

-- ---------------------------------------------------------------------------
-- 10 · Anon no toca la auditoría.
-- ---------------------------------------------------------------------------
-- El grant se comprueba en el catálogo y no llamando a la función, como en
-- HFX-CLIN-001. No es pereza: en la imagen local de Supabase, una sesión
-- superusuario que hace `set local role anon` y llama a una función sin
-- privilegio tumba el backend con SIGSEGV en vez de devolver 42501. Por REST
-- —el camino real de PostgREST— la misma llamada responde 401 y la base sigue
-- viva, así que es una trampa del arnés de pruebas y no un agujero del
-- producto. Reproducirla aquí sólo serviría para dejar la suite inservible.
do $$
begin
  if has_function_privilege('anon', 'public.linea_tiempo_consulta(uuid)', 'execute') then
    raise exception 'anon puede ejecutar la línea de tiempo';
  end if;
  if has_function_privilege('anon', 'public.hfx_clin_005_registrar_evento(text, uuid, uuid, jsonb)', 'execute') then
    raise exception 'anon puede escribir eventos de auditoría';
  end if;
  if has_table_privilege('anon', 'public.auditoria_clinica', 'select')
     or has_table_privilege('anon', 'public.auditoria_clinica', 'insert') then
    raise exception 'anon alcanza la tabla de auditoría';
  end if;

  raise notice 'OK 10 · anon no lee ni escribe la auditoría por ninguna vía';
end;
$$;

-- ---------------------------------------------------------------------------
-- 11 · Escribir un evento no es una capacidad del cliente.
-- ---------------------------------------------------------------------------
-- Una auditoría que el auditado puede escribir a mano no audita nada.
do $$
begin
  if has_function_privilege('authenticated', 'public.hfx_clin_005_registrar_evento(text, uuid, uuid, jsonb)', 'execute') then
    raise exception 'un usuario autenticado puede fabricar eventos de auditoría';
  end if;
  if has_table_privilege('authenticated', 'public.auditoria_clinica', 'insert')
     or has_table_privilege('authenticated', 'public.auditoria_clinica', 'update')
     or has_table_privilege('authenticated', 'public.auditoria_clinica', 'delete') then
    raise exception 'un usuario autenticado puede alterar la auditoría';
  end if;

  raise notice 'OK 11 · la auditoría sólo la escriben los triggers';
end;
$$;

rollback;
