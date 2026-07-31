-- HFX-CLIN-006 · Reglas clínicas vivas y aprobadas
--
-- HFX-CLIN-003 dejó el motor de alertas construido pero desarmado: de las once
-- reglas sembradas, nueve quedaron en `pendiente_aprobacion` y sin parámetros,
-- porque nadie con autoridad clínica había fijado los umbrales. Una regla sin
-- parámetros no se evalúa —`hfx_clin_003_evaluar_alertas` filtra por
-- `parametros is not null`—, así que el sistema sabía avisar y no avisaba de
-- nada.
--
-- Esta migración hace tres cosas:
--
--   1. Cierra un agujero que la certificación destapó: `catalogo_signos_vitales`
--      no tenía RLS y `authenticated` conservaba el `grant all` del esquema.
--      Cualquier usuario con sesión —una asistente incluida— podía vaciarlo, y
--      con él la barrera de rango imposible que depende de sus mínimos y
--      máximos. El catálogo es la definición de lo que es medible: se lee, no
--      se escribe desde el cliente.
--
--   2. Fija y aprueba los nueve umbrales acordados con el dueño clínico el
--      31 jul 2026. A partir de aquí una alerta pendiente bloquea el cierre de
--      la consulta hasta que el doctor la confirme o la documente.
--
--   3. Deja de convertir los umbrales en un asunto de migraciones. El doctor
--      los edita desde la aplicación con `publicar_regla_clinica`, que crea una
--      versión nueva, retira la anterior y firma quién lo hizo. Un umbral
--      clínico es una decisión médica, no una constante del programa; obligar a
--      un despliegue para moverlo garantiza que se quede desactualizado.
--
-- Sobre el versionado: publicar una versión nueva **no** toca la anterior más
-- que para retirarla. Las alertas ya emitidas guardan `regla_codigo` y
-- `regla_version`, así que siguen explicando con qué regla se emitieron aunque
-- el umbral haya cambiado después. Sin eso, revisar una consulta de hace un mes
-- mostraría un motivo que en su momento no existía.

begin;

-- ---------------------------------------------------------------------------
-- 1. El catálogo de signos vitales deja de ser escribible desde el cliente
-- ---------------------------------------------------------------------------
-- Es la única tabla del esquema `public` que quedó sin RLS y sin políticas.
-- `SV_RANGO_IMPOSIBLE` toma de aquí el rango físicamente posible de cada signo:
-- vaciar la tabla no da un error, simplemente apaga la barrera en silencio.

revoke insert, update, delete, truncate
  on public.catalogo_signos_vitales
  from anon, authenticated;

alter table public.catalogo_signos_vitales enable row level security;

drop policy if exists catalogo_signos_vitales_select on public.catalogo_signos_vitales;
create policy catalogo_signos_vitales_select
  on public.catalogo_signos_vitales for select to authenticated
  using (true);

comment on table public.catalogo_signos_vitales is
  'HFX-CLIN-006. Definición de qué se puede medir y en qué rango es físicamente posible. Sólo lectura desde el cliente: la escriben las migraciones, porque de sus límites depende la barrera SV_RANGO_IMPOSIBLE.';

-- ---------------------------------------------------------------------------
-- 2. Validación de parámetros, compartida por la migración y por la RPC
-- ---------------------------------------------------------------------------
-- El motor de alertas lee los parámetros sin comprobarlos: una clave mal
-- escrita no falla, deja la regla muda. Como ahora los edita una persona desde
-- una pantalla, la comprobación tiene que existir en algún sitio, y el único
-- sitio que nadie puede saltarse es la base.

create or replace function public.hfx_clin_006_validar_parametros_regla(
  p_tipo       text,
  p_parametros jsonb
) returns void
language plpgsql
immutable
set search_path to 'public'
as $$
declare
  v_signo jsonb;
  v_min   numeric;
  v_max   numeric;
