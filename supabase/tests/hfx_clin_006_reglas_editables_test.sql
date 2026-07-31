-- HFX-CLIN-006 · reglas clínicas aprobadas y editables desde la aplicación.
-- Se ejecuta tras `supabase db reset` y revierte todos sus datos.
--
--   psql "$DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/hfx_clin_006_reglas_editables_test.sql

begin;
set local role postgres;

-- ---------------------------------------------------------------------------
-- 0 · Escenario: una doctora, una asistente y una administradora que ejerce.
-- ---------------------------------------------------------------------------
do $$
declare
  v_doc       uuid := '60600000-0000-4000-8000-000000000001';
  v_asistente uuid := '60600000-0000-4000-8000-000000000002';
  v_admin     uuid := '60600000-0000-4000-8000-000000000003';
begin
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    created_at, updated_at, raw_user_meta_data
  ) values
  (v_doc, '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'hfx006-doc@test.local', 'x', now(), now(),
   '{"rol":"doctor","nombre":"Rita","apellido":"Reglas","fecha_nacimiento":"1980-01-01","cedula":"HFX006-DA","username":"hfx006_da","especialidad":"General"}'),
  (v_asistente, '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'hfx006-asis@test.local', 'x', now(), now(),
   '{"rol":"asistente","nombre":"Sara","apellido":"Recepción","fecha_nacimiento":"1990-01-01","cedula":"HFX006-AS","username":"hfx006_as","turno":"matutino"}'),
  (v_admin, '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'hfx006-admin@test.local', 'x', now(), now(),
   '{"rol":"admin","nombre":"Tina","apellido":"Dirección","fecha_nacimiento":"1975-01-01","cedula":"HFX006-AD","username":"hfx006_ad","especialidad":"General","departamento":"Dirección"}');

  perform set_config('hfx006.doc', v_doc::text, true);
  perform set_config('hfx006.asistente', v_asistente::text, true);
  perform set_config('hfx006.admin', v_admin::text, true);
end;
$$;

create or replace function pg_temp.actuar_como(p_uuid text) returns void
language plpgsql as $$
begin
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', p_uuid, 'role', 'authenticated')::text,
    true);
end;
$$;

-- ---------------------------------------------------------------------------
-- 1 · Las nueve reglas quedaron aprobadas y con parámetros.
-- ---------------------------------------------------------------------------
-- El motor filtra por `parametros is not null`: aprobarlas sin umbral las
-- dejaría igual de mudas que antes, pero pareciendo activas.
do $$
declare
  v_sin_parametros text;
  v_pendientes     integer;
begin
  select count(*) into v_pendientes
    from public.reglas_clinicas
   where estado = 'pendiente_aprobacion';

  if v_pendientes > 0 then
    raise exception 'quedan % reglas sin aprobar', v_pendientes;
  end if;

  select string_agg(codigo, ', ') into v_sin_parametros
    from public.reglas_clinicas
   where estado = 'aprobada' and parametros is null;

  if v_sin_parametros is not null then
    raise exception 'reglas aprobadas sin umbral: %', v_sin_parametros;
  end if;

  if (select count(*) from public.reglas_clinicas where estado = 'aprobada') <> 11 then
    raise exception 'se esperaban 11 reglas en vigor';
  end if;

  raise notice 'OK 1 · las once reglas están en vigor y con umbral';
end;
$$;

-- ---------------------------------------------------------------------------
-- 2 · Cada umbral vigila un signo que existe en el catálogo.
-- ---------------------------------------------------------------------------
-- Vigilar un código inexistente no da error: simplemente no encuentra el signo
-- y la regla nunca dispara.
do $$
declare
  v_huerfano text;
