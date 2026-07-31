-- HFX-CLIN-008 · La consulta nace con su dentición completa.
-- Se ejecuta tras `supabase db reset` y revierte todos sus datos.
--
--   psql "$DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/hfx_clin_008_odontograma_completo_test.sql
--
-- Estas comprobaciones existen porque las catorce jornadas de HFX-CLIN-006
-- pasaban en verde sobre un defecto que impedía guardar cualquier consulta: el
-- arnés llamaba a `iniciar_consulta_de_cita` con la dentición ya escrita en el
-- payload (`$DENTICION_FDI`), que es justo lo que el cliente no manda. Aquí se
-- llama **sin dientes**, como llama la aplicación.

begin;
set local role postgres;

-- ---------------------------------------------------------------------------
-- 0 · Escenario: una doctora, un paciente y una cita con el paciente llegado.
-- ---------------------------------------------------------------------------
do $$
declare
  v_doc      uuid := '50800000-0000-4000-8000-000000000001';
  v_paciente uuid := '50800000-0000-4000-8000-000000000010';
  v_cita     uuid;
begin
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    created_at, updated_at, raw_user_meta_data
  ) values
  (v_doc, '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'hfx008-doc@test.local', 'x', now(), now(),
   '{"rol":"doctor","nombre":"Olga","apellido":"Odonto","fecha_nacimiento":"1980-01-01","cedula":"HFX008-DO","username":"hfx008_do","especialidad":"General"}');

  insert into public.personas (id, nombre, apellido, fecha_nacimiento, cedula)
  values (v_paciente, 'Pedro', 'Pieza', date '1990-03-03', '00800000001');
  insert into public.pacientes (id, genero) values (v_paciente, 'masculino');
  insert into public.records (paciente_id, tipo_sangre, cirugias_previas, historial_familiar)
  values (v_paciente, 'o_positivo', '{}', 'Sin antecedentes');

  insert into public.citas (persona_id, doctor_id, fecha_hora, duracion_minutos, motivo, estado)
  values (v_paciente, v_doc, date_trunc('hour', now()) + interval '1 hour',
          30, 'Revisión', 'en_espera')
  returning id into v_cita;

  insert into public.diagnosticos (nombre, severidad_default, alcance, categoria)
  values ('HFX008 caries', 'moderada', 'puntual', 'caries');

  perform set_config('hfx008.doc', v_doc::text, true);
  perform set_config('hfx008.paciente', v_paciente::text, true);
  perform set_config('hfx008.cita', v_cita::text, true);
end;
$$;

-- ---------------------------------------------------------------------------
-- 1 · Abrir la consulta sin mandar dientes deja las 52 piezas con sus caras.
-- ---------------------------------------------------------------------------
-- Es exactamente la llamada de la aplicación: el cubit construye la consulta
-- inicial sin odontograma, así que `p_dientes` viaja vacío.
set local role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('hfx008.doc'), 'role', 'authenticated')::text,
  true
);

do $$
declare
  v_consulta uuid;
  v_piezas   integer;
  v_caras    integer;
  v_faltan   integer;
begin
  v_consulta := (public.iniciar_consulta_de_cita(
    current_setting('hfx008.cita')::uuid,
    '[]'::jsonb
  ) ->> 'consulta_id')::uuid;
  perform set_config('hfx008.consulta', v_consulta::text, true);

  select count(*) into v_piezas
    from public.dientes d
    join public.odontogramas o on o.id = d.odontograma_id
   where o.consulta_id = v_consulta;

  if v_piezas <> 52 then
    raise exception 'la consulta nació con % piezas en vez de 52', v_piezas;
  end if;

  -- Que sean 52 no basta: tienen que ser las 52 correctas.
  select count(*) into v_faltan
    from public.hfx_clin_008_denticion_fdi() f
   where not exists (
     select 1
       from public.dientes d
       join public.odontogramas o on o.id = d.odontograma_id
      where o.consulta_id = v_consulta and d.fdi_code = f.fdi
   );
  if v_faltan <> 0 then
    raise exception 'faltan % códigos FDI en el odontograma', v_faltan;
  end if;

  select count(*) into v_caras
    from public.superficies s
    join public.dientes d on d.id = s.diente_id
    join public.odontogramas o on o.id = d.odontograma_id
   where o.consulta_id = v_consulta;

  if v_caras <> 260 then
    raise exception 'las piezas tienen % caras en total en vez de 260', v_caras;
  end if;

  raise notice 'OK 1 · la consulta nace con las 52 piezas y sus 260 caras';
end;
$$;

-- ---------------------------------------------------------------------------
-- 2 · El reparto de caras respeta la anatomía, no un valor por defecto.
-- ---------------------------------------------------------------------------
-- Cinco caras por pieza son fáciles de acertar por accidente; cuál es la
-- interna y cuál la quinta, no. Espejo de `superficiesParaFdi` en Dart.
do $$
declare
  v_caso record;
