-- Audit 2026-08-02 · F1-01 y F4-01: el trabajo ejecutado desde el plan se
-- borraba solo y no se cobraba.
--
-- Reproducido en vivo (§10.1 del audit): insertar la ejecución de una actividad
-- del plan directamente en `tratamientos_aplicados` —lo que hacía la pantalla
-- del plan al marcar «Completado»— y guardar después el borrador de la consulta
-- anulaba la fila. `dientes.tratamientos_aplicados_ids` nunca supo de ella y el
-- payload del cliente tampoco, y el contrato del payload es «lo que la clave
-- declara es el conjunto completo; lo que falte se anula». RD$12,000 → RD$0, en
-- el expediente y en la pre-factura.
--
-- El cliente ya no tiene esa vía: la ejecución entra por el `ConsultaCubit` y
-- viaja en el payload. Esta migración cierra la puerta en la base, para que la
-- próxima pantalla que lo intente reciba un error accionable en vez de perder
-- trabajo en silencio, y hace que la cantidad ejecutada llegue al servidor.

begin;

-- ---------------------------------------------------------------------------
-- F1-05 y F4-02 · Los dos canales del payload no se repartían igual las filas
--
-- El cliente reparte lo aplicado con una sola regla (`registroClinicoEsGeneral`):
-- va por «generales» lo que no tiene pieza y también lo que el catálogo declara
-- `arcada`/`global`, aunque arrastre un `diente_id` histórico. El servidor no
-- usaba esa regla: la barrida de la pieza reclamaba TODA fila con ese
-- `diente_id` —incluidas las que el cliente mandaba al otro canal— y el canal de
-- generales exigía `diente_id is null` para actualizarlas, así que no encontraba
-- nada y respondía `CL004`.
--
-- Escenario real: la administradora corrige el catálogo y pone «Profilaxis» como
-- alcance *arcada*. Cualquier consulta abierta que ya tuviera una profilaxis
-- anotada sobre una pieza falla en **cada** autoguardado y en el cierre, con un
-- mensaje que el doctor no puede accionar, y la cita queda atascada en
-- `en_consulta` para siempre.
--
-- Este predicado es la traducción literal del cliente. Si los dos discrepan,
-- una fila se cuenta dos veces o no la reclama nadie.
-- ---------------------------------------------------------------------------
create or replace function public.hfx_audit_es_registro_general(
  p_diente_id uuid,
  p_alcance text
)
returns boolean
language sql
immutable
as $$
  select p_diente_id is null
      or lower(coalesce(p_alcance, '')) in ('arcada', 'global');
$$;

comment on function public.hfx_audit_es_registro_general(uuid, text) is
  'Reparto de lo aplicado entre el canal de la pieza y el de «generales». Debe '
  'coincidir con `registroClinicoEsGeneral` del cliente '
  '(lib/features/consulta/data/models/alcance_registro_clinico.dart).';