begin
  select string_agg(distinct codigo, ', ') into v_huerfano
    from (
      select r.codigo, r.parametros ->> 'codigo' as signo
        from public.reglas_clinicas r
       where r.tipo in ('valor_critico', 'requisito_dato')
      union all
      select r.codigo, s ->> 'codigo'
        from public.reglas_clinicas r,
             jsonb_array_elements(coalesce(r.parametros -> 'signos', '[]'::jsonb)) s
       where r.tipo = 'combinacion_condicion_signo'
    ) t
   where signo is not null
     and not exists (
       select 1 from public.catalogo_signos_vitales c where c.codigo = t.signo);

  if v_huerfano is not null then
    raise exception 'reglas que vigilan un signo inexistente: %', v_huerfano;
  end if;

  raise notice 'OK 2 · todos los umbrales apuntan a un signo del catálogo';
end;
$$;

-- ---------------------------------------------------------------------------
-- 3 · El catálogo dejó de ser escribible desde el cliente.
-- ---------------------------------------------------------------------------
-- Es de donde sale el rango físicamente posible: vaciarlo apaga
-- `SV_RANGO_IMPOSIBLE` sin que nadie se entere.
do $$
begin
  if not (select relrowsecurity from pg_class
           where oid = 'public.catalogo_signos_vitales'::regclass) then
    raise exception 'el catálogo de signos vitales sigue sin RLS';
  end if;

  if has_table_privilege('authenticated', 'public.catalogo_signos_vitales', 'insert')
     or has_table_privilege('authenticated', 'public.catalogo_signos_vitales', 'update')
     or has_table_privilege('authenticated', 'public.catalogo_signos_vitales', 'delete')
     or has_table_privilege('authenticated', 'public.catalogo_signos_vitales', 'truncate') then
    raise exception 'un usuario autenticado puede alterar el catálogo';
  end if;

  if not has_table_privilege('authenticated', 'public.catalogo_signos_vitales', 'select') then
    raise exception 'el catálogo dejó de ser legible';
  end if;

  raise notice 'OK 3 · el catálogo se lee pero no se escribe desde el cliente';
end;
$$;

-- ---------------------------------------------------------------------------
-- 4 · La doctora publica una versión nueva; la anterior queda retirada.
-- ---------------------------------------------------------------------------
set local role authenticated;
select pg_temp.actuar_como(current_setting('hfx006.doc'));

do $$
declare
  v_resultado jsonb;
  v_estados   text;
begin
  v_resultado := public.publicar_regla_clinica(
    'SV_PULSO_CRITICO',
    jsonb_build_object('codigo', 'pulso', 'min', 45, 'max', 130),
    null, null, 'Ajuste acordado en comité clínico.');

  if (v_resultado ->> 'version')::int <> 2 then
    raise exception 'la publicación no creó la versión 2: %', v_resultado;
  end if;
  if (v_resultado ->> 'sin_cambios')::boolean then
    raise exception 'la publicación se declaró sin cambios habiéndolos';
  end if;

  select string_agg(version || ':' || estado, ', ' order by version)
    into v_estados
    from public.reglas_clinicas where codigo = 'SV_PULSO_CRITICO';

  if v_estados <> '1:retirada, 2:aprobada' then
    raise exception 'las versiones quedaron en un estado inesperado: %', v_estados;
  end if;

  raise notice 'OK 4 · publicar crea una versión nueva y retira la anterior';
end;
$$;

-- ---------------------------------------------------------------------------
-- 5 · Un solo umbral en vigor por código.
-- ---------------------------------------------------------------------------
-- Si las dos versiones quedaran aprobadas el motor evaluaría el mismo código
-- dos veces y el doctor vería la alerta duplicada con umbrales distintos.
do $$
declare
  v_duplicadas text;
begin
  select string_agg(codigo, ', ') into v_duplicadas
    from (select codigo from public.reglas_clinicas
           where estado = 'aprobada'
           group by codigo having count(*) > 1) t;

  if v_duplicadas is not null then
    raise exception 'códigos con más de una versión en vigor: %', v_duplicadas;
  end if;

  raise notice 'OK 5 · cada código tiene una sola versión en vigor';
