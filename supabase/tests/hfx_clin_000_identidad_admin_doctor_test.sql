-- HFX-CLIN-000 · Prueba funcional de la identidad admin-doctor y del contrato
-- de perfil.
--
-- Se ejecuta sobre una base reconstruida con `supabase db reset`. Todo ocurre
-- dentro de una transacción que termina en ROLLBACK: no deja rastro, ni
-- siquiera los usuarios de Auth que crea.
--
--   psql -h 127.0.0.1 -p 54322 -U postgres -d postgres -v ON_ERROR_STOP=1 \
--        -f supabase/tests/hfx_clin_000_identidad_admin_doctor_test.sql
--
-- Cubre lo que hasta hoy no comprobaba nadie y por eso el login se caía en
-- cuanto la base no era la instancia de siempre:
--
--   1. Dar de alta un admin crea las tres identidades (usuarios, doctores,
--      admins) con el mismo UUID que emitió Auth.
--   2. Un doctor crea usuarios + doctores, y no entra en admins.
--   3. Un asistente crea usuarios + asistentes, y no obtiene identidad clínica.
--   4. Un alta incompleta o con rol inválido se rechaza entera: no deja
--      persona a medias ni un usuario capaz de autenticarse sin perfil.
--   5. La FK admins.id -> doctores.id impide volver a tener un admin huérfano.
--   6. `perfil_actual()` resuelve el perfil de cada rol, sólo el de la propia
--      sesión, y no existe ninguna columna de contraseña en su contrato.
--   7. El admin aparece en `get_active_doctors()` y puede recibir una cita y
--      firmar una consulta con su propio UUID.
--   8. `anon` no puede ejecutar ninguna de las dos funciones.

begin;

set local role postgres;

-- ---------------------------------------------------------------------------
-- Montaje: tres altas por el mismo camino que usa la Edge Function, es decir
-- insertando en auth.users y dejando que el trigger aprovisione el perfil.
-- ---------------------------------------------------------------------------
do $$
declare
  v_admin_id     uuid := gen_random_uuid();
  v_doctor_id    uuid := gen_random_uuid();
  v_asistente_id uuid := gen_random_uuid();
  v_conteo       integer;
  v_texto        text;
  v_ok           boolean;