begin
  for v_caso in
    select * from (values
      (11, 'palatina', 'incisal'),  -- anterior superior permanente
      (18, 'palatina', 'oclusal'),  -- posterior superior permanente
      (33, 'lingual',  'incisal'),  -- anterior inferior permanente
      (46, 'lingual',  'oclusal'),  -- posterior inferior permanente
      (51, 'palatina', 'incisal'),  -- anterior superior temporal
      (65, 'palatina', 'oclusal'),  -- posterior superior temporal
      (71, 'lingual',  'incisal'),  -- anterior inferior temporal
      (85, 'lingual',  'oclusal')   -- posterior inferior temporal
    ) as t(fdi, interna, quinta)
  loop
    if not exists (
      select 1
        from public.superficies s
        join public.dientes d on d.id = s.diente_id
        join public.odontogramas o on o.id = d.odontograma_id
       where o.consulta_id = current_setting('hfx008.consulta')::uuid
         and d.fdi_code = v_caso.fdi
         and s.tipo_superficie::text = v_caso.interna
    ) then
      raise exception 'la pieza % no tiene cara %', v_caso.fdi, v_caso.interna;
    end if;

    if not exists (
      select 1
        from public.superficies s
        join public.dientes d on d.id = s.diente_id
        join public.odontogramas o on o.id = d.odontograma_id
       where o.consulta_id = current_setting('hfx008.consulta')::uuid
         and d.fdi_code = v_caso.fdi
         and s.tipo_superficie::text = v_caso.quinta
    ) then
      raise exception 'la pieza % no tiene cara %', v_caso.fdi, v_caso.quinta;
    end if;
  end loop;

  raise notice 'OK 2 · cada pieza recibe la cara interna y la quinta que le tocan';
end;
$$;

-- ---------------------------------------------------------------------------
-- 3 · El defecto real: anotar una pieza sobre esa consulta se puede guardar.
-- ---------------------------------------------------------------------------
-- Esta es la comprobación que importa. Sin la corrección, esto devolvía CL004
-- («La pieza 11 no pertenece al odontograma…») y ninguna consulta abierta
-- desde una cita podía guardarse ni cerrarse.
do $$
declare
  v_consulta  uuid := current_setting('hfx008.consulta')::uuid;
  v_diag      uuid;
  v_resultado jsonb;
begin
  select id into v_diag from public.diagnosticos where nombre = 'HFX008 caries';

  v_resultado := public.guardar_borrador_consulta(
    v_consulta,
    null,
    jsonb_build_object(
      'motivo_consulta', 'Revisión general',
      'dientes', jsonb_build_array(
        jsonb_build_object(
          'fdi_code', 11,
          'diagnosticos', jsonb_build_array(
            jsonb_build_object(
              'diagnosis_id', v_diag,
              'severidad', 'moderada',
              'superficie', 'vestibular',
              'origen', 'descubierto'
            )
          )
        )
      )
    )
  );

  if (v_resultado ->> 'consulta_id')::uuid is distinct from v_consulta then
    raise exception 'el borrador no se guardó sobre la consulta esperada';
  end if;

  if not exists (
    select 1
      from public.diagnosticos_aplicados da
      join public.dientes d on d.id = da.diente_id
     where da.consulta_id = v_consulta and d.fdi_code = 11
       and da.deleted_at is null
  ) then
    raise exception 'el diagnóstico no quedó colgado de la pieza 11';
  end if;

  raise notice 'OK 3 · se puede anotar una pieza en una consulta abierta desde su cita';
end;
$$;

-- ---------------------------------------------------------------------------
-- 4 · Completar es idempotente y no borra trabajo.
-- ---------------------------------------------------------------------------
-- La reparación de la migración se ejecuta sobre datos vivos: si duplicara
-- piezas o arrastrara las anotaciones existentes, sería peor que el defecto.
set local role postgres;

do $$
declare
  v_odontograma uuid;
  v_creadas     integer;
  v_piezas      integer;
begin
  select o.id into v_odontograma
    from public.odontogramas o
   where o.consulta_id = current_setting('hfx008.consulta')::uuid;

  v_creadas := public.hfx_clin_008_completar_odontograma(v_odontograma);
  if v_creadas <> 0 then
    raise exception 'volver a completar creó % piezas sobre un odontograma lleno', v_creadas;
  end if;

  select count(*) into v_piezas
    from public.dientes where odontograma_id = v_odontograma;
  if v_piezas <> 52 then
    raise exception 'el odontograma quedó con % piezas tras repetir el completado', v_piezas;
  end if;

  if not exists (
    select 1
      from public.diagnosticos_aplicados da
      join public.dientes d on d.id = da.diente_id
     where da.consulta_id = current_setting('hfx008.consulta')::uuid
       and d.fdi_code = 11 and da.deleted_at is null
  ) then
    raise exception 'el completado repetido se llevó por delante el diagnóstico';
  end if;

  raise notice 'OK 4 · completar dos veces no duplica piezas ni pierde anotaciones';
end;
$$;

-- ---------------------------------------------------------------------------
-- 5 · Completar un odontograma no es una capacidad del cliente.
-- ---------------------------------------------------------------------------
do $$
begin
  if has_function_privilege('authenticated',
       'public.hfx_clin_008_completar_odontograma(uuid)', 'execute') then
    raise exception 'un usuario autenticado puede materializar piezas a mano';
  end if;

  raise notice 'OK 5 · las piezas sólo las crea la apertura de la consulta';
end;
$$;

rollback;
