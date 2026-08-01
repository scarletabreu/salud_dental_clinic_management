-- HFX-QA-108 · Normalización de aplicaciones clínicas históricas.
-- Se ejecuta tras `supabase db reset` y revierte todos sus datos.
--
--   psql "$DB_URL" -v ON_ERROR_STOP=1 \
--     -f supabase/tests/hfx_qa_108_alcance_odontograma_test.sql

begin;
set local role postgres;

do $$
declare
  v_doc uuid := '10800000-0000-4000-8000-000000000001';
  v_paciente uuid := '10800000-0000-4000-8000-000000000002';
  v_consulta uuid;
  v_odontograma uuid;
  v_diente uuid;
begin
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    created_at, updated_at, raw_user_meta_data
  ) values (
    v_doc, '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated', 'hfxqa108-doc@test.local', 'x',
    now(), now(),
    '{"rol":"doctor","nombre":"Prueba","apellido":"QA108","fecha_nacimiento":"1980-01-01","cedula":"HFXQA108-D","username":"hfxqa108_doc","especialidad":"General"}'
  );

  insert into public.personas (id, nombre, apellido, fecha_nacimiento, cedula)
  values (v_paciente, 'Paciente', 'QA108', date '1990-01-01', 'HFXQA108-P');
  insert into public.pacientes (id, genero) values (v_paciente, 'femenino');

  insert into public.consultas (paciente_id, doctor_id, fecha)
  values (v_paciente, v_doc, now()) returning id into v_consulta;
  insert into public.odontogramas (consulta_id)
  values (v_consulta) returning id into v_odontograma;
  insert into public.dientes (odontograma_id, fdi_code)
  values (v_odontograma, 16) returning id into v_diente;

  insert into public.tratamientos (id, nombre, costo, alcance) values
    ('10800000-0000-4000-8000-000000000101', 'Global legacy QA108', 1, 'global'),
    ('10800000-0000-4000-8000-000000000102', 'Diente legacy QA108', 1, 'diente'),
    ('10800000-0000-4000-8000-000000000103', 'Diente ambiguo QA108', 1, 'diente');
  insert into public.diagnosticos (id, nombre, alcance, categoria) values
    ('10800000-0000-4000-8000-000000000201', 'Global legacy QA108', 'global', 'caries'),
    ('10800000-0000-4000-8000-000000000202', 'Diente legacy QA108', 'diente', 'caries'),
    ('10800000-0000-4000-8000-000000000203', 'Puntual ambiguo QA108', 'puntual', 'caries');

  -- Reproduce filas anteriores a la barrera HFX-CLIN-003. Solo se apagan los
  -- triggers durante estas inserciones sintéticas; la función se prueba con
  -- todas las barreras activas.
  alter table public.tratamientos_aplicados disable trigger user;
  alter table public.diagnosticos_aplicados disable trigger user;

  insert into public.tratamientos_aplicados
    (id, tratamiento_id, consulta_id, diente_id, superficie) values
    ('10800000-0000-4000-8000-000000000301', '10800000-0000-4000-8000-000000000101', v_consulta, v_diente, 'oclusal'),
    ('10800000-0000-4000-8000-000000000302', '10800000-0000-4000-8000-000000000102', v_consulta, v_diente, 'vestibular'),
    ('10800000-0000-4000-8000-000000000303', '10800000-0000-4000-8000-000000000103', v_consulta, null, null);

  insert into public.diagnosticos_aplicados
    (id, diagnosis_id, consulta_id, diente_id, superficie, severidad) values
    ('10800000-0000-4000-8000-000000000401', '10800000-0000-4000-8000-000000000201', v_consulta, v_diente, 'oclusal', 'leve'),
    ('10800000-0000-4000-8000-000000000402', '10800000-0000-4000-8000-000000000202', v_consulta, v_diente, 'vestibular', 'leve'),
    ('10800000-0000-4000-8000-000000000403', '10800000-0000-4000-8000-000000000203', v_consulta, v_diente, null, 'leve');

  alter table public.tratamientos_aplicados enable trigger user;
  alter table public.diagnosticos_aplicados enable trigger user;

  update public.dientes
     set tratamientos_aplicados_ids = array[
       '10800000-0000-4000-8000-000000000301'::uuid,
       '10800000-0000-4000-8000-000000000302'::uuid
     ]
   where id = v_diente;

  perform set_config('hfxqa108.diente', v_diente::text, true);
end;
$$;

do $$
declare
  v_resultado jsonb;
  v_diente uuid := current_setting('hfxqa108.diente')::uuid;
begin
  v_resultado := public.hfx_qa_108_normalizar_alcance_historico();

  if (v_resultado ->> 'tratamientos_generales_normalizados')::int <> 1
     or (v_resultado ->> 'tratamientos_diente_normalizados')::int <> 1
     or (v_resultado ->> 'diagnosticos_generales_normalizados')::int <> 1
     or (v_resultado ->> 'diagnosticos_diente_normalizados')::int <> 1 then
    raise exception 'cantidades normalizadas inesperadas: %', v_resultado;
  end if;

  if (v_resultado ->> 'tratamientos_ambiguos_pendientes')::int <> 1
     or (v_resultado ->> 'diagnosticos_ambiguos_pendientes')::int <> 1 then
    raise exception 'los casos ambiguos no fueron informados: %', v_resultado;
  end if;

  if exists (
    select 1 from public.tratamientos_aplicados
     where id = '10800000-0000-4000-8000-000000000301'
       and (diente_id is not null or superficie is not null)
  ) then raise exception 'el tratamiento global conservó pieza o superficie'; end if;

  if not exists (
    select 1 from public.tratamientos_aplicados
     where id = '10800000-0000-4000-8000-000000000302'
       and diente_id = v_diente and superficie is null
  ) then raise exception 'el tratamiento de diente no se normalizó'; end if;

  if exists (
    select 1 from public.diagnosticos_aplicados
     where id = '10800000-0000-4000-8000-000000000401'
       and (diente_id is not null or superficie is not null)
  ) then raise exception 'el diagnóstico global conservó pieza o superficie'; end if;

  if not exists (
    select 1 from public.diagnosticos_aplicados
     where id = '10800000-0000-4000-8000-000000000402'
       and diente_id = v_diente and superficie is null
  ) then raise exception 'el diagnóstico de diente no se normalizó'; end if;

  if (select tratamientos_aplicados_ids from public.dientes where id = v_diente)
     <> array['10800000-0000-4000-8000-000000000302'::uuid] then
    raise exception 'la proyección auxiliar del diente no se reconstruyó';
  end if;

  raise notice 'OK 1 · alcance histórico normalizado sin inventar datos ambiguos';
end;
$$;

do $$
declare
  v_resultado jsonb;
begin
  v_resultado := public.hfx_qa_108_normalizar_alcance_historico();
  if (v_resultado ->> 'tratamientos_generales_normalizados')::int <> 0
     or (v_resultado ->> 'tratamientos_diente_normalizados')::int <> 0
     or (v_resultado ->> 'diagnosticos_generales_normalizados')::int <> 0
     or (v_resultado ->> 'diagnosticos_diente_normalizados')::int <> 0
     or (v_resultado ->> 'arrays_diente_reconstruidos')::int <> 0 then
    raise exception 'la segunda ejecución no fue idempotente: %', v_resultado;
  end if;
  raise notice 'OK 2 · la normalización es idempotente';
end;
$$;

rollback;