begin
  perform set_config('hfx.admin_id',     v_admin_id::text,     true);
  perform set_config('hfx.doctor_id',    v_doctor_id::text,    true);
  perform set_config('hfx.asistente_id', v_asistente_id::text, true);

  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    created_at, updated_at, raw_user_meta_data
  ) values (
    v_admin_id, '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated', 'hfx-admin@test.local', 'x',
    now(), now(),
    jsonb_build_object(
      'rol', 'admin', 'nombre', 'Ada', 'apellido', 'Directora',
      'fecha_nacimiento', '1980-01-01', 'cedula', 'HFX000-ADM',
      'username', 'hfx_admin', 'departamento', 'Dirección',
      'especialidad', 'Ortodoncia', 'telefono', '809-000-0001'
    )
  );

  -- 1. Las tres identidades, con el UUID que emitió Auth.
  select count(*) into v_conteo from usuarios where id = v_admin_id;
  if v_conteo <> 1 then raise exception 'Caso 1: el admin no tiene fila en usuarios.'; end if;

  select count(*) into v_conteo from doctores where id = v_admin_id;
  if v_conteo <> 1 then
    raise exception 'Caso 1: el admin no tiene identidad clínica. Un admin es un doctor.';
  end if;

  select count(*) into v_conteo from admins where id = v_admin_id;
  if v_conteo <> 1 then raise exception 'Caso 1: el admin no tiene fila en admins.'; end if;

  select count(*) into v_conteo from personas where id = v_admin_id;
  if v_conteo <> 1 then
    raise exception 'Caso 1: personas.id no coincide con auth.uid(). RLS compara ese UUID.';
  end if;

  select especialidad into v_texto from doctores where id = v_admin_id;
  if v_texto <> 'Ortodoncia' then
    raise exception 'Caso 1: la especialidad del metadata no llegó a doctores (llegó "%").', v_texto;
  end if;

  select ct.numero_telefono into v_texto
    from persona_contactos pc join contactos ct on ct.id = pc.contacto_id
   where pc.persona_id = v_admin_id and pc.es_principal;
  if v_texto is distinct from '809-000-0001' then
    raise exception 'Caso 1: el teléfono del metadata no creó su contacto principal.';
  end if;

  raise notice 'OK 1 · el alta de admin crea usuarios + doctores + admins con el UUID de Auth';

  -- 2. Doctor: identidad clínica, sin capacidades administrativas.
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    created_at, updated_at, raw_user_meta_data
  ) values (
    v_doctor_id, '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated', 'hfx-doctor@test.local', 'x',
    now(), now(),
    jsonb_build_object(
      'rol', 'doctor', 'nombre', 'Beto', 'apellido', 'Clínico',
      'fecha_nacimiento', '1985-02-02', 'cedula', 'HFX000-DOC',
      'username', 'hfx_doctor', 'especialidad', 'Endodoncia'
    )
  );

  select count(*) into v_conteo from doctores where id = v_doctor_id;
  if v_conteo <> 1 then raise exception 'Caso 2: el doctor no tiene fila en doctores.'; end if;
  select count(*) into v_conteo from admins where id = v_doctor_id;
  if v_conteo <> 0 then raise exception 'Caso 2: un doctor no debe entrar en admins.'; end if;

  raise notice 'OK 2 · el alta de doctor crea usuarios + doctores y nada más';

  -- 3. Asistente: ninguna capacidad clínica.
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    created_at, updated_at, raw_user_meta_data
  ) values (
    v_asistente_id, '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated', 'hfx-asistente@test.local', 'x',
    now(), now(),
    jsonb_build_object(
      'rol', 'asistente', 'nombre', 'Cami', 'apellido', 'Recepción',
      'fecha_nacimiento', '1998-03-03', 'cedula', 'HFX000-ASI',
      'username', 'hfx_asistente', 'turno', 'matutino'
    )
  );

  select count(*) into v_conteo from asistentes where id = v_asistente_id;
  if v_conteo <> 1 then raise exception 'Caso 3: el asistente no tiene fila en asistentes.'; end if;
  select count(*) into v_conteo from doctores where id = v_asistente_id;
  if v_conteo <> 0 then
    raise exception 'Caso 3: un asistente no puede tener identidad clínica.';
  end if;

  raise notice 'OK 3 · el alta de asistente no otorga identidad clínica';

  -- 4. Altas inválidas: el trigger aborta el INSERT de Auth entero.
  begin
    insert into auth.users (
      id, instance_id, aud, role, email, encrypted_password,
      created_at, updated_at, raw_user_meta_data
    ) values (
      gen_random_uuid(), '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated', 'hfx-sinrol@test.local', 'x',
      now(), now(),
      jsonb_build_object('nombre', 'Sin', 'apellido', 'Rol')
    );
    raise exception 'Caso 4: un alta sin rol debería rechazarse.';
  exception when sqlstate 'P0001' then
    null;  -- esperado
  end;

  begin
    insert into auth.users (
      id, instance_id, aud, role, email, encrypted_password,
      created_at, updated_at, raw_user_meta_data
    ) values (
      gen_random_uuid(), '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated', 'hfx-incompleto@test.local', 'x',
      now(), now(),
      jsonb_build_object('rol', 'doctor', 'nombre', 'Falta', 'apellido', 'Cédula',
                         'username', 'hfx_incompleto')
    );
    raise exception 'Caso 4: un alta sin cédula ni fecha de nacimiento debería rechazarse.';
  exception when sqlstate 'P0001' then
    null;  -- esperado
  end;

  select count(*) into v_conteo from personas
   where cedula in ('HFX000-SINROL') or nombre in ('Sin', 'Falta');
  if v_conteo <> 0 then
    raise exception 'Caso 4: un alta rechazada dejó persona a medias.';
  end if;

  select count(*) into v_conteo from auth.users
   where email in ('hfx-sinrol@test.local', 'hfx-incompleto@test.local');
  if v_conteo <> 0 then
    raise exception 'Caso 4: quedó un usuario capaz de autenticarse sin perfil operativo.';
  end if;

  raise notice 'OK 4 · un alta inválida se revierte entera, sin usuario huérfano';

  -- 5. La FK cierra la puerta a un admin sin identidad clínica.
  begin
    insert into admins (id, departamento)
    values (v_asistente_id, 'Contabilidad');
    raise exception 'Caso 5: se pudo crear un admin sin fila en doctores.';
  exception when foreign_key_violation then
    null;  -- esperado
  end;

  select count(*) into v_conteo
    from admins a left join doctores d on d.id = a.id
   where d.id is null;
  if v_conteo <> 0 then
    raise exception 'Caso 5: hay % admin(s) sin identidad clínica.', v_conteo;
  end if;

  raise notice 'OK 5 · la FK admins.id -> doctores.id impide el admin huérfano';
