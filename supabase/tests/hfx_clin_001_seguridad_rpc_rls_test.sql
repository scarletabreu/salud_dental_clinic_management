-- HFX-CLIN-001 · matriz ofensiva de RPC, RLS y datos sensibles.
-- Se ejecuta tras `supabase db reset` y revierte todos sus datos.

begin;
set local role postgres;

do $$
declare
  v_admin uuid := '10000000-0000-4000-8000-000000000001';
  v_doc_a uuid := '10000000-0000-4000-8000-000000000002';
  v_doc_b uuid := '10000000-0000-4000-8000-000000000003';
  v_asistente uuid := '10000000-0000-4000-8000-000000000004';
  v_paciente uuid := '20000000-0000-4000-8000-000000000001';
  v_cita_a uuid;
  v_cita_b uuid;
  v_consulta_a uuid;
  v_consulta_b uuid;
  v_consumible uuid;
begin
  perform set_config('hfx001.admin', v_admin::text, true);
  perform set_config('hfx001.doc_a', v_doc_a::text, true);
  perform set_config('hfx001.doc_b', v_doc_b::text, true);
  perform set_config('hfx001.asistente', v_asistente::text, true);

  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    created_at, updated_at, raw_user_meta_data
  ) values
  (v_admin, '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'hfx001-admin@test.local', 'x', now(), now(),
   '{"rol":"admin","nombre":"Ana","apellido":"Admin","fecha_nacimiento":"1980-01-01","cedula":"HFX001-A","username":"hfx001_admin","departamento":"Dirección","especialidad":"General"}'),
  (v_doc_a, '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'hfx001-a@test.local', 'x', now(), now(),
   '{"rol":"doctor","nombre":"Dora","apellido":"Autora","fecha_nacimiento":"1981-01-01","cedula":"HFX001-D1","username":"hfx001_d1","especialidad":"General"}'),
  (v_doc_b, '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'hfx001-b@test.local', 'x', now(), now(),
   '{"rol":"doctor","nombre":"Dino","apellido":"Ajeno","fecha_nacimiento":"1982-01-01","cedula":"HFX001-D2","username":"hfx001_d2","especialidad":"General"}'),
  (v_asistente, '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'hfx001-as@test.local', 'x', now(), now(),
   '{"rol":"asistente","nombre":"Rita","apellido":"Recepción","fecha_nacimiento":"1990-01-01","cedula":"HFX001-AS","username":"hfx001_as","turno":"matutino"}');

  insert into public.personas (
    id, nombre, apellido, fecha_nacimiento, cedula
  ) values (
    v_paciente, 'Paz', 'Paciente', date '1995-01-01', 'HFX001-P'
  );
  insert into public.pacientes(id, genero) values (v_paciente, 'femenino');

  insert into public.citas(persona_id, doctor_id, fecha_hora, duracion_minutos)
  values (v_paciente, v_doc_a, now() + interval '1 day', 30)
  returning id into v_cita_a;
  insert into public.citas(persona_id, doctor_id, fecha_hora, duracion_minutos)
  values (v_paciente, v_doc_b, now() + interval '2 day', 30)
  returning id into v_cita_b;
  insert into public.consultas(paciente_id, doctor_id, cita_id, fecha, notas)
  values (v_paciente, v_doc_a, v_cita_a, now(), 'original A')
  returning id into v_consulta_a;
  insert into public.consultas(paciente_id, doctor_id, cita_id, fecha, notas)
  values (v_paciente, v_doc_b, v_cita_b, now(), 'original B')
  returning id into v_consulta_b;
  insert into public.consumibles(
    nombre, stock_actual, stock_minimo, precio
  ) values ('Guantes HFX001', 20, 5, 100)
  returning id into v_consumible;

  perform set_config('hfx001.consulta_a', v_consulta_a::text, true);
  perform set_config('hfx001.consulta_b', v_consulta_b::text, true);
  perform set_config('hfx001.cita_b', v_cita_b::text, true);
  perform set_config('hfx001.consumible', v_consumible::text, true);
end;
$$;

