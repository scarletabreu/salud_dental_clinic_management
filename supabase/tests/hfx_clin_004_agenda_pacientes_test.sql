-- HFX-CLIN-004 · agenda, pacientes y continuidad operativa.
-- Se ejecuta tras `supabase db reset` y revierte todos sus datos.
--
--   psql "$DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/hfx_clin_004_agenda_pacientes_test.sql

begin;
set local role postgres;

-- ---------------------------------------------------------------------------
-- 0 · Escenario: dos doctoras, una asistente, un paciente con expediente.
-- ---------------------------------------------------------------------------
do $$
declare
  v_doc_a      uuid := '50000000-0000-4000-8000-000000000001';
  v_doc_b      uuid := '50000000-0000-4000-8000-000000000002';
  v_asistente  uuid := '50000000-0000-4000-8000-000000000003';
  v_paciente   uuid := '50000000-0000-4000-8000-000000000010';
  v_condicion  uuid;
begin
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    created_at, updated_at, raw_user_meta_data
  ) values
  (v_doc_a, '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'hfx004-doca@test.local', 'x', now(), now(),
   '{"rol":"doctor","nombre":"Ana","apellido":"Agenda","fecha_nacimiento":"1980-01-01","cedula":"HFX004-DA","username":"hfx004_da","especialidad":"General"}'),
  (v_doc_b, '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'hfx004-docb@test.local', 'x', now(), now(),
   '{"rol":"doctor","nombre":"Berta","apellido":"Bloque","fecha_nacimiento":"1981-01-01","cedula":"HFX004-DB","username":"hfx004_db","especialidad":"General"}'),
  (v_asistente, '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'hfx004-asis@test.local', 'x', now(), now(),
   '{"rol":"asistente","nombre":"Carla","apellido":"Recepción","fecha_nacimiento":"1990-01-01","cedula":"HFX004-AS","username":"hfx004_as","turno":"matutino"}');

  insert into public.personas (id, nombre, apellido, fecha_nacimiento, cedula)
  values (v_paciente, 'Pedro', 'Paciente', date '1990-03-03', '00100000001');
  insert into public.pacientes (id, genero) values (v_paciente, 'masculino');
  insert into public.records (paciente_id, tipo_sangre, cirugias_previas, historial_familiar)
  values (v_paciente, 'o_positivo', '{}', 'Sin antecedentes');

  insert into public.condiciones (nombre, tipo, categoria)
  values ('HFX004 condición', 'patologica', 'cronica')
  returning id into v_condicion;

  perform set_config('hfx004.doc_a', v_doc_a::text, true);
  perform set_config('hfx004.doc_b', v_doc_b::text, true);
  perform set_config('hfx004.asistente', v_asistente::text, true);
  perform set_config('hfx004.paciente', v_paciente::text, true);
  perform set_config('hfx004.condicion', v_condicion::text, true);
end;
$$;

-- ---------------------------------------------------------------------------
-- 1 · La base rechaza el intervalo solapado y acepta el consecutivo.
-- ---------------------------------------------------------------------------
do $$
declare
  v_doc      uuid := current_setting('hfx004.doc_a')::uuid;
  v_paciente uuid := current_setting('hfx004.paciente')::uuid;
  v_base     timestamptz := date_trunc('hour', now()) + interval '1 day';
  v_cita     uuid;
begin
  insert into public.citas (persona_id, doctor_id, fecha_hora, duracion_minutos)
  values (v_paciente, v_doc, v_base, 60)
  returning id into v_cita;
  perform set_config('hfx004.cita_base', v_cita::text, true);
  perform set_config('hfx004.base', v_base::text, true);

  -- 09:15 sobre una cita de 09:00 a 10:00.
  begin
    insert into public.citas (persona_id, doctor_id, fecha_hora, duracion_minutos)
    values (v_paciente, v_doc, v_base + interval '15 minutes', 60);
    raise exception 'la base aceptó dos citas solapadas del mismo doctor';
  exception when exclusion_violation then null;
  end;

  -- Consecutiva exacta: el rango es semiabierto, así que 10:00 no cruza.
  insert into public.citas (persona_id, doctor_id, fecha_hora, duracion_minutos)
  values (v_paciente, v_doc, v_base + interval '60 minutes', 30);

  -- Otro doctor puede ocupar el mismo intervalo.
  insert into public.citas (persona_id, doctor_id, fecha_hora, duracion_minutos)
  values (v_paciente, current_setting('hfx004.doc_b')::uuid, v_base, 60);

  raise notice 'OK 1 · el solapamiento se rechaza, lo consecutivo y lo de otro doctor se acepta';