end;
$$;

-- ---------------------------------------------------------------------------
-- 6. El contrato del perfil. Se comprueba primero sobre el catálogo: si
--    `password_hash` no está en la firma, no hay forma de que llegue al
--    navegador por esta vía.
-- ---------------------------------------------------------------------------
do $$
declare
  v_args text;
begin
  select pg_get_function_result(p.oid) into v_args
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'perfil_actual';
  if v_args is null then raise exception 'Caso 6: no existe perfil_actual().'; end if;
  if v_args ilike '%password%' then
    raise exception 'Caso 6: perfil_actual() devuelve una columna de contraseña.';
  end if;

  select pg_get_function_result(p.oid) into v_args
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'get_active_doctors';
  if v_args is null then
    raise exception 'Caso 6: get_active_doctors() no existe en una base reconstruida.';
  end if;
  if v_args ilike '%password%' then
    raise exception 'Caso 6: get_active_doctors() sigue devolviendo password_hash.';
  end if;

  raise notice 'OK 6a · perfil_actual() y get_active_doctors() existen y no exponen contraseñas';
end;
$$;

-- El perfil se resuelve con la sesión, no con un parámetro: cada rol ve el
-- suyo y sólo el suyo.
do $$
declare
  v_rol    text;
  v_dep    text;
  v_esp    text;
  v_turno  text;
  v_id     uuid;
  v_conteo integer;
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', current_setting('hfx.admin_id'), 'role', 'authenticated')::text,
    true);

  select id, rol, especialidad, departamento, turno
    into v_id, v_rol, v_esp, v_dep, v_turno
    from perfil_actual();

  if v_rol <> 'admin' then raise exception 'Caso 6: el admin resolvió como "%".', v_rol; end if;
  if v_id::text <> current_setting('hfx.admin_id') then
    raise exception 'Caso 6: perfil_actual() devolvió un UUID distinto al de la sesión.';
  end if;
  if v_esp is null then
    raise exception 'Caso 6: el admin no trae datos clínicos; no podría ejercer.';
  end if;
  if v_dep is null then
    raise exception 'Caso 6: el admin no trae datos administrativos.';
  end if;
  if v_turno is not null then
    raise exception 'Caso 6: el admin no debería traer turno de asistente.';
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', current_setting('hfx.doctor_id'), 'role', 'authenticated')::text,
    true);
  select rol, departamento into v_rol, v_dep from perfil_actual();
  if v_rol <> 'doctor' then raise exception 'Caso 6: el doctor resolvió como "%".', v_rol; end if;
  if v_dep is not null then
    raise exception 'Caso 6: un doctor no puede traer departamento administrativo.';
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', current_setting('hfx.asistente_id'), 'role', 'authenticated')::text,
    true);
  select rol, especialidad, turno into v_rol, v_esp, v_turno from perfil_actual();
  if v_rol <> 'asistente' then raise exception 'Caso 6: el asistente resolvió como "%".', v_rol; end if;
  if v_esp is not null then
    raise exception 'Caso 6: un asistente no puede traer especialidad clínica.';
  end if;
  if v_turno is null then raise exception 'Caso 6: el asistente no trae turno.'; end if;

  -- Sin sesión no hay perfil.
  perform set_config('request.jwt.claims', null, true);
  select count(*) into v_conteo from perfil_actual();
  if v_conteo <> 0 then
    raise exception 'Caso 6: perfil_actual() devolvió % fila(s) sin sesión.', v_conteo;
  end if;

  raise notice 'OK 6b · perfil_actual() resuelve cada rol desde la sesión y nada sin ella';