-- ---------------------------------------------------------------------------
-- F2-02 (mitad cliente→servidor) · `cantidad_realizada` no viajaba en el payload
--
-- La columna existe y la UI la pide, pero `_payloadClinico` no la incluía y las
-- funciones del borrador no la leían: sólo llegaba por el insert directo, que es
-- justo el que se anulaba.
-- ---------------------------------------------------------------------------
create or replace function public.hfx_clin_002_aplicar_borrador(
  p_consulta_id uuid,
  p_actor_id uuid,
  p_payload jsonb
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_paciente_id      uuid;
  v_odontograma_id   uuid;
  v_consulta_update  boolean := false;
  v_diente           jsonb;
  v_fila             jsonb;
  v_diente_id        uuid;
  v_fdi              integer;
  v_ids              uuid[];
  v_ids_tratamiento  uuid[];
  v_id               uuid;
  v_conservados      uuid[];
  v_dientes_out      jsonb := '[]'::jsonb;
  v_recetas_out      jsonb := '[]'::jsonb;
  v_insumos_out      jsonb := '[]'::jsonb;
  v_version          integer;
  v_estado           text;
begin
  p_payload := coalesce(p_payload, '{}'::jsonb);

  select paciente_id into v_paciente_id from consultas where id = p_consulta_id;

  -- Una colección enviada como `null` o con otra forma se trata como vacía en
  -- lugar de reventar a mitad del guardado.
  if jsonb_exists(p_payload, 'dientes')
     and jsonb_typeof(p_payload -> 'dientes') <> 'array' then
    p_payload := p_payload - 'dientes';
  end if;
  if jsonb_exists(p_payload, 'recetas')
     and jsonb_typeof(p_payload -> 'recetas') <> 'array' then
    p_payload := p_payload - 'recetas';
  end if;
  if jsonb_exists(p_payload, 'insumos')
     and jsonb_typeof(p_payload -> 'insumos') <> 'array' then
    p_payload := p_payload - 'insumos';
  end if;
  if jsonb_exists(p_payload, 'documentos')
     and jsonb_typeof(p_payload -> 'documentos') <> 'array' then
    p_payload := p_payload - 'documentos';
  end if;
  if jsonb_exists(p_payload, 'temp_condiciones')
     and jsonb_typeof(p_payload -> 'temp_condiciones') <> 'array' then
    p_payload := p_payload - 'temp_condiciones';
  end if;

  -- 6.1 Cabecera de la consulta.
  if jsonb_exists(p_payload, 'motivo_consulta') then
    update consultas set motivo_consulta = p_payload ->> 'motivo_consulta'
     where id = p_consulta_id;
    v_consulta_update := true;
  end if;

  if jsonb_exists(p_payload, 'notas') then
    update consultas set notas = p_payload ->> 'notas' where id = p_consulta_id;
    v_consulta_update := true;
  end if;

  if jsonb_exists(p_payload, 'signos_vitales') then
    update consultas
       set signos_vitales = case
             when jsonb_typeof(p_payload -> 'signos_vitales') = 'null' then null
             else p_payload -> 'signos_vitales'
           end
     where id = p_consulta_id;
    v_consulta_update := true;
  end if;

  if jsonb_exists(p_payload, 'temp_condiciones') then
    update consultas
       set temp_condiciones = coalesce(
             (select array_agg(val)
                from jsonb_array_elements_text(p_payload -> 'temp_condiciones') as t(val)),
             '{}'::text[])
     where id = p_consulta_id;
    v_consulta_update := true;
  end if;

  -- 6.2 Odontograma: evaluación y piezas.
  select id into v_odontograma_id
    from odontogramas
   where consulta_id = p_consulta_id and deleted_at is null
   limit 1;

  if jsonb_exists(p_payload, 'evaluacion_clinica') and v_odontograma_id is not null then
    update odontogramas
       set evaluacion_clinica = p_payload -> 'evaluacion_clinica',
           updated_at = now()
     where id = v_odontograma_id;
  end if;

  if jsonb_exists(p_payload, 'dientes') then
    if v_odontograma_id is null then
      if jsonb_array_length(p_payload -> 'dientes') > 0 then
        raise exception 'La consulta % no tiene odontograma; no se puede guardar el hallazgo dental.', p_consulta_id
          using errcode = 'CL004';
      end if;
    else
      for v_diente in select value from jsonb_array_elements(p_payload -> 'dientes')
      loop
        v_fdi := (v_diente ->> 'fdi_code')::integer;

        select id into v_diente_id
          from dientes
         where odontograma_id = v_odontograma_id and fdi_code = v_fdi
         limit 1;

        if v_diente_id is null then
          raise exception 'La pieza % no pertenece al odontograma de la consulta %.', v_fdi, p_consulta_id
            using errcode = 'CL004';
        end if;

        -- Tratamientos ejecutados de la pieza.
        v_conservados := coalesce((
          select array_agg((f ->> 'id')::uuid)
            from jsonb_array_elements(coalesce(v_diente -> 'tratamientos', '[]'::jsonb)) as f
           where f ->> 'id' is not null), '{}'::uuid[]);

        -- Sólo se anula lo que este canal gobierna: una fila cuyo catálogo
        -- dice `arcada`/`global` la lee y la escribe el canal de «generales»,
        -- aunque arrastre un `diente_id` histórico.
        update tratamientos_aplicados ta
           set deleted_at = now(), updated_at = now()
         where ta.consulta_id = p_consulta_id
           and ta.diente_id = v_diente_id
           and ta.deleted_at is null
           and not (ta.id = any (v_conservados))
           and not public.hfx_audit_es_registro_general(
                 ta.diente_id,
                 (select t.alcance::text from tratamientos t
                   where t.id = ta.tratamiento_id));

        v_ids := '{}'::uuid[];
        for v_fila in select value from jsonb_array_elements(coalesce(v_diente -> 'tratamientos', '[]'::jsonb))
        loop
          v_id := nullif(v_fila ->> 'id', '')::uuid;

          if v_id is null then
            insert into tratamientos_aplicados (
              tratamiento_id, diente_id, consulta_id, es_continuo, esta_terminado,
              superficie, precio_aplicado, cantidad_realizada, notas, estado,
              item_plan_id, justificacion_no_planificada, doctor_ejecuta_id,
              fecha_ejecucion, created_at, updated_at
            ) values (
              (v_fila ->> 'tratamiento_id')::uuid,
              v_diente_id,
              p_consulta_id,
              coalesce((v_fila ->> 'es_continuo')::boolean, false),
              coalesce((v_fila ->> 'esta_terminado')::boolean, false),
              nullif(v_fila ->> 'superficie', '')::tipo_superficie,
              nullif(v_fila ->> 'precio_aplicado', '')::numeric,
              coalesce(nullif(v_fila ->> 'cantidad_realizada', '')::numeric, 1),
              v_fila ->> 'notas',
              coalesce(nullif(v_fila ->> 'estado', ''), 'aplicado'),
              nullif(v_fila ->> 'item_plan_id', '')::uuid,
              v_fila ->> 'justificacion_no_planificada',
              coalesce(nullif(v_fila ->> 'doctor_ejecuta_id', '')::uuid, p_actor_id),
              coalesce(nullif(v_fila ->> 'fecha_ejecucion', '')::timestamptz, now()),
              now(), now()
            ) returning id into v_id;
          else
            update tratamientos_aplicados
               set tratamiento_id = (v_fila ->> 'tratamiento_id')::uuid,
                   es_continuo = coalesce((v_fila ->> 'es_continuo')::boolean, false),
                   esta_terminado = coalesce((v_fila ->> 'esta_terminado')::boolean, false),
                   superficie = nullif(v_fila ->> 'superficie', '')::tipo_superficie,
                   precio_aplicado = nullif(v_fila ->> 'precio_aplicado', '')::numeric,
                   cantidad_realizada = coalesce(
                     nullif(v_fila ->> 'cantidad_realizada', '')::numeric,
                     cantidad_realizada),
                   notas = v_fila ->> 'notas',
                   estado = coalesce(nullif(v_fila ->> 'estado', ''), estado),
                   item_plan_id = nullif(v_fila ->> 'item_plan_id', '')::uuid,
                   justificacion_no_planificada = v_fila ->> 'justificacion_no_planificada',
                   doctor_ejecuta_id = coalesce(
                     nullif(v_fila ->> 'doctor_ejecuta_id', '')::uuid, doctor_ejecuta_id, p_actor_id),
                   fecha_ejecucion = coalesce(
                     nullif(v_fila ->> 'fecha_ejecucion', '')::timestamptz, fecha_ejecucion),
                   diente_id = v_diente_id,
                   deleted_at = null,
                   updated_at = now()
             where id = v_id and consulta_id = p_consulta_id;

            if not found then
              raise exception 'El tratamiento % no pertenece a la consulta %.', v_id, p_consulta_id
                using errcode = 'CL004';
            end if;
          end if;

          v_ids := v_ids || v_id;
        end loop;

        v_ids_tratamiento := v_ids;

        -- Hallazgos de la pieza.
        v_conservados := coalesce((
          select array_agg((f ->> 'id')::uuid)
            from jsonb_array_elements(coalesce(v_diente -> 'diagnosticos', '[]'::jsonb)) as f
           where f ->> 'id' is not null), '{}'::uuid[]);

        update diagnosticos_aplicados da
           set deleted_at = now(), updated_at = now()
         where da.consulta_id = p_consulta_id
           and da.diente_id = v_diente_id
           and da.deleted_at is null
           and not (da.id = any (v_conservados))
           and not public.hfx_audit_es_registro_general(
                 da.diente_id,
                 (select d.alcance::text from diagnosticos d
                   where d.id = da.diagnosis_id));

        v_ids := '{}'::uuid[];
        for v_fila in select value from jsonb_array_elements(coalesce(v_diente -> 'diagnosticos', '[]'::jsonb))
        loop
          v_id := nullif(v_fila ->> 'id', '')::uuid;

          if v_id is null then
            insert into diagnosticos_aplicados (
              diagnosis_id, severidad, fecha_aplicacion, notas, consulta_id,
              diente_id, superficie, origen, created_at, updated_at
            ) values (
              (v_fila ->> 'diagnosis_id')::uuid,
              (v_fila ->> 'severidad')::severidad_diagnosis,
              coalesce(nullif(v_fila ->> 'fecha_aplicacion', '')::timestamptz, now()),
              v_fila ->> 'notas',
              p_consulta_id,
              v_diente_id,
              nullif(v_fila ->> 'superficie', '')::tipo_superficie,
              coalesce(nullif(v_fila ->> 'origen', ''), 'preexistente'),
              now(), now()
            ) returning id into v_id;
          else
            -- `evaluacion_id` lo asigna el flujo de evaluación (SD-135): el
            -- borrador no debe desvincular un hallazgo de su evaluación.
            update diagnosticos_aplicados
               set diagnosis_id = (v_fila ->> 'diagnosis_id')::uuid,
                   severidad = (v_fila ->> 'severidad')::severidad_diagnosis,
                   fecha_aplicacion = coalesce(
                     nullif(v_fila ->> 'fecha_aplicacion', '')::timestamptz, fecha_aplicacion),
                   notas = v_fila ->> 'notas',
                   superficie = nullif(v_fila ->> 'superficie', '')::tipo_superficie,
                   origen = coalesce(nullif(v_fila ->> 'origen', ''), origen),
                   diente_id = v_diente_id,
                   deleted_at = null,
                   updated_at = now()
             where id = v_id and consulta_id = p_consulta_id;

            if not found then
              raise exception 'El hallazgo % no pertenece a la consulta %.', v_id, p_consulta_id
                using errcode = 'CL004';
            end if;
          end if;

          v_ids := v_ids || v_id;
        end loop;

        v_dientes_out := v_dientes_out || jsonb_build_object(
          'fdi_code', v_fdi,
          'tratamientos', to_jsonb(v_ids_tratamiento),
          'diagnosticos', to_jsonb(v_ids)
        );

        update dientes
           set tratamientos_aplicados_ids = v_ids_tratamiento,
               esta_ausente = coalesce((v_diente ->> 'esta_ausente')::boolean, false),
               observaciones = v_diente ->> 'observaciones',
               updated_at = now()
         where id = v_diente_id;
      end loop;
    end if;
  end if;

  -- 6.3 Recetas en borrador. Una emitida no se toca aquí.
  if jsonb_exists(p_payload, 'recetas') then
    v_conservados := coalesce((
      select array_agg((f ->> 'id')::uuid)
        from jsonb_array_elements(p_payload -> 'recetas') as f
       where f ->> 'id' is not null), '{}'::uuid[]);

    update recetas
       set deleted_at = now(), updated_at = now()
     where consulta_id = p_consulta_id
       and deleted_at is null
       and estado = 'borrador'
       and not (id = any (v_conservados));

    for v_fila in select value from jsonb_array_elements(p_payload -> 'recetas')
    loop
      v_id := nullif(v_fila ->> 'id', '')::uuid;

      if v_id is null then
        insert into recetas (
          consulta_id, paciente_id, doctor_id, fecha_emision,
          indicaciones_generales, justificacion_contraindicaciones,
          items_receta, estado, version, created_at, updated_at
        ) values (
          p_consulta_id,
          coalesce(nullif(v_fila ->> 'paciente_id', '')::uuid, v_paciente_id),
          coalesce(nullif(v_fila ->> 'doctor_id', '')::uuid, p_actor_id),
          coalesce(nullif(v_fila ->> 'fecha_emision', '')::timestamptz, now()),
          v_fila ->> 'indicaciones_generales',
          v_fila ->> 'justificacion_contraindicaciones',
          coalesce(v_fila -> 'items_receta', '[]'::jsonb),
          'borrador', 1, now(), now()
        ) returning id, version into v_id, v_version;
      else
        select estado, version into v_estado, v_version
          from recetas
         where id = v_id and consulta_id = p_consulta_id and deleted_at is null;

        if v_estado is null then
          raise exception 'La receta % no pertenece a la consulta %.', v_id, p_consulta_id
            using errcode = 'CL004';
        end if;

        if v_estado = 'borrador' then
          if jsonb_exists(v_fila, 'version')
             and nullif(v_fila ->> 'version', '') is not null
             and (v_fila ->> 'version')::integer <> v_version then
            raise exception 'La receta % cambió en otra pestaña (versión % ≠ %).',
              v_id, v_fila ->> 'version', v_version
              using errcode = 'CL001';
          end if;

          update recetas
             set indicaciones_generales = v_fila ->> 'indicaciones_generales',
                 justificacion_contraindicaciones = v_fila ->> 'justificacion_contraindicaciones',
                 items_receta = coalesce(v_fila -> 'items_receta', '[]'::jsonb),
                 doctor_id = coalesce(nullif(v_fila ->> 'doctor_id', '')::uuid, doctor_id, p_actor_id),
                 version = version + 1,
                 updated_at = now()
           where id = v_id
          returning version into v_version;
        end if;
      end if;

      v_recetas_out := v_recetas_out || jsonb_build_object(
        'id', v_id, 'version', v_version
      );
    end loop;
  end if;

  -- 6.4 Insumos declarados. Aquí solo se registra la intención; el stock se
  -- mueve únicamente en el cierre.
  if jsonb_exists(p_payload, 'insumos') then
    update consumos_consulta
       set deleted_at = now(), updated_at = now()
     where consulta_id = p_consulta_id
       and deleted_at is null
       and not (consumible_id = any (coalesce((
             select array_agg((f ->> 'consumible_id')::uuid)
               from jsonb_array_elements(p_payload -> 'insumos') as f
              where nullif(f ->> 'consumible_id', '') is not null
               and coalesce((f ->> 'cantidad')::integer, 0) > 0
           ), '{}'::uuid[])));

    -- El formulario permite repetir un consumible; se agrega antes de guardar.
    for v_fila in
      select jsonb_build_object(
               'consumible_id', consumible_id,
               'nombre', max(nombre),
               'cantidad', sum(cantidad))
        from (
          select (f ->> 'consumible_id')::uuid as consumible_id,
                 f ->> 'nombre' as nombre,
                 coalesce((f ->> 'cantidad')::integer, 0) as cantidad
            from jsonb_array_elements(p_payload -> 'insumos') as f
           where nullif(f ->> 'consumible_id', '') is not null
        ) i
       where cantidad > 0
       group by consumible_id
    loop
      insert into consumos_consulta (consulta_id, consumible_id, nombre, cantidad)
      values (
        p_consulta_id,
        (v_fila ->> 'consumible_id')::uuid,
        v_fila ->> 'nombre',
        (v_fila ->> 'cantidad')::integer
      )
      on conflict (consulta_id, consumible_id) where deleted_at is null
      do update set cantidad = excluded.cantidad,
                    nombre = coalesce(excluded.nombre, consumos_consulta.nombre),
                    updated_at = now();

      v_insumos_out := v_insumos_out || v_fila;
    end loop;
  end if;

  -- 6.5 Documentos ya subidos a Storage.
  if jsonb_exists(p_payload, 'documentos') then
    for v_fila in select value from jsonb_array_elements(p_payload -> 'documentos')
    loop
      if nullif(v_fila ->> 'id', '') is null then
        insert into documentos_clinicos (
          paciente_id, consulta_id, descripcion, tipo_documento, url_archivo,
          created_at, updated_at
        ) values (
          v_paciente_id,
          p_consulta_id,
          v_fila ->> 'descripcion',
          (v_fila ->> 'tipo_documento')::tipo_documento,
          v_fila ->> 'url_archivo',
          coalesce(nullif(v_fila ->> 'fecha_creacion', '')::timestamptz, now()),
          now()
        );
      end if;
    end loop;
  end if;

  if v_consulta_update then
    update consultas set updated_at = now() where id = p_consulta_id;
  end if;

  return jsonb_build_object(
    'dientes', v_dientes_out,
    'recetas', v_recetas_out,
    'insumos', v_insumos_out
  );
end;
$$;

-- Lo mismo para las ejecuciones sin pieza (alcance global o de arcada): el
-- único cambio respecto de HFX-CLIN-003 es que `cantidad_realizada` viaja.
create or replace function public.hfx_clin_003_aplicar_extras(
  p_consulta_id uuid,
  p_actor_id uuid,
  p_payload jsonb
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_fila        jsonb;
  v_conservados uuid[];
  v_codigos     text[];
  v_sistolica   numeric;
  v_diastolica  numeric;
  v_paciente    uuid;
  v_id          uuid;
  v_signos      jsonb := '{}'::jsonb;
begin
  p_payload := coalesce(p_payload, '{}'::jsonb);

  select paciente_id into v_paciente from consultas where id = p_consulta_id;

  -- 10.1 Signos vitales estructurados.
  if jsonb_exists(p_payload, 'signos_vitales_medidos')
     and jsonb_typeof(p_payload -> 'signos_vitales_medidos') = 'array' then

    v_codigos := coalesce((
      select array_agg(f ->> 'codigo')
        from jsonb_array_elements(p_payload -> 'signos_vitales_medidos') as f
       where nullif(f ->> 'codigo', '') is not null
         and nullif(f ->> 'valor', '') is not null), '{}'::text[]);

    update signos_vitales_consulta
       set deleted_at = now(), updated_at = now()
     where consulta_id = p_consulta_id
       and deleted_at is null
       and not (codigo = any (v_codigos));

    for v_fila in
      select value from jsonb_array_elements(p_payload -> 'signos_vitales_medidos')
    loop
      if nullif(v_fila ->> 'codigo', '') is null
         or nullif(v_fila ->> 'valor', '') is null then
        continue;
      end if;

      insert into signos_vitales_consulta (
        consulta_id, codigo, valor, unidad, medido_en, medido_por, origen,
        observacion, estado_validacion
      ) values (
        p_consulta_id,
        v_fila ->> 'codigo',
        (v_fila ->> 'valor')::numeric,
        coalesce(nullif(v_fila ->> 'unidad', ''),
                 (select unidad from catalogo_signos_vitales
                   where codigo = v_fila ->> 'codigo')),
        coalesce(nullif(v_fila ->> 'medido_en', '')::timestamptz, now()),
        coalesce(nullif(v_fila ->> 'medido_por', '')::uuid, p_actor_id),
        coalesce(nullif(v_fila ->> 'origen', ''), 'medido'),
        nullif(v_fila ->> 'observacion', ''),
        coalesce(nullif(v_fila ->> 'estado_validacion', ''), 'valido')
      )
      on conflict (consulta_id, codigo) where deleted_at is null
      do update set valor = excluded.valor,
                    unidad = excluded.unidad,
                    medido_en = excluded.medido_en,
                    medido_por = excluded.medido_por,
                    origen = excluded.origen,
                    observacion = excluded.observacion,
                    estado_validacion = excluded.estado_validacion,
                    updated_at = now();
    end loop;

    -- Relación imposible: se comprueba con las dos mediciones ya guardadas.
    select max(valor) filter (where codigo = 'presion_sistolica'),
           max(valor) filter (where codigo = 'presion_diastolica')
      into v_sistolica, v_diastolica
      from signos_vitales_consulta
     where consulta_id = p_consulta_id and deleted_at is null;

    if v_sistolica is not null and v_diastolica is not null
       and v_diastolica >= v_sistolica then
      raise exception 'La diastólica (%) no puede igualar ni superar la sistólica (%).',
        v_diastolica, v_sistolica
        using errcode = 'CL006';
    end if;

    -- `consultas.signos_vitales` se conserva como resumen derivado para los
    -- lectores antiguos (detalle, PDF del expediente); la tabla es la verdad.
    select coalesce(jsonb_object_agg(codigo, valor), '{}'::jsonb)
      into v_signos
      from signos_vitales_consulta
     where consulta_id = p_consulta_id and deleted_at is null;

    update consultas
       set signos_vitales = case when v_signos = '{}'::jsonb then null else v_signos end,
           updated_at = now()
     where id = p_consulta_id;
  end if;

  -- 10.2 Condiciones descubiertas durante la consulta.
  if jsonb_exists(p_payload, 'condiciones_detectadas')
     and jsonb_typeof(p_payload -> 'condiciones_detectadas') = 'array' then

    v_conservados := coalesce((
      select array_agg((f ->> 'condicion_id')::uuid)
        from jsonb_array_elements(p_payload -> 'condiciones_detectadas') as f
       where nullif(f ->> 'condicion_id', '') is not null), '{}'::uuid[]);

    update condiciones_consulta
       set deleted_at = now(), updated_at = now()
     where consulta_id = p_consulta_id
       and deleted_at is null
       and not (condicion_id = any (v_conservados));

    for v_fila in
      select value from jsonb_array_elements(p_payload -> 'condiciones_detectadas')
    loop
      if nullif(v_fila ->> 'condicion_id', '') is null then
        continue;
      end if;

      insert into condiciones_consulta (
        consulta_id, condicion_id, severidad, notas, detectada_en,
        incorporar_al_expediente, confirmada_por, confirmada_en
      ) values (
        p_consulta_id,
        (v_fila ->> 'condicion_id')::uuid,
        coalesce(nullif(v_fila ->> 'severidad', ''), 'moderada'),
        nullif(v_fila ->> 'notas', ''),
        coalesce(nullif(v_fila ->> 'detectada_en', '')::timestamptz, now()),
        coalesce((v_fila ->> 'incorporar_al_expediente')::boolean, false),
        case when coalesce((v_fila ->> 'incorporar_al_expediente')::boolean, false)
             then p_actor_id end,
        case when coalesce((v_fila ->> 'incorporar_al_expediente')::boolean, false)
             then now() end
      )
      on conflict (consulta_id, condicion_id) where deleted_at is null
      do update set severidad = excluded.severidad,
                    notas = excluded.notas,
                    incorporar_al_expediente = excluded.incorporar_al_expediente,
                    confirmada_por = excluded.confirmada_por,
                    confirmada_en = excluded.confirmada_en,
                    updated_at = now();
    end loop;
  end if;

  -- 10.3 Hallazgos y ejecuciones sin pieza: lo que el catálogo declara global o
  -- de arcada.
  if jsonb_exists(p_payload, 'generales')
     and jsonb_typeof(p_payload -> 'generales') = 'object' then

    v_conservados := coalesce((
      select array_agg((f ->> 'id')::uuid)
        from jsonb_array_elements(
               coalesce(p_payload -> 'generales' -> 'tratamientos', '[]'::jsonb)) as f
       where nullif(f ->> 'id', '') is not null), '{}'::uuid[]);

    -- Espejo exacto de la barrida de la pieza: entre las dos cubren todo el
    -- conjunto de la consulta sin solaparse.
    update tratamientos_aplicados ta
       set deleted_at = now(), updated_at = now()
     where ta.consulta_id = p_consulta_id
       and ta.deleted_at is null
       and not (ta.id = any (v_conservados))
       and public.hfx_audit_es_registro_general(
             ta.diente_id,
             (select t.alcance::text from tratamientos t
               where t.id = ta.tratamiento_id));

    for v_fila in
      select value from jsonb_array_elements(
        coalesce(p_payload -> 'generales' -> 'tratamientos', '[]'::jsonb))
    loop
      v_id := nullif(v_fila ->> 'id', '')::uuid;
      if v_id is null then
        insert into tratamientos_aplicados (
          tratamiento_id, consulta_id, precio_aplicado, cantidad_realizada,
          notas, estado, item_plan_id, justificacion_no_planificada,
          doctor_ejecuta_id, fecha_ejecucion, created_at, updated_at
        ) values (
          (v_fila ->> 'tratamiento_id')::uuid,
          p_consulta_id,
          nullif(v_fila ->> 'precio_aplicado', '')::numeric,
          coalesce(nullif(v_fila ->> 'cantidad_realizada', '')::numeric, 1),
          v_fila ->> 'notas',
          coalesce(nullif(v_fila ->> 'estado', ''), 'aplicado'),
          nullif(v_fila ->> 'item_plan_id', '')::uuid,
          v_fila ->> 'justificacion_no_planificada',
          coalesce(nullif(v_fila ->> 'doctor_ejecuta_id', '')::uuid, p_actor_id),
          coalesce(nullif(v_fila ->> 'fecha_ejecucion', '')::timestamptz, now()),
          now(), now()
        );
      else
        -- Sin `and diente_id is null`: una fila histórica de alcance arcada
        -- pegada a una pieza llega legítimamente por aquí y antes no se
        -- encontraba (0 filas → `CL004` en cada guardado). Además se normaliza
        -- —fuera pieza y superficie—, que es lo que hizo
        -- `hfx_qa_108_normalizar_alcance_historico` con el histórico: la
        -- inconsistencia se repara al pasar por este canal en vez de bloquear
        -- la consulta para siempre.
        update tratamientos_aplicados
           set tratamiento_id = (v_fila ->> 'tratamiento_id')::uuid,
               precio_aplicado = nullif(v_fila ->> 'precio_aplicado', '')::numeric,
               cantidad_realizada = coalesce(
                 nullif(v_fila ->> 'cantidad_realizada', '')::numeric,
                 cantidad_realizada),
               notas = v_fila ->> 'notas',
               estado = coalesce(nullif(v_fila ->> 'estado', ''), estado),
               item_plan_id = nullif(v_fila ->> 'item_plan_id', '')::uuid,
               justificacion_no_planificada = v_fila ->> 'justificacion_no_planificada',
               diente_id = null,
               superficie = null,
               deleted_at = null,
               updated_at = now()
         where id = v_id and consulta_id = p_consulta_id;

        if not found then
          raise exception 'El tratamiento general % no pertenece a la consulta %.',
            v_id, p_consulta_id using errcode = 'CL004';
        end if;
      end if;
    end loop;

    v_conservados := coalesce((
      select array_agg((f ->> 'id')::uuid)
        from jsonb_array_elements(
               coalesce(p_payload -> 'generales' -> 'diagnosticos', '[]'::jsonb)) as f
       where nullif(f ->> 'id', '') is not null), '{}'::uuid[]);

    update diagnosticos_aplicados da
       set deleted_at = now(), updated_at = now()
     where da.consulta_id = p_consulta_id
       and da.deleted_at is null
       and not (da.id = any (v_conservados))
       and public.hfx_audit_es_registro_general(
             da.diente_id,
             (select d.alcance::text from diagnosticos d
               where d.id = da.diagnosis_id));

    for v_fila in
      select value from jsonb_array_elements(
        coalesce(p_payload -> 'generales' -> 'diagnosticos', '[]'::jsonb))
    loop
      v_id := nullif(v_fila ->> 'id', '')::uuid;
      if v_id is null then
        insert into diagnosticos_aplicados (
          diagnosis_id, severidad, fecha_aplicacion, notas, consulta_id,
          origen, created_at, updated_at
        ) values (
          (v_fila ->> 'diagnosis_id')::uuid,
          (v_fila ->> 'severidad')::severidad_diagnosis,
          coalesce(nullif(v_fila ->> 'fecha_aplicacion', '')::timestamptz, now()),
          v_fila ->> 'notas',
          p_consulta_id,
          coalesce(nullif(v_fila ->> 'origen', ''), 'preexistente'),
          now(), now()
        );
      else
        update diagnosticos_aplicados
           set diagnosis_id = (v_fila ->> 'diagnosis_id')::uuid,
               severidad = (v_fila ->> 'severidad')::severidad_diagnosis,
               notas = v_fila ->> 'notas',
               origen = coalesce(nullif(v_fila ->> 'origen', ''), origen),
               diente_id = null,
               superficie = null,
               deleted_at = null,
               updated_at = now()
         where id = v_id and consulta_id = p_consulta_id;

        if not found then
          raise exception 'El hallazgo general % no pertenece a la consulta %.',
            v_id, p_consulta_id using errcode = 'CL004';
        end if;
      end if;
    end loop;
  end if;

  -- 10.4 Receta: el bloqueo absoluto vive aquí, no solo en la pantalla.
  for v_fila in
    select r.items_receta
      from recetas r
     where r.consulta_id = p_consulta_id
       and r.deleted_at is null
       and r.estado = 'borrador'
  loop
    perform public.hfx_clin_003_validar_receta(p_consulta_id, v_fila, false);
  end loop;

  return public.hfx_clin_003_evaluar_alertas(p_consulta_id);
end;
$$;

-- ---------------------------------------------------------------------------
-- F1-01 · Cerrar la escritura directa a `tratamientos_aplicados` de una consulta
--         abierta
--
-- Mientras la consulta está abierta, su conjunto de procedimientos lo gobierna
-- el payload del borrador. Una fila insertada por fuera es invisible para el
-- cliente y el siguiente guardado la anula. El patrón es el de HFX-CLIN-007:
-- si una escritura no puede ser correcta, que no sea posible.
--
-- Una consulta ya finalizada no tiene borrador que la contradiga, así que sus
-- filas siguen siendo editables por las vías de siempre.
-- ---------------------------------------------------------------------------
create or replace function public.hfx_audit_proteger_ejecucion_consulta()
returns trigger
language plpgsql
set search_path to 'public'
as $$
declare
  v_consulta_id uuid;
  v_abierta     boolean;
begin
  if tg_op = 'DELETE' then
    v_consulta_id := old.consulta_id;
  else
    v_consulta_id := new.consulta_id;
  end if;

  -- Sólo se vigila al cliente. Las RPC clínicas son SECURITY DEFINER y su
  -- cuerpo corre como el dueño de la función, no como `authenticated`: son
  -- ellas las que reciben el conjunto completo y pueden escribirlo entero.
  --
  -- No se usa `es_contexto_interno()` a propósito: esa función mira
  -- `session_user`, que en una petición de PostgREST sigue siendo el
  -- autenticador aunque la función sea SECURITY DEFINER, así que devolvería
  -- `false` dentro de las propias RPC y este trigger las bloquearía a ellas.
  if current_user not in ('authenticated', 'anon')
     or v_consulta_id is null then
    if tg_op = 'DELETE' then return old; else return new; end if;
  end if;

  select finalizada is not true
    into v_abierta
    from consultas
   where id = v_consulta_id and deleted_at is null;

  if coalesce(v_abierta, false) then
    raise exception
      'Los procedimientos de una consulta abierta se registran desde la propia '
      'consulta, no escribiendo la tabla: cualquier otra vía la anula el '
      'siguiente guardado.'
      using errcode = '42501';
  end if;

  if tg_op = 'DELETE' then return old; else return new; end if;
end;
$$;

drop trigger if exists tratamientos_aplicados_proteger_consulta
  on public.tratamientos_aplicados;
create trigger tratamientos_aplicados_proteger_consulta
  before insert or update or delete on public.tratamientos_aplicados
  for each row execute function public.hfx_audit_proteger_ejecucion_consulta();

commit;