end;
$$;

-- ---------------------------------------------------------------------------
-- 6 · Republicar lo mismo no genera una versión nueva.
-- ---------------------------------------------------------------------------
do $$
declare
  v_resultado jsonb;
begin
  v_resultado := public.publicar_regla_clinica(
    'SV_PULSO_CRITICO',
    jsonb_build_object('codigo', 'pulso', 'min', 45, 'max', 130));

  if not (v_resultado ->> 'sin_cambios')::boolean then
    raise exception 'reenviar el mismo umbral creó otra versión: %', v_resultado;
  end if;

  if (select count(*) from public.reglas_clinicas
       where codigo = 'SV_PULSO_CRITICO') <> 2 then
    raise exception 'apareció una tercera versión sin cambios';
  end if;

  raise notice 'OK 6 · reenviar el formulario sin cambios no versiona';
end;
$$;

-- ---------------------------------------------------------------------------
-- 7 · La edición queda firmada, y una doctora sin galones también puede firmar.
-- ---------------------------------------------------------------------------
-- El rastro no puede vivir en `auditoria_operaciones_admin`: su `actor_id`
-- referencia `admins` y su política exige `es_admin()`, así que una doctora que
-- no es administradora habría hecho fallar la escritura del rastro —y con ella
-- la edición entera—.
do $$
declare
  v_evento record;
begin
  select * into v_evento
    from public.auditoria_reglas_clinicas
   where operacion = 'publicada' and codigo = 'SV_PULSO_CRITICO'
   order by created_at desc limit 1;

  if v_evento is null then
    raise exception 'publicar una regla no dejó rastro';
  end if;
  if v_evento.actor_id <> current_setting('hfx006.doc')::uuid then
    raise exception 'el evento no atribuye la edición a quien la hizo';
  end if;
  if v_evento.version <> 2 then
    raise exception 'el evento no apunta a la versión publicada';
  end if;
  if (v_evento.metadata -> 'parametros_anteriores' ->> 'max') <> '120' then
    raise exception 'el evento no conserva el umbral anterior: %',
      v_evento.metadata;
  end if;
  if (v_evento.metadata ->> 'nota') is null then
    raise exception 'el evento perdió el motivo del cambio';
  end if;

  raise notice 'OK 7 · la edición queda firmada con el umbral anterior y el nuevo';
end;
$$;

-- El rastro tampoco lo puede escribir a mano quien es auditado por él.
do $$
begin
  if has_table_privilege('authenticated', 'public.auditoria_reglas_clinicas', 'insert')
     or has_table_privilege('authenticated', 'public.auditoria_reglas_clinicas', 'update')
     or has_table_privilege('authenticated', 'public.auditoria_reglas_clinicas', 'delete') then
    raise exception 'un usuario autenticado puede fabricar el rastro de reglas';
  end if;

  raise notice 'OK 7b · sólo las RPC escriben la auditoría de reglas';
end;
$$;

-- ---------------------------------------------------------------------------
-- 8 · La base rechaza umbrales que no vigilarían nada.
-- ---------------------------------------------------------------------------
-- La pantalla valida lo mismo, pero la validación de la pantalla es comodidad;
-- la que no se puede saltar es ésta.
do $$
declare
  v_fallos integer := 0;