end;
$$;

-- ---------------------------------------------------------------------------
-- 7. El admin ejerce: aparece en el catálogo, recibe cita y firma consulta.
-- ---------------------------------------------------------------------------
do $$
declare
  v_admin_id  uuid := current_setting('hfx.admin_id')::uuid;
  v_doctor_id uuid := current_setting('hfx.doctor_id')::uuid;
  v_pac_id    uuid := gen_random_uuid();
  v_cita_id   uuid;
  v_conteo    integer;
  v_es_admin  boolean;
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin_id::text, 'role', 'authenticated')::text, true);

  select count(*), bool_or(es_admin) into v_conteo, v_es_admin
    from get_active_doctors() where doctor_id = v_admin_id;
  if v_conteo <> 1 then
    raise exception 'Caso 7: el admin no aparece como doctor agendable.';
  end if;
  if not v_es_admin then
    raise exception 'Caso 7: el catálogo no distingue al admin-doctor.';
  end if;

  select count(*) into v_conteo from get_active_doctors() where doctor_id = v_doctor_id;
  if v_conteo <> 1 then raise exception 'Caso 7: el doctor no aparece en el catálogo.'; end if;

  -- Una cita y una consulta a nombre del admin: las FK apuntan a `doctores`,
  -- así que esto es exactamente lo que antes era imposible.
  insert into personas (id, nombre, apellido, fecha_nacimiento, cedula)
  values (v_pac_id, 'Paco', 'Paciente', date '1990-09-09', 'HFX000-PAC');
  insert into pacientes (id, genero) values (v_pac_id, 'masculino');

  insert into citas (persona_id, doctor_id, fecha_hora, duracion_minutos)
  values (v_pac_id, v_admin_id, now() + interval '1 day', 30)
  returning id into v_cita_id;

  insert into consultas (paciente_id, doctor_id, cita_id, fecha)
  values (v_pac_id, v_admin_id, v_cita_id, now());

  select count(*) into v_conteo from consultas where doctor_id = v_admin_id;
  if v_conteo <> 1 then
    raise exception 'Caso 7: el admin no pudo quedar como autor de su consulta.';
  end if;

  raise notice 'OK 7 · el admin aparece en el catálogo, recibe cita y firma su consulta';
end;
$$;

-- ---------------------------------------------------------------------------
-- 8. Nada de esto es ejecutable sin sesión. Ocultar el botón no es una barrera;
--    el grant sí.
-- ---------------------------------------------------------------------------
do $$
begin
  if has_function_privilege('anon', 'public.perfil_actual()', 'execute') then
    raise exception 'Caso 8: anon puede ejecutar perfil_actual().';
  end if;
  if has_function_privilege('anon', 'public.get_active_doctors()', 'execute') then
    raise exception 'Caso 8: anon puede ejecutar get_active_doctors().';
  end if;
  if not has_function_privilege('authenticated', 'public.perfil_actual()', 'execute') then
    raise exception 'Caso 8: authenticated no puede ejecutar perfil_actual().';
  end if;
  if not has_function_privilege('authenticated', 'public.get_active_doctors()', 'execute') then
    raise exception 'Caso 8: authenticated no puede ejecutar get_active_doctors().';
  end if;

  raise notice 'OK 8 · anon no ejecuta el perfil ni el catálogo; authenticated sí';
end;
$$;

rollback;