-- Grants: anon no muta, authenticated no invoca triggers ni funciones base.
do $$
declare
  v_oid oid;
begin
  if has_function_privilege(
    'anon', 'public.finalizar_consulta(uuid,text,text)', 'execute'
  ) then
    raise exception 'anon conserva finalizar_consulta';
  end if;
  if has_function_privilege(
    'anon',
    'public.crear_consulta_completa(uuid,uuid,uuid,timestamptz,text,jsonb,jsonb,jsonb,tipo_atencion_clinica)',
    'execute'
  ) then
    raise exception 'anon conserva crear_consulta_completa';
  end if;
  if has_function_privilege(
    'authenticated', 'public.update_timestamp()', 'execute'
  ) then
    raise exception 'authenticated puede invocar una función de trigger';
  end if;
  select p.oid into v_oid from pg_proc p join pg_namespace n on n.oid=p.pronamespace
   where n.nspname='public' and p.proname='hfx_base_finalizar_consulta';
  if has_function_privilege('authenticated', v_oid, 'execute') then
    raise exception 'authenticated puede saltarse el wrapper de cierre';
  end if;
  if has_column_privilege(
    'authenticated', 'public.usuarios', 'password_hash', 'select'
  ) then
    raise exception 'password_hash sigue siendo legible por PostgREST';
  end if;
  if has_table_privilege('anon', 'public.consultas', 'select') then
    raise exception 'anon conserva privilegios directos sobre consultas';
  end if;
  if exists (
    select 1 from storage.buckets
     where id = 'documentos-clinicos' and public
  ) then
    raise exception 'el bucket de documentos clínicos sigue siendo público';
  end if;
  raise notice 'OK 1 · grants mínimos, triggers/base privados y hash ilegible';
end;
$$;

-- Anon sin token: la ACL anterior demuestra que no llega al cuerpo de la RPC.
-- La invocación efectiva se cubre por PostgREST en
-- hfx_clin_001_rest_ofensivo.sh. Ejecutar una función revocada dentro de un
-- bloque DO con SET ROLE anon provoca SIGSEGV en la imagen local de PostgreSQL
-- 17, por lo que aquí no se repite ese patrón defectuoso del motor.
set local role anon;
set local request.jwt.claims = '{"role":"anon"}';
do $$
begin
  if auth.uid() is not null then
    raise exception 'anon sin token obtuvo auth.uid()';
  end if;
  raise notice 'OK 2 · anon sin token no tiene identidad ni grants de mutación';
end;
$$;

-- Asistente: ve lo operativo permitido, pero no escribe clínica.
set local role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object(
    'sub', current_setting('hfx001.asistente'), 'role', 'authenticated'
  )::text, true
);
do $$
begin
  begin
    update public.consultas set notas = 'intrusión asistente'
     where id = current_setting('hfx001.consulta_a')::uuid;
    if found then raise exception 'asistente actualizó consulta'; end if;
  exception when insufficient_privilege then null;
  end;

  begin
    insert into public.recetas(consulta_id, doctor_id, items_receta)
    values (
      current_setting('hfx001.consulta_a')::uuid,
      current_setting('hfx001.doc_a')::uuid,
      '[]'
    );
    raise exception 'asistente insertó receta';
  exception when insufficient_privilege then null;
  end;
  raise notice 'OK 3 · asistente no escribe consulta ni receta';
end;
$$;

-- Doctor: puede editar la propia, no la ajena ni firmar con UUID ajeno.
select set_config(
  'request.jwt.claims',
  json_build_object(
    'sub', current_setting('hfx001.doc_a'), 'role', 'authenticated'
  )::text, true
);
do $$
declare
  v_count integer;