begin
  begin
    perform public.publicar_regla_clinica(
      'SV_PULSO_CRITICO', jsonb_build_object('codigo', 'pulso'));
    raise exception 'se aceptó una regla sin ningún límite';
  exception when sqlstate 'CL030' then v_fallos := v_fallos + 1;
  end;

  begin
    perform public.publicar_regla_clinica(
      'SV_PULSO_CRITICO',
      jsonb_build_object('codigo', 'pulso', 'min', 150, 'max', 40));
    raise exception 'se aceptó un rango invertido';
  exception when sqlstate 'CL030' then v_fallos := v_fallos + 1;
  end;

  begin
    perform public.publicar_regla_clinica(
      'SV_PULSO_CRITICO',
      jsonb_build_object('codigo', 'inventado', 'max', 100));
    raise exception 'se aceptó un signo que no existe en el catálogo';
  exception when sqlstate 'CL030' then v_fallos := v_fallos + 1;
  end;

  begin
    perform public.publicar_regla_clinica(
      'COMB_DIABETES_SIGNOS',
      jsonb_build_object('condicion', 'diabetes', 'signos', '[]'::jsonb));
    raise exception 'se aceptó una combinación sin signos que vigilar';
  exception when sqlstate 'CL030' then v_fallos := v_fallos + 1;
  end;

  if v_fallos <> 4 then
    raise exception 'sólo se rechazaron % de 4 umbrales inválidos', v_fallos;
  end if;

  raise notice 'OK 8 · la base rechaza los umbrales que no vigilarían nada';
end;
$$;

-- ---------------------------------------------------------------------------
-- 9 · La administradora también ejerce, así que también publica.
-- ---------------------------------------------------------------------------
select pg_temp.actuar_como(current_setting('hfx006.admin'));

do $$
declare
  v_resultado jsonb;
begin
  v_resultado := public.publicar_regla_clinica(
    'SV_DOLOR_SEVERO', jsonb_build_object('codigo', 'dolor', 'max', 8));

  if (v_resultado ->> 'version')::int <> 2 then
    raise exception 'la administradora no pudo publicar: %', v_resultado;
  end if;

  raise notice 'OK 9 · el admin edita reglas porque también ejerce clínica';
end;
$$;

-- ---------------------------------------------------------------------------
-- 10 · La asistente no toca los umbrales clínicos.
-- ---------------------------------------------------------------------------
select pg_temp.actuar_como(current_setting('hfx006.asistente'));

do $$
begin
  begin
    perform public.publicar_regla_clinica(
      'SV_DOLOR_SEVERO', jsonb_build_object('codigo', 'dolor', 'max', 3));
    raise exception 'la asistente movió un umbral clínico';
  exception when sqlstate 'CL031' then null;
  end;

  begin
    perform public.retirar_regla_clinica('SV_DOLOR_SEVERO', 'Prueba');
    raise exception 'la asistente retiró una regla clínica';
  exception when sqlstate 'CL031' then null;
  end;

  raise notice 'OK 10 · la asistente no decide umbrales clínicos';
end;
$$;

-- ---------------------------------------------------------------------------
-- 11 · Retirar exige motivo y no borra el histórico.
-- ---------------------------------------------------------------------------
select pg_temp.actuar_como(current_setting('hfx006.doc'));

do $$
declare
  v_antes integer;
begin
  select count(*) into v_antes
    from public.reglas_clinicas where codigo = 'SV_DOLOR_SEVERO';

  begin
    perform public.retirar_regla_clinica('SV_DOLOR_SEVERO', '   ');
    raise exception 'se retiró una regla sin motivo';
  exception when sqlstate 'CL033' then null;
  end;

  perform public.retirar_regla_clinica(
    'SV_DOLOR_SEVERO', 'La clínica deja de vigilar el dolor referido.');

  if exists (select 1 from public.reglas_clinicas
              where codigo = 'SV_DOLOR_SEVERO' and estado = 'aprobada') then
    raise exception 'la regla sigue en vigor tras retirarla';
  end if;

  if (select count(*) from public.reglas_clinicas
       where codigo = 'SV_DOLOR_SEVERO') <> v_antes then
    raise exception 'retirar borró versiones del histórico';
  end if;

  raise notice 'OK 11 · retirar exige motivo y conserva el histórico';
end;
$$;

-- ---------------------------------------------------------------------------
-- 12 · Una regla retirada deja de evaluarse; una editada usa el umbral nuevo.
-- ---------------------------------------------------------------------------
-- Es la prueba de que editar desde la aplicación cambia lo que ocurre en la
-- consulta, no sólo lo que dice una tabla.
set local role postgres;