end;
$$;

-- ---------------------------------------------------------------------------
-- 2 · Sin duración explícita la cita ocupa 30 minutos, no cero.
-- ---------------------------------------------------------------------------
do $$
declare
  v_doc   uuid := current_setting('hfx004.doc_b')::uuid;
  v_base  timestamptz := current_setting('hfx004.base')::timestamptz;
  v_cita  uuid;
  v_fin   timestamptz;
begin
  insert into public.citas (persona_id, doctor_id, fecha_hora)
  values (current_setting('hfx004.paciente')::uuid, v_doc, v_base + interval '3 hours')
  returning id, fin into v_cita, v_fin;

  if v_fin <> v_base + interval '3 hours' + interval '30 minutes' then
    raise exception 'una cita sin duración no ocupó los 30 minutos por defecto: %', v_fin;
  end if;

  begin
    insert into public.citas (persona_id, doctor_id, fecha_hora, duracion_minutos)
    values (current_setting('hfx004.paciente')::uuid, v_doc, v_base + interval '3 hours', 0);
    raise exception 'la base aceptó una cita de duración cero';
  exception when check_violation then null;
  end;

  delete from public.citas where id = v_cita;
  raise notice 'OK 2 · la duración es obligatoria, positiva y con respaldo de 30 minutos';
end;
$$;

-- ---------------------------------------------------------------------------
-- 3 · Cancelar, eliminar o cambiar de doctor libera el intervalo.
-- ---------------------------------------------------------------------------
do $$
declare
  v_doc      uuid := current_setting('hfx004.doc_a')::uuid;
  v_doc_b    uuid := current_setting('hfx004.doc_b')::uuid;
  v_paciente uuid := current_setting('hfx004.paciente')::uuid;
  v_base     timestamptz := current_setting('hfx004.base')::timestamptz + interval '5 hours';
  v_cita     uuid;
  v_otra     uuid;
begin
  insert into public.citas (persona_id, doctor_id, fecha_hora, duracion_minutos)
  values (v_paciente, v_doc, v_base, 60)
  returning id into v_cita;

  update public.citas set estado = 'cancelada' where id = v_cita;

  -- Liberado el intervalo, la reprogramación entra donde antes chocaba.
  insert into public.citas (persona_id, doctor_id, fecha_hora, duracion_minutos)
  values (v_paciente, v_doc, v_base + interval '15 minutes', 30)
  returning id into v_otra;

  -- La cita de doc_b vive a la hora base; mover esta allí debe rechazarse.
  begin
    update public.citas
       set doctor_id = v_doc_b,
           fecha_hora = current_setting('hfx004.base')::timestamptz
     where id = v_otra;
    raise exception 'cambiar de doctor esquivó la restricción de solapamiento';
  exception when exclusion_violation then null;
  end;

  delete from public.citas where id = v_otra;
  raise notice 'OK 3 · cancelación libera el hueco y el cambio de doctor se revalida';
end;
$$;

-- ---------------------------------------------------------------------------
-- 4 · La emergencia interrumpe la agenda: no la reserva ni la bloquea.
-- ---------------------------------------------------------------------------
do $$
declare
  v_resultado jsonb;
  v_cita      uuid;
begin
  v_resultado := public.registrar_cita_emergencia(
    current_setting('hfx004.paciente')::uuid,
    current_setting('hfx004.doc_a')::uuid,
    'Dolor agudo'
  );
  v_cita := (v_resultado ->> 'cita_id')::uuid;

  if not exists (
    select 1 from public.citas
     where id = v_cita and es_emergencia and estado = 'en_espera'
  ) then
    raise exception 'la emergencia no quedó marcada ni en espera';
  end if;

  -- Una segunda urgencia en el mismo minuto tampoco puede bloquearse.
  perform public.registrar_cita_emergencia(
    current_setting('hfx004.paciente')::uuid,
    current_setting('hfx004.doc_a')::uuid,
    'Segunda urgencia'
  );

  perform set_config('hfx004.cita_emergencia', v_cita::text, true);
  raise notice 'OK 4 · la urgencia se registra en espera y queda fuera de la exclusión';
end;
$$;