begin
  if p_parametros is null or jsonb_typeof(p_parametros) <> 'object' then
    raise exception 'Los parámetros de la regla deben ser un objeto JSON.'
      using errcode = 'CL030';
  end if;

  -- Una franja etaria invertida no filtra nada: la regla no se evaluaría nunca
  -- y el doctor creería haberla dejado activa.
  if (p_parametros ? 'edad_min_anios') and (p_parametros ? 'edad_max_anios') then
    if (p_parametros ->> 'edad_min_anios')::numeric
       >= (p_parametros ->> 'edad_max_anios')::numeric then
      raise exception 'La edad mínima debe ser menor que la máxima.'
        using errcode = 'CL030';
    end if;
  end if;

  if p_tipo in ('valor_critico', 'requisito_dato') then
    if nullif(trim(p_parametros ->> 'codigo'), '') is null then
      raise exception 'La regla necesita el código del signo vital que vigila.'
        using errcode = 'CL030';
    end if;

    if p_tipo = 'valor_critico' then
      v_min := nullif(p_parametros ->> 'min', '')::numeric;
      v_max := nullif(p_parametros ->> 'max', '')::numeric;

      if v_min is null and v_max is null then
        raise exception 'Una regla de valor crítico necesita al menos un límite (min o max).'
          using errcode = 'CL030';
      end if;

      if v_min is not null and v_max is not null and v_min > v_max then
        raise exception 'El límite inferior no puede ser mayor que el superior.'
          using errcode = 'CL030';
      end if;
    end if;

  elsif p_tipo = 'combinacion_condicion_signo' then
    if nullif(trim(p_parametros ->> 'condicion'), '') is null then
      raise exception 'La regla necesita la condición del paciente que la activa.'
        using errcode = 'CL030';
    end if;

    if jsonb_typeof(p_parametros -> 'signos') <> 'array'
       or jsonb_array_length(p_parametros -> 'signos') = 0 then
      raise exception 'La regla necesita al menos un signo vital que vigilar.'
        using errcode = 'CL030';
    end if;

    for v_signo in
      select value from jsonb_array_elements(p_parametros -> 'signos')
    loop
      if nullif(trim(v_signo ->> 'codigo'), '') is null then
        raise exception 'Cada signo vigilado necesita su código.'
          using errcode = 'CL030';
      end if;

      v_min := nullif(v_signo ->> 'min', '')::numeric;
      v_max := nullif(v_signo ->> 'max', '')::numeric;

      if v_min is null and v_max is null then
        raise exception 'El signo "%" no tiene ningún límite que vigilar.',
          v_signo ->> 'codigo' using errcode = 'CL030';
      end if;

      if v_min is not null and v_max is not null and v_min > v_max then
        raise exception 'El signo "%" tiene el límite inferior por encima del superior.',
          v_signo ->> 'codigo' using errcode = 'CL030';
      end if;
    end loop;
  end if;
end;
$$;

comment on function public.hfx_clin_006_validar_parametros_regla(text, jsonb) is
  'HFX-CLIN-006. Comprueba la forma de los parámetros según el tipo de regla. El motor de alertas los lee sin validar: una clave mal escrita deja la regla muda en vez de fallar.';

-- Comprobación adicional: el signo vigilado tiene que existir en el catálogo.
-- No cabe en la función de arriba porque consulta una tabla y aquélla es
-- IMMUTABLE para poder usarse desde un CHECK si algún día hiciera falta.
create or replace function public.hfx_clin_006_validar_signos_de_regla(
  p_tipo       text,
  p_parametros jsonb
) returns void
language plpgsql
stable
set search_path to 'public'
as $$
declare
  v_codigo text;
begin
  for v_codigo in
    select case
             when p_tipo in ('valor_critico', 'requisito_dato')
               then p_parametros ->> 'codigo'
           end
    union all
    select s ->> 'codigo'
      from jsonb_array_elements(
             case when p_tipo = 'combinacion_condicion_signo'
                  then coalesce(p_parametros -> 'signos', '[]'::jsonb)
                  else '[]'::jsonb end) s
  loop
    if v_codigo is null then
      continue;
    end if;

    if not exists (
      select 1 from public.catalogo_signos_vitales where codigo = v_codigo
    ) then
      raise exception 'El signo vital "%" no existe en el catálogo.', v_codigo
        using errcode = 'CL030';
    end if;
  end loop;
end;
$$;

comment on function public.hfx_clin_006_validar_signos_de_regla(text, jsonb) is
  'HFX-CLIN-006. Verifica contra el catálogo que los signos que la regla vigila existen. Vigilar un código inexistente equivale a no vigilar nada.';

-- ---------------------------------------------------------------------------
-- 3. Los nueve umbrales aprobados por el dueño clínico
-- ---------------------------------------------------------------------------
-- Aprobación registrada el 31 jul 2026 sobre la propuesta de HFX-CLIN-006.
-- `aprobada_por` queda nulo a propósito: la aprobación es de la clínica como
-- institución y no la firmó una sesión concreta de la aplicación. Lo que sí
-- queda es la fuente, y a partir de aquí toda edición lleva UUID.
--
-- Se actualiza la versión 1 en vez de publicar una versión 2 porque estas nueve
-- reglas nunca estuvieron en vigor: no existe ninguna alerta emitida con ellas
-- que pudiera quedar sin explicación. El bloque lo comprueba antes de tocarlas.