begin
  update public.consultas set notas = 'edición propia'
   where id = current_setting('hfx001.consulta_a')::uuid;
  get diagnostics v_count = row_count;
  if v_count <> 1 then raise exception 'doctor no pudo editar consulta propia'; end if;

  update public.consultas set notas = 'intrusión doctor'
   where id = current_setting('hfx001.consulta_b')::uuid;
  get diagnostics v_count = row_count;
  if v_count <> 0 then raise exception 'doctor actualizó consulta ajena'; end if;

  update public.citas set motivo = 'intrusión doctor'
   where id = current_setting('hfx001.cita_b')::uuid;
  get diagnostics v_count = row_count;
  if v_count <> 0 then raise exception 'doctor actualizó cita ajena'; end if;

  begin
    insert into public.documentos_clinicos (
      paciente_id, consulta_id, descripcion, tipo_documento, url_archivo
    ) values (
      '20000000-0000-4000-8000-000000000001',
      current_setting('hfx001.consulta_b')::uuid,
      'documento ajeno', 'imagen', 'ruta/ajena.jpg'
    );
    raise exception 'doctor adjuntó documento a consulta ajena';
  exception when insufficient_privilege then null;
  end;

  begin
    perform public.crear_consulta_completa(
      '20000000-0000-4000-8000-000000000001',
      current_setting('hfx001.doc_b')::uuid,
      gen_random_uuid(), now(), null, '[]', '[]', '[]',
      'consulta'::tipo_atencion_clinica
    );
    raise exception 'doctor pudo firmar con UUID ajeno';
  exception when insufficient_privilege then null;
  end;
  raise notice 'OK 4 · doctor solo escribe lo propio y no suplanta autoría';
end;
$$;

-- Admin ve la consulta ajena, pero solo la corrige por la RPC auditada.
select set_config(
  'request.jwt.claims',
  json_build_object(
    'sub', current_setting('hfx001.admin'), 'role', 'authenticated'
  )::text, true
);
do $$
declare
  v_count integer;
  v_autor uuid;
  v_stock integer;
  v_estado public.estado_consumible;
begin
  update public.consultas set notas = 'atajo admin'
   where id = current_setting('hfx001.consulta_b')::uuid;
  get diagnostics v_count = row_count;
  if v_count <> 0 then
    raise exception 'admin alteró consulta ajena sin auditoría';
  end if;

  perform public.corregir_consulta_ajena(
    current_setting('hfx001.consulta_b')::uuid,
    '{"notas":"corrección auditada"}',
    'Corrección administrativa documentada'
  );

  select doctor_id into v_autor from public.consultas
   where id = current_setting('hfx001.consulta_b')::uuid;
  if v_autor::text <> current_setting('hfx001.doc_b') then
    raise exception 'la corrección cambió al autor original';
  end if;
  select count(*) into v_count from public.auditoria_correcciones_clinicas
   where consulta_id = current_setting('hfx001.consulta_b')::uuid
     and corregido_por = current_setting('hfx001.admin')::uuid
     and autor_original_id = current_setting('hfx001.doc_b')::uuid;
  if v_count <> 1 then raise exception 'la corrección no dejó auditoría'; end if;

  perform public.ajustar_stock_consumible(
    current_setting('hfx001.consumible')::uuid, 3, 'correccion'
  );
  select stock_actual, estado into v_stock, v_estado
    from public.consumibles
   where id = current_setting('hfx001.consumible')::uuid;
  if v_stock <> 3 or v_estado <> 'bajo_stock'::public.estado_consumible then
    raise exception 'el ajuste administrativo de stock no aplicó estado enum';
  end if;
  raise notice 'OK 5 · corrección admin conserva autor y deja antes/después';
end;
$$;

-- Baja lógica: el token sigue siendo formalmente válido, pero pierde capacidad.
set local role postgres;
update public.usuarios set deleted_at = now()
 where id = current_setting('hfx001.doc_a')::uuid;
set local role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object(
    'sub', current_setting('hfx001.doc_a'), 'role', 'authenticated'
  )::text, true
);
do $$
begin
  if public.es_doctor() then
    raise exception 'un perfil inactivo conserva capacidad clínica';
  end if;
  begin
    perform public.finalizar_consulta(
      current_setting('hfx001.consulta_a')::uuid, 'contado', null
    );
    raise exception 'perfil inactivo finalizó consulta';
  exception when insufficient_privilege then null;
  end;
  raise notice 'OK 6 · un perfil inactivo pierde capacidad aunque conserve token';
end;
$$;

rollback;