-- ---------------------------------------------------------------------------
-- 5 · El ciclo de vida de la cita se valida en la base.
-- ---------------------------------------------------------------------------
do $$
declare
  v_cita uuid := current_setting('hfx004.cita_base')::uuid;
begin
  begin
    update public.citas set estado = 'completada' where id = v_cita;
    raise exception 'la base aceptó saltar de programada a completada';
  exception when others then
    if sqlstate <> 'CL016' then raise; end if;
  end;

  update public.citas set estado = 'confirmada' where id = v_cita;
  update public.citas set estado = 'en_espera' where id = v_cita;

  begin
    update public.citas set estado = 'programada' where id = v_cita;
    raise exception 'la base aceptó retroceder de en_espera a programada';
  exception when others then
    if sqlstate <> 'CL016' then raise; end if;
  end;

  raise notice 'OK 5 · el grafo de estados de la cita lo impone PostgreSQL';
end;
$$;

-- ---------------------------------------------------------------------------
-- 6 · Iniciar la consulta crea una sola vez y luego reanuda.
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('hfx004.doc_a'), 'role', 'authenticated')::text,
  true
);

do $$
declare
  v_cita     uuid := current_setting('hfx004.cita_base')::uuid;
  v_primero  jsonb;
  v_segundo  jsonb;
begin
  v_primero := public.iniciar_consulta_de_cita(v_cita);
  if v_primero ->> 'estado' <> 'creada' then
    raise exception 'el primer inicio no creó la consulta: %', v_primero;
  end if;
  if (select estado from public.citas where id = v_cita) <> 'en_consulta' then
    raise exception 'la cita no pasó a en_consulta dentro de la misma transacción';
  end if;

  v_segundo := public.iniciar_consulta_de_cita(v_cita);
  if v_segundo ->> 'estado' <> 'reanudada' then
    raise exception 'el reintento no reanudó: %', v_segundo;
  end if;
  if v_segundo ->> 'consulta_id' <> v_primero ->> 'consulta_id' then
    raise exception 'el reintento creó una consulta distinta';
  end if;
  if (select count(*) from public.consultas where cita_id = v_cita) <> 1 then
    raise exception 'la cita terminó con más de una consulta';
  end if;

  perform set_config('hfx004.consulta', v_primero ->> 'consulta_id', true);
  raise notice 'OK 6 · iniciar es idempotente: crea una vez y después reanuda';
end;
$$;

-- ---------------------------------------------------------------------------
-- 7 · Nadie firma la consulta de otro doctor.
-- ---------------------------------------------------------------------------
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('hfx004.doc_b'), 'role', 'authenticated')::text,
  true
);

do $$
begin
  begin
    perform public.iniciar_consulta_de_cita(current_setting('hfx004.cita_base')::uuid);
    raise exception 'una doctora ajena inició la consulta de otra';
  exception when insufficient_privilege then null;
  end;
  raise notice 'OK 7 · la cita solo la atiende el doctor asignado';
end;
$$;

-- ---------------------------------------------------------------------------
-- 8 · Una consulta ya finalizada se consulta, no se reabre.
-- ---------------------------------------------------------------------------
set local role postgres;
do $$
declare
  v_consulta uuid := current_setting('hfx004.consulta')::uuid;
  v_cita     uuid := current_setting('hfx004.cita_base')::uuid;
  v_resultado jsonb;
begin
  update public.consultas
     set finalizada = true, finalizada_at = now()
   where id = v_consulta;
  update public.citas set estado = 'completada' where id = v_cita;

  v_resultado := public.iniciar_consulta_de_cita(v_cita);
  if v_resultado ->> 'estado' <> 'finalizada' then
    raise exception 'una cita atendida no se señaló como finalizada: %', v_resultado;
  end if;
  if v_resultado ->> 'consulta_id' <> v_consulta::text then
    raise exception 'se devolvió una consulta distinta a la ya cerrada';
  end if;
  raise notice 'OK 8 · la cita atendida devuelve su consulta cerrada en vez de abrir otra';
end;
$$;

-- ---------------------------------------------------------------------------
-- 9 · Una cita cancelada no admite consulta.
-- ---------------------------------------------------------------------------
do $$
declare
  v_cita uuid;