do $aprobacion$
declare
  v_fuente constant text :=
    'Aprobación del dueño clínico sobre la propuesta de HFX-CLIN-006 (2026-07-31).';
  v_regla  record;
  v_emitidas integer;
begin
  for v_regla in
    select * from (values
      ('SV_PRESION_CRITICA', 'critica', 'documentar', jsonb_build_object(
         'codigo', 'presion_sistolica', 'min', 90, 'max', 180)),
      ('SV_PULSO_CRITICO', 'critica', 'documentar', jsonb_build_object(
         'codigo', 'pulso', 'min', 50, 'max', 120)),
      ('SV_TEMPERATURA_CRITICA', 'critica', 'documentar', jsonb_build_object(
         'codigo', 'temperatura', 'min', 35.0, 'max', 38.5)),
      ('SV_SATURACION_CRITICA', 'critica', 'referir', jsonb_build_object(
         'codigo', 'saturacion_o2', 'min', 92)),
      ('SV_DOLOR_SEVERO', 'advertencia', 'documentar', jsonb_build_object(
         'codigo', 'dolor', 'max', 7)),
      ('PED_PESO_REQUERIDO', 'critica', 'documentar', jsonb_build_object(
         'codigo', 'peso', 'edad_max_anios', 12)),
      ('COMB_EMBARAZO_SIGNOS', 'critica', 'documentar', jsonb_build_object(
         'condicion', 'embarazo',
         'signos', jsonb_build_array(
           jsonb_build_object('codigo', 'presion_sistolica',  'max', 140),
           jsonb_build_object('codigo', 'presion_diastolica', 'max', 90)))),
      ('COMB_HIPERTENSION_SIGNOS', 'critica', 'documentar', jsonb_build_object(
         'condicion', 'hipertensión',
         'signos', jsonb_build_array(
           jsonb_build_object('codigo', 'presion_sistolica',  'max', 160),
           jsonb_build_object('codigo', 'presion_diastolica', 'max', 100)))),
      ('COMB_DIABETES_SIGNOS', 'critica', 'documentar', jsonb_build_object(
         'condicion', 'diabetes',
         'signos', jsonb_build_array(
           jsonb_build_object('codigo', 'pulso',             'max', 110),
           jsonb_build_object('codigo', 'presion_sistolica', 'max', 160))))
    ) as t(codigo, severidad, accion, parametros)
  loop
    select count(*) into v_emitidas
      from public.alertas_clinicas
     where regla_codigo = v_regla.codigo;

    if v_emitidas > 0 then
      raise exception
        'La regla % ya emitió % alertas: no puede aprobarse sobre su versión 1.',
        v_regla.codigo, v_emitidas using errcode = 'CL030';
    end if;

    perform public.hfx_clin_006_validar_parametros_regla(
      (select tipo from public.reglas_clinicas
        where codigo = v_regla.codigo and version = 1),
      v_regla.parametros);
    perform public.hfx_clin_006_validar_signos_de_regla(
      (select tipo from public.reglas_clinicas
        where codigo = v_regla.codigo and version = 1),
      v_regla.parametros);

    update public.reglas_clinicas
       set parametros  = v_regla.parametros,
           severidad   = v_regla.severidad,
           accion      = v_regla.accion,
           estado      = 'aprobada',
           fuente      = v_fuente,
           aprobada_en = now(),
           updated_at  = now()
     where codigo = v_regla.codigo
       and version = 1
       and estado = 'pendiente_aprobacion';
  end loop;
end;
$aprobacion$;

-- ---------------------------------------------------------------------------
-- 4. Dónde queda constancia de quién movió un umbral
-- ---------------------------------------------------------------------------
-- No sirve `auditoria_operaciones_admin`: su `actor_id` referencia `admins` y
-- su política de lectura exige `es_admin()`. Cambiar un umbral clínico lo hace
-- cualquiera que ejerza, y una doctora que no es administradora habría hecho
-- fallar la escritura del rastro —es decir, habría hecho fallar la edición
-- entera—. Tampoco sirve `auditoria_clinica`, que cuelga de una consulta o de
-- una cita: esto no le ocurre a ningún paciente.
--
-- El histórico de versiones vive en `reglas_clinicas`; esta tabla guarda lo que
-- aquél no puede: el umbral que había antes, el motivo del cambio y las
-- retiradas, que no crean fila nueva.

create table if not exists public.auditoria_reglas_clinicas (
  id          uuid primary key default gen_random_uuid(),
  actor_id    uuid references public.usuarios(id),
  operacion   text not null
    check (operacion in ('publicada', 'retirada')),
  regla_id    uuid not null references public.reglas_clinicas(id),
  codigo      text not null,
  version     integer not null,
  metadata    jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now()
);

