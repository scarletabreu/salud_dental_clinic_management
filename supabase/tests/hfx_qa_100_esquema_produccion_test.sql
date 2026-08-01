-- HFX-QA-100 · Prueba del modelo de permisos de producción, ya versionado.
--
-- Se ejecuta sobre una base con todas las migraciones aplicadas. Todo ocurre
-- dentro de una transacción que termina en ROLLBACK: no deja rastro.
--
--   psql -h 127.0.0.1 -p 54322 -U postgres -d postgres -v ON_ERROR_STOP=1 \
--        -f supabase/tests/hfx_qa_100_esquema_produccion_test.sql
--
-- NO ejecutar contra la instancia real: inserta datos y el ROLLBACK no está
-- garantizado por la Management API.
--
-- Contrato que se verifica:
--   1. Existen los objetos que sólo estaban en producción (tablas, vista,
--      funciones y triggers de la deriva).
--   2. `doctor_paciente` gobierna de verdad lo que ve un doctor regular:
--      sin asignación activa, `pacientes` no le devuelve la ficha.
--   3. El trigger `trg_autoasignar_doctor_paciente` da acceso al doctor que
--      abre la consulta, y a partir de ahí sí ve la ficha.
--   4. Un segundo doctor sin asignación sigue sin ver esa ficha (el acceso no
--      es global, es por par doctor-paciente).
--   5. `directorio_pacientes` resuelve el NOMBRE de ese paciente para el doctor
--      no asignado — es la pieza que evita el «Paciente #uuid» del defecto D4.
--   6. El directorio no filtra datos de más: sólo id, nombre y apellido.
--   7. Las vistas `*_seguro` ya no existen (defecto D3).
--   8. `admins` tiene una sola FK hacia `doctores` (defecto D2).
--   9. `auditoria_log` e `items_receta` quedan cerradas a `authenticated`.

begin;

set local role postgres;

do $$
declare
  v_doctor_a    uuid := gen_random_uuid();
  v_doctor_b    uuid := gen_random_uuid();
  v_paciente    uuid := gen_random_uuid();
  v_consulta_id uuid;
  v_conteo      integer;
  v_nombre      text;
  v_columnas    text;