begin
  insert into public.citas (persona_id, doctor_id, fecha_hora, duracion_minutos, estado)
  values (
    current_setting('hfx004.paciente')::uuid,
    current_setting('hfx004.doc_a')::uuid,
    current_setting('hfx004.base')::timestamptz + interval '8 hours',
    30, 'cancelada'
  )
  returning id into v_cita;

  begin
    perform public.iniciar_consulta_de_cita(v_cita);
    raise exception 'se abrió una consulta sobre una cita cancelada';
  exception when others then
    if sqlstate <> 'CL015' then raise; end if;
  end;

  -- Y sin llegada registrada tampoco: nadie puede afirmar que el paciente está.
  insert into public.citas (persona_id, doctor_id, fecha_hora, duracion_minutos, estado)
  values (
    current_setting('hfx004.paciente')::uuid,
    current_setting('hfx004.doc_a')::uuid,
    current_setting('hfx004.base')::timestamptz + interval '9 hours',
    30, 'confirmada'
  )
  returning id into v_cita;

  begin
    perform public.iniciar_consulta_de_cita(v_cita);
    raise exception 'se abrió una consulta sin registrar la llegada del paciente';
  exception when others then
    if sqlstate <> 'CL015' then raise; end if;
  end;

  raise notice 'OK 9 · ni una cita cancelada ni una sin llegada abren consulta';
end;
$$;

-- ---------------------------------------------------------------------------
-- 10 · Alta de paciente: todo o nada.
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('hfx004.asistente'), 'role', 'authenticated')::text,
  true
);

do $$
declare
  v_resultado jsonb;
  v_nuevo     uuid;
begin
  v_resultado := public.registrar_paciente(jsonb_build_object(
    'nombre', 'Nueva', 'apellido', 'Paciente',
    'fecha_nacimiento', '1995-07-07',
    'cedula', '402-1234567-8',
    'genero', 'femenino',
    'contactos', jsonb_build_array(
      jsonb_build_object(
        'numero_telefono', '(809) 555-1234',
        'email', '  Nueva.Paciente@Correo.COM '
      ),
      jsonb_build_object('numero_telefono', '809-555-4321', 'es_emergencia', true)
    ),
    'record', jsonb_build_object('tipo_sangre', 'a_positivo'),
    'condiciones', jsonb_build_array(
      jsonb_build_object('condicion_id', current_setting('hfx004.condicion'))
    )
  ));
  v_nuevo := (v_resultado ->> 'paciente_id')::uuid;
  perform set_config('hfx004.paciente_nuevo', v_nuevo::text, true);
  raise notice 'OK 10a · una asistente puede dar de alta al paciente completo';
end;
$$;

-- El expediente y sus condiciones son clínicos: la asistente que acaba de
-- crearlos no puede leerlos (RLS de HFX-CLIN-001), así que la comprobación
-- estructural se hace desde dentro.
set local role postgres;
do $$
declare
  v_nuevo     uuid := current_setting('hfx004.paciente_nuevo')::uuid;
  v_personas  integer;
  v_contactos integer;
begin
  if not exists (select 1 from public.pacientes where id = v_nuevo) then
    raise exception 'el alta no creó la ficha del paciente';
  end if;
  if not exists (select 1 from public.records where paciente_id = v_nuevo) then
    raise exception 'el alta no creó el expediente';
  end if;
  if not exists (
    select 1 from public.record_condicion rc
      join public.records r on r.id = rc.record_id
     where r.paciente_id = v_nuevo
  ) then
    raise exception 'el alta no registró las condiciones iniciales';
  end if;
  if not exists (
    select 1 from public.persona_contactos pc
      join public.contactos c on c.id = pc.contacto_id
     where pc.persona_id = v_nuevo
       and pc.es_principal
       and c.numero_telefono = '8095551234'
       and c.email = 'nueva.paciente@correo.com'
  ) then
    raise exception 'el contacto principal no se normalizó ni se enlazó';
  end if;

  -- Un alta que falla no puede dejar rastro: misma cédula, otra persona.
  select count(*) into v_personas from public.personas;
  select count(*) into v_contactos from public.contactos;
  begin
    perform public.registrar_paciente(jsonb_build_object(
      'nombre', 'Duplicada', 'apellido', 'Cédula',
      'fecha_nacimiento', '1991-01-01',
      'cedula', '40212345678',
      'contactos', jsonb_build_array(
        jsonb_build_object('numero_telefono', '8090000000')
      )
    ));
    raise exception 'se aceptó una segunda ficha con la misma cédula';
  exception when others then
    if sqlstate <> 'CL017' then raise; end if;
  end;
  if (select count(*) from public.personas) <> v_personas
     or (select count(*) from public.contactos) <> v_contactos then
    raise exception 'el alta fallida dejó personas o contactos huérfanos';
  end if;

  raise notice 'OK 10 · el alta es una transacción única y su fallo no deja huérfanos';