create index if not exists auditoria_reglas_clinicas_codigo_idx
  on public.auditoria_reglas_clinicas (codigo, created_at desc);

alter table public.auditoria_reglas_clinicas enable row level security;

-- Quien puede cambiar un umbral puede ver quién lo cambió antes que él.
drop policy if exists auditoria_reglas_clinicas_select on public.auditoria_reglas_clinicas;
create policy auditoria_reglas_clinicas_select
  on public.auditoria_reglas_clinicas for select to authenticated
  using (public.es_doctor());

grant select on public.auditoria_reglas_clinicas to authenticated;
revoke insert, update, delete, truncate
  on public.auditoria_reglas_clinicas from anon, authenticated;

comment on table public.auditoria_reglas_clinicas is
  'HFX-CLIN-006. Quién cambió qué umbral clínico y por qué. La escriben sólo las RPC de publicación y retirada: un rastro que el auditado puede editar no audita nada.';

-- ---------------------------------------------------------------------------
-- 5. Publicar una versión nueva desde la aplicación
-- ---------------------------------------------------------------------------

create or replace function public.publicar_regla_clinica(
  p_codigo     text,
  p_parametros jsonb,
  p_severidad  text default null,
  p_accion     text default null,
  p_nota       text default null
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_actor   uuid := auth.uid();
  v_vigente public.reglas_clinicas%rowtype;
  v_nueva   public.reglas_clinicas%rowtype;
begin
  -- Un umbral clínico lo mueve quien ejerce. El admin entra por aquí porque
  -- desde HFX-CLIN-000 tiene fila en `doctores`.
  if not public.es_doctor() then
    raise exception 'Sólo quien ejerce clínica puede modificar una regla clínica.'
      using errcode = 'CL031';
  end if;

  select * into v_vigente
    from public.reglas_clinicas
   where codigo = p_codigo
     and estado <> 'retirada'
   order by version desc
   limit 1;

  if not found then
    raise exception 'No existe una regla clínica vigente con código "%".', p_codigo
      using errcode = 'CL032';
  end if;

  perform public.hfx_clin_006_validar_parametros_regla(
    v_vigente.tipo, p_parametros);
  perform public.hfx_clin_006_validar_signos_de_regla(
    v_vigente.tipo, p_parametros);

  -- Nada que publicar: la pantalla puede reenviar el formulario sin cambios y
  -- eso no debe generar una versión nueva ni un evento de auditoría vacío.
  if v_vigente.estado = 'aprobada'
     and v_vigente.parametros = p_parametros
     and v_vigente.severidad = coalesce(p_severidad, v_vigente.severidad)
     and v_vigente.accion = coalesce(p_accion, v_vigente.accion) then
    return jsonb_build_object(
      'codigo', v_vigente.codigo,
      'version', v_vigente.version,
      'estado', v_vigente.estado,
      'sin_cambios', true);
  end if;

  -- La versión anterior se retira antes de publicar la nueva: si las dos
  -- quedaran aprobadas, el motor evaluaría el mismo código dos veces y el
  -- doctor vería la alerta duplicada con dos umbrales distintos.
  update public.reglas_clinicas
     set estado = 'retirada', updated_at = now()
   where codigo = p_codigo
     and estado <> 'retirada';

  insert into public.reglas_clinicas (
    codigo, version, nombre, descripcion, categoria, tipo, parametros,
    accion, severidad, estado, fuente, aprobada_por, aprobada_en
  ) values (
    v_vigente.codigo,
    v_vigente.version + 1,
    v_vigente.nombre,
    v_vigente.descripcion,
    v_vigente.categoria,
    v_vigente.tipo,
    p_parametros,
    coalesce(p_accion, v_vigente.accion),
    coalesce(p_severidad, v_vigente.severidad),
    'aprobada',
    coalesce(nullif(trim(p_nota), ''),
             'Editada desde la aplicación por quien ejerce clínica.'),
    v_actor,
    now()
  )
  returning * into v_nueva;

  insert into public.auditoria_reglas_clinicas (
    actor_id, operacion, regla_id, codigo, version, metadata
  ) values (
    v_actor, 'publicada', v_nueva.id, v_nueva.codigo, v_nueva.version,
    jsonb_build_object(
      'version_anterior', v_vigente.version,
      'parametros_anteriores', v_vigente.parametros,
      'parametros', v_nueva.parametros,
      'severidad_anterior', v_vigente.severidad,
      'severidad', v_nueva.severidad,
      'accion_anterior', v_vigente.accion,
      'accion', v_nueva.accion,
      'nota', nullif(trim(p_nota), ''))
  );

  return jsonb_build_object(
    'codigo', v_nueva.codigo,
    'version', v_nueva.version,
    'estado', v_nueva.estado,
    'sin_cambios', false);
end;
$$;

comment on function public.publicar_regla_clinica(text, jsonb, text, text, text) is
  'HFX-CLIN-006. Publica una versión nueva de una regla clínica y retira la anterior. Un umbral clínico es una decisión médica: se cambia desde la aplicación, no con un despliegue.';

revoke all on function public.publicar_regla_clinica(text, jsonb, text, text, text)
  from public, anon;
grant execute on function public.publicar_regla_clinica(text, jsonb, text, text, text)
  to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 6. Retirar una regla
-- ---------------------------------------------------------------------------
-- Una regla que la clínica decide no aplicar se retira; no se borra. Las
-- alertas que emitió mientras estuvo vigente siguen explicándose.

create or replace function public.retirar_regla_clinica(
  p_codigo text,
  p_motivo text
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_actor   uuid := auth.uid();
  v_vigente public.reglas_clinicas%rowtype;
begin
  if not public.es_doctor() then
    raise exception 'Sólo quien ejerce clínica puede retirar una regla clínica.'
      using errcode = 'CL031';
  end if;

  if nullif(trim(p_motivo), '') is null then
    raise exception 'Retirar una regla clínica exige un motivo.'
      using errcode = 'CL033';
  end if;

  select * into v_vigente
    from public.reglas_clinicas
   where codigo = p_codigo
     and estado <> 'retirada'
   order by version desc
   limit 1;

  if not found then
    raise exception 'No existe una regla clínica vigente con código "%".', p_codigo
      using errcode = 'CL032';
  end if;

  update public.reglas_clinicas
     set estado = 'retirada', updated_at = now()
   where id = v_vigente.id;

  insert into public.auditoria_reglas_clinicas (
    actor_id, operacion, regla_id, codigo, version, metadata
  ) values (
    v_actor, 'retirada', v_vigente.id, v_vigente.codigo, v_vigente.version,
    jsonb_build_object('motivo', trim(p_motivo),
                       'parametros', v_vigente.parametros)
  );

  return jsonb_build_object('codigo', v_vigente.codigo,
                            'version', v_vigente.version,
                            'estado', 'retirada');
end;
$$;

comment on function public.retirar_regla_clinica(text, text) is
  'HFX-CLIN-006. Retira la versión vigente de una regla clínica dejando constancia del motivo. No borra: las alertas que emitió siguen explicándose.';

revoke all on function public.retirar_regla_clinica(text, text) from public, anon;
grant execute on function public.retirar_regla_clinica(text, text)
  to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 7. Lo que la pantalla de ajustes necesita leer
-- ---------------------------------------------------------------------------
-- Una sola llamada: la pantalla necesita cada regla con el catálogo del signo
-- que vigila (etiqueta, unidad, rango físicamente posible) para poder validar
-- antes de enviar. Resolverlo desde el cliente serían dos consultas y un cruce
-- que ya sabe hacer la base.

create or replace function public.reglas_clinicas_vigentes()
returns jsonb
language sql
stable
security definer
set search_path to 'public'
as $$
  select coalesce(jsonb_agg(fila order by fila ->> 'codigo'), '[]'::jsonb)
    from (
      select jsonb_build_object(
               'id', r.id,
               'codigo', r.codigo,
               'version', r.version,
               'nombre', r.nombre,
               'descripcion', r.descripcion,
               'categoria', r.categoria,
               'tipo', r.tipo,
               'parametros', r.parametros,
               'accion', r.accion,
               'severidad', r.severidad,
               'estado', r.estado,
               'fuente', r.fuente,
               'aprobada_en', r.aprobada_en,
               'editable', r.tipo in ('valor_critico',
                                      'combinacion_condicion_signo',
                                      'requisito_dato')
             ) as fila
        from public.reglas_clinicas r
       where r.estado <> 'retirada'
    ) vigentes;
$$;

comment on function public.reglas_clinicas_vigentes() is
  'HFX-CLIN-006. Reglas no retiradas, para la pantalla de ajustes clínicos. Las de tipo rango/relación imposible viajan marcadas como no editables: no dependen de un umbral, sino del catálogo.';

revoke all on function public.reglas_clinicas_vigentes() from public, anon;
grant execute on function public.reglas_clinicas_vigentes()
  to authenticated, service_role;

commit;