begin
  -- ------------------------------------------------- 1. objetos de la deriva
  foreach v_nombre in array array[
    'public.doctor_paciente', 'public.auditoria_log', 'public.items_receta',
    'public.resumen_actividad_plan', 'public.directorio_pacientes'
  ] loop
    if to_regclass(v_nombre) is null then
      raise exception 'HFX-QA-100: falta el objeto % en el esquema.', v_nombre;
    end if;
  end loop;

  foreach v_nombre in array array[
    'fn_auditoria_log', 'fn_autoasignar_doctor_paciente',
    'fn_cascade_deleted_at_doctor', 'fn_cascade_deleted_at_usuario',
    'generar_codigo_receta'
  ] loop
    if not exists (
      select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
       where n.nspname = 'public' and p.proname = v_nombre
    ) then
      raise exception 'HFX-QA-100: falta la función %.', v_nombre;
    end if;
  end loop;

  select count(*) into v_conteo
    from pg_trigger
   where not tgisinternal
     and tgname in ('trg_auditoria_caja_diaria', 'trg_auditoria_cita',
                    'trg_auditoria_compra', 'trg_auditoria_consulta',
                    'trg_auditoria_cuenta', 'trg_auditoria_pago',
                    'trg_autoasignar_doctor_paciente',
                    'trg_cascade_deleted_at_doctor',
                    'trg_cascade_deleted_at_usuario',
                    'trg_generar_codigo_receta');
  if v_conteo <> 10 then
    raise exception 'HFX-QA-100: se esperaban 10 triggers de la deriva, hay %.', v_conteo;
  end if;
  raise notice 'OK 1 · los objetos que sólo estaban en producción están versionados.';

  -- --------------------------------------------------------------- montaje
  insert into personas (id, nombre, apellido, fecha_nacimiento, cedula, created_at, updated_at)
  values (v_doctor_a, 'Ada', 'Doctora QA100 A', date '1985-01-01', 'QA100-DOC-A', now(), now());
  insert into usuarios (id, username, created_at, updated_at)
  values (v_doctor_a, 'qa100_doctor_a', now(), now());
  insert into doctores (id, especialidad, updated_at)
  values (v_doctor_a, 'General', now());

  insert into personas (id, nombre, apellido, fecha_nacimiento, cedula, created_at, updated_at)
  values (v_doctor_b, 'Beto', 'Doctor QA100 B', date '1986-02-02', 'QA100-DOC-B', now(), now());
  insert into usuarios (id, username, created_at, updated_at)
  values (v_doctor_b, 'qa100_doctor_b', now(), now());
  insert into doctores (id, especialidad, updated_at)
  values (v_doctor_b, 'General', now());

  insert into personas (id, nombre, apellido, fecha_nacimiento, cedula, created_at, updated_at)
  values (v_paciente, 'Zoila', 'Paciente QA100', date '1995-05-05', 'QA100-PAC', now(), now());
  insert into pacientes (id, genero, created_at, updated_at)
  values (v_paciente, 'femenino', now(), now());

  -- --------------------------------- 2. sin asignación, el doctor no ve ficha
  -- `set role authenticated` es lo que hace que RLS se evalúe: `postgres` la
  -- salta por ser propietario.
  set local role authenticated;
  perform set_config('request.jwt.claims',
                     json_build_object('sub', v_doctor_a)::text, true);

  select count(*) into v_conteo from pacientes where id = v_paciente;
  if v_conteo <> 0 then
    raise exception
      'HFX-QA-100: un doctor sin asignación en doctor_paciente vio la ficha (% filas).',
      v_conteo;
  end if;
  raise notice 'OK 2 · sin asignación activa el doctor no lee la ficha del paciente.';

  -- ------------------------------------- 3. abrir consulta concede el acceso
  reset role;
  insert into consultas (paciente_id, doctor_id, fecha, motivo_consulta, created_at, updated_at)
  values (v_paciente, v_doctor_a, now(), 'Dolor molar', now(), now())
  returning id into v_consulta_id;

  select count(*) into v_conteo
    from doctor_paciente
   where doctor_id = v_doctor_a and paciente_id = v_paciente and activo;
  if v_conteo <> 1 then
    raise exception
      'HFX-QA-100: el trigger de autoasignación no creó el acceso (% filas).', v_conteo;
  end if;

  set local role authenticated;
  perform set_config('request.jwt.claims',
                     json_build_object('sub', v_doctor_a)::text, true);
  select count(*) into v_conteo from pacientes where id = v_paciente;
  if v_conteo <> 1 then
    raise exception
      'HFX-QA-100: el doctor asignado no ve la ficha que acaba de atender (% filas).',
      v_conteo;
  end if;
  raise notice 'OK 3 · atender una consulta concede acceso a la ficha.';

  -- ------------------------------ 4. el acceso no se contagia a otro doctor
  perform set_config('request.jwt.claims',
                     json_build_object('sub', v_doctor_b)::text, true);
  select count(*) into v_conteo from pacientes where id = v_paciente;
  if v_conteo <> 0 then
    raise exception
      'HFX-QA-100: un doctor ajeno vio la ficha del paciente (% filas).', v_conteo;
  end if;
  raise notice 'OK 4 · el acceso es por par doctor-paciente, no global.';

  -- ------------------ 5. el directorio sí le resuelve el nombre (defecto D4)
  select nombre into v_nombre from directorio_pacientes where id = v_paciente;
  if v_nombre is distinct from 'Zoila' then
    raise exception
      'HFX-QA-100: el directorio no resolvió el nombre para el doctor no asignado (devolvió %).',
      coalesce(v_nombre, '<nulo>');
  end if;
  raise notice 'OK 5 · el directorio resuelve nombres sin abrir la ficha.';

  -- ---------------------------------- 6. el directorio no filtra datos de más
  reset role;
  select string_agg(column_name, ',' order by ordinal_position)
    into v_columnas
    from information_schema.columns
   where table_schema = 'public' and table_name = 'directorio_pacientes';
  if v_columnas is distinct from 'id,nombre,apellido' then
    raise exception
      'HFX-QA-100: el directorio expone columnas de más o de menos: %.', v_columnas;
  end if;
  raise notice 'OK 6 · el directorio expone exactamente id, nombre y apellido.';

  -- ------------------------------------- 7. las vistas *_seguro ya no existen
  foreach v_nombre in array array[
    'public.pacientes_seguro', 'public.personas_seguro', 'public.contactos_seguro'
  ] loop
    if to_regclass(v_nombre) is not null then
      raise exception 'HFX-QA-100: la vista % sigue existiendo.', v_nombre;
    end if;
  end loop;
  raise notice 'OK 7 · las vistas *_seguro fueron retiradas.';

  -- ------------------------ 8. una sola FK de `admins` hacia `doctores` (D2)
  select count(*) into v_conteo
    from pg_constraint
   where conrelid = 'public.admins'::regclass
     and confrelid = 'public.doctores'::regclass
     and contype = 'f';
  if v_conteo <> 1 then
    raise exception
      'HFX-QA-100: admins tiene % FK hacia doctores; PostgREST necesita exactamente 1.',
      v_conteo;
  end if;
  raise notice 'OK 8 · admins tiene una sola relación con doctores.';

  -- --------------------------- 9. bitácora y tabla legada cerradas al cliente
  foreach v_nombre in array array['auditoria_log', 'items_receta'] loop
    if has_table_privilege('authenticated', 'public.' || v_nombre, 'select') then
      raise exception 'HFX-QA-100: authenticated puede leer %.', v_nombre;
    end if;
  end loop;
  raise notice 'OK 9 · auditoria_log e items_receta quedan cerradas al cliente.';
end;
$$;

rollback;