end;
$$;

-- ---------------------------------------------------------------------------
-- 11 · Actualizar con versión vencida no pisa la ficha ajena.
-- ---------------------------------------------------------------------------
do $$
declare
  v_paciente uuid := current_setting('hfx004.paciente_nuevo')::uuid;
  v_res      jsonb;
begin
  v_res := public.actualizar_paciente(v_paciente, 1, jsonb_build_object(
    'trabajo', 'Docente',
    'contactos', jsonb_build_array(
      jsonb_build_object(
        'id', (select pc.contacto_id from public.persona_contactos pc
                where pc.persona_id = v_paciente and pc.es_principal limit 1),
        'numero_telefono', '809-555-9999'
      )
    )
  ));
  if (v_res ->> 'version')::integer <> 2 then
    raise exception 'la actualización no incrementó la versión: %', v_res;
  end if;

  begin
    perform public.actualizar_paciente(v_paciente, 1, jsonb_build_object('trabajo', 'Otro'));
    raise exception 'una edición con versión vencida sobrescribió la ficha';
  exception when others then
    if sqlstate <> 'CL019' then raise; end if;
  end;

  if (select trabajo from public.pacientes where id = v_paciente) <> 'Docente' then
    raise exception 'la edición rechazada dejó la ficha a medias';
  end if;
  if (select count(*) from public.persona_contactos where persona_id = v_paciente) <> 2 then
    raise exception 'actualizar el teléfono alteró el número de contactos de la ficha';
  end if;
  if not exists (
    select 1 from public.persona_contactos pc
      join public.contactos c on c.id = pc.contacto_id
     where pc.persona_id = v_paciente and pc.es_principal
       and c.numero_telefono = '8095559999'
  ) then
    raise exception 'el teléfono principal no se actualizó en su sitio';
  end if;

  raise notice 'OK 11 · la actualización es transaccional y respeta la versión';
end;
$$;

-- ---------------------------------------------------------------------------
-- 12 · La llegada la registra el doctor de la cita, no solo recepción.
-- ---------------------------------------------------------------------------
set local role postgres;
do $$
declare
  v_cita uuid;
begin
  insert into public.citas (persona_id, doctor_id, fecha_hora, duracion_minutos, estado)
  values (
    current_setting('hfx004.paciente')::uuid,
    current_setting('hfx004.doc_a')::uuid,
    current_setting('hfx004.base')::timestamptz + interval '10 hours',
    30, 'confirmada'
  )
  returning id into v_cita;
  perform set_config('hfx004.cita_llegada', v_cita::text, true);
end;
$$;

set local role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('hfx004.doc_a'), 'role', 'authenticated')::text,
  true
);

do $$
declare
  v_cita uuid := current_setting('hfx004.cita_llegada')::uuid;
  v_res  jsonb;
begin
  v_res := public.registrar_llegada_cita(v_cita);
  if (v_res ->> 'ya_registrada')::boolean then
    raise exception 'la primera llegada se reportó como repetida';
  end if;
  if (select estado from public.citas where id = v_cita) <> 'en_espera' then
    raise exception 'la llegada no dejó la cita en espera';
  end if;

  -- Repetirla no es un error: el paciente ya está.
  v_res := public.registrar_llegada_cita(v_cita);
  if not (v_res ->> 'ya_registrada')::boolean then
    raise exception 'registrar la llegada dos veces no fue idempotente';
  end if;

  raise notice 'OK 12 · el doctor registra la llegada de su cita y repetirlo es inocuo';
end;
$$;

-- ---------------------------------------------------------------------------
-- 13 · Un doctor no toca la llegada de una cita ajena.
-- ---------------------------------------------------------------------------
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('hfx004.doc_b'), 'role', 'authenticated')::text,
  true
);

do $$
begin
  begin
    perform public.registrar_llegada_cita(current_setting('hfx004.cita_llegada')::uuid);
    raise exception 'un doctor registró la llegada de una cita ajena';
  exception when insufficient_privilege then null;
  end;
  raise notice 'OK 13 · la llegada ajena queda fuera del alcance del doctor';
end;
$$;

rollback;