do $$
declare
  v_doc      uuid := current_setting('hfx006.doc')::uuid;
  v_paciente uuid := '60600000-0000-4000-8000-000000000010';
  v_cita     uuid;
  v_consulta uuid;
  v_alertas  jsonb;
begin
  insert into public.personas (id, nombre, apellido, fecha_nacimiento, cedula)
  values (v_paciente, 'Pedro', 'Prueba', date '1990-05-05', '00600000001');
  insert into public.pacientes (id, genero) values (v_paciente, 'masculino');
  insert into public.records (paciente_id, tipo_sangre)
  values (v_paciente, 'o_positivo');

  insert into public.citas (persona_id, doctor_id, fecha_hora, duracion_minutos, estado)
  values (v_paciente, v_doc, now(), 30, 'en_consulta')
  returning id into v_cita;

  insert into public.consultas (paciente_id, doctor_id, cita_id, fecha, motivo_consulta)
  values (v_paciente, v_doc, v_cita, now(), 'Control')
  returning id into v_consulta;

  -- Pulso 125: con el umbral original (120) alertaría; con el publicado (130)
  -- no. Y el dolor, cuya regla acaba de retirarse, tampoco debe aparecer.
  insert into public.signos_vitales_consulta (consulta_id, codigo, valor)
  values (v_consulta, 'pulso', 125), (v_consulta, 'dolor', 9);

  v_alertas := public.hfx_clin_003_evaluar_alertas(v_consulta);

  if v_alertas @> '[{"regla":"SV_PULSO_CRITICO"}]'::jsonb then
    raise exception 'el motor sigue usando el umbral antiguo del pulso: %', v_alertas;
  end if;
  if v_alertas @> '[{"regla":"SV_DOLOR_SEVERO"}]'::jsonb then
    raise exception 'una regla retirada sigue alertando: %', v_alertas;
  end if;

  -- Y con 135 sí alerta, ahora con la versión 2.
  update public.signos_vitales_consulta set valor = 135
   where consulta_id = v_consulta and codigo = 'pulso';
  v_alertas := public.hfx_clin_003_evaluar_alertas(v_consulta);

  if not (v_alertas @> '[{"regla":"SV_PULSO_CRITICO"}]'::jsonb) then
    raise exception 'el umbral nuevo no dispara la alerta: %', v_alertas;
  end if;

  if (select regla_version from public.alertas_clinicas
       where consulta_id = v_consulta
         and regla_codigo = 'SV_PULSO_CRITICO'
         and estado <> 'obsoleta') <> 2 then
    raise exception 'la alerta no quedó sellada con la versión que la emitió';
  end if;

  raise notice 'OK 12 · el motor obedece al umbral publicado y sella su versión';
end;
$$;

-- ---------------------------------------------------------------------------
-- 13 · anon no ve ni toca las reglas.
-- ---------------------------------------------------------------------------
-- Se comprueba con `has_function_privilege` y no llamando a la función: con
-- `set role anon` una función sin grant tumba el Postgres local entero.
do $$
begin
  if has_function_privilege('anon', 'public.publicar_regla_clinica(text, jsonb, text, text, text)', 'execute')
     or has_function_privilege('anon', 'public.retirar_regla_clinica(text, text)', 'execute')
     or has_function_privilege('anon', 'public.reglas_clinicas_vigentes()', 'execute') then
    raise exception 'anon alcanza las funciones de reglas clínicas';
  end if;

  if has_table_privilege('anon', 'public.reglas_clinicas', 'select')
     or has_table_privilege('anon', 'public.catalogo_signos_vitales', 'select') then
    raise exception 'anon lee las reglas o el catálogo';
  end if;

  raise notice 'OK 13 · anon no alcanza las reglas clínicas por ninguna vía';
end;
$$;

rollback;
