


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "btree_gist" WITH SCHEMA "public";






CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."alcance" AS ENUM (
    'puntual',
    'diente',
    'arcada',
    'global'
);


ALTER TYPE "public"."alcance" OWNER TO "postgres";


CREATE TYPE "public"."categoria_condicion" AS ENUM (
    'temporal',
    'cronica'
);


ALTER TYPE "public"."categoria_condicion" OWNER TO "postgres";


CREATE TYPE "public"."categoria_diagnosis" AS ENUM (
    'caries',
    'periodontitis',
    'endodoncia',
    'ortodoncia',
    'protesis',
    'cirurgia_oral',
    'implantes',
    'estetica',
    'patologia_atm'
);


ALTER TYPE "public"."categoria_diagnosis" OWNER TO "postgres";


CREATE TYPE "public"."efecto_adverso" AS ENUM (
    'nauseas',
    'vomitos',
    'diarrea',
    'dolor_cabeza',
    'fatiga',
    'mareo',
    'somnolencia',
    'reaccion_alergica',
    'erupcion_cutanea',
    'anafilaxia',
    'xerostomia',
    'hiperplasia_gingival',
    'sabor_metalico',
    'parestesia',
    'sangrado_aumentado',
    'necrosis_osea',
    'arritmia',
    'sangrado_severo'
);


ALTER TYPE "public"."efecto_adverso" OWNER TO "postgres";


CREATE TYPE "public"."efecto_secundario" AS ENUM (
    'inflamacion',
    'sangrado_leve',
    'sensibilidad_termica',
    'boca_seca',
    'adormecimiento_prolongado',
    'trismo',
    'hematoma',
    'alteracion_gusto',
    'alveolitis',
    'dolor_cabeza',
    'mareos',
    'aumento_apetito',
    'fatiga',
    'nauseas',
    'vomitos',
    'diarrea',
    'reacciones_alergicas',
    'cambios_animo',
    'vision_borrosa',
    'insomnio',
    'somnolencia',
    'ninguno',
    'dolor_abdominal'
);


ALTER TYPE "public"."efecto_secundario" OWNER TO "postgres";


CREATE TYPE "public"."estado_cita" AS ENUM (
    'programada',
    'confirmada',
    'cancelada',
    'completada',
    'no_asistida',
    'en_espera',
    'en_consulta',
    'no_asistio',
    'pendiente'
);


ALTER TYPE "public"."estado_cita" OWNER TO "postgres";


CREATE TYPE "public"."estado_compra" AS ENUM (
    'pendiente',
    'completada',
    'cancelada',
    'recibida',
    'envíada',
    'recibido'
);


ALTER TYPE "public"."estado_compra" OWNER TO "postgres";


CREATE TYPE "public"."estado_consumible" AS ENUM (
    'disponible',
    'bajo_stock',
    'agotado',
    'descontinuado'
);


ALTER TYPE "public"."estado_consumible" OWNER TO "postgres";


CREATE TYPE "public"."estado_cuenta" AS ENUM (
    'abierta',
    'pendiente',
    'saldada',
    'cancelada'
);


ALTER TYPE "public"."estado_cuenta" OWNER TO "postgres";


CREATE TYPE "public"."estado_cuota" AS ENUM (
    'pendiente',
    'pagada',
    'atrasada',
    'vencida',
    'cancelada'
);


ALTER TYPE "public"."estado_cuota" OWNER TO "postgres";


CREATE TYPE "public"."estado_item_plan" AS ENUM (
    'propuesto',
    'aceptado',
    'rechazado',
    'pendiente',
    'en_proceso',
    'completado',
    'cancelado'
);


ALTER TYPE "public"."estado_item_plan" OWNER TO "postgres";


CREATE TYPE "public"."estado_pago" AS ENUM (
    'pendiente',
    'parcial',
    'completado',
    'fallido',
    'cancelado',
    'reembolsado',
    'vencido'
);


ALTER TYPE "public"."estado_pago" OWNER TO "postgres";


CREATE TYPE "public"."estado_plan_tratamiento" AS ENUM (
    'borrador',
    'propuesto',
    'aceptado',
    'rechazado',
    'en_proceso',
    'completado',
    'cancelado'
);


ALTER TYPE "public"."estado_plan_tratamiento" OWNER TO "postgres";


CREATE TYPE "public"."estatus_persona" AS ENUM (
    'activo',
    'inactivo',
    'suspendido'
);


ALTER TYPE "public"."estatus_persona" OWNER TO "postgres";


CREATE TYPE "public"."genero" AS ENUM (
    'masculino',
    'femenino',
    'otro',
    'no_prefiere_decir'
);


ALTER TYPE "public"."genero" OWNER TO "postgres";


CREATE TYPE "public"."metodo_pago" AS ENUM (
    'tarjeta_credito',
    'tarjeta_debito',
    'transferencia_bancaria',
    'efectivo'
);


ALTER TYPE "public"."metodo_pago" OWNER TO "postgres";


CREATE TYPE "public"."modo_pago" AS ENUM (
    'contado',
    'credito'
);


ALTER TYPE "public"."modo_pago" OWNER TO "postgres";


CREATE TYPE "public"."rol_usuario" AS ENUM (
    'admin',
    'doctor',
    'asistente'
);


ALTER TYPE "public"."rol_usuario" OWNER TO "postgres";


CREATE TYPE "public"."severidad_diagnosis" AS ENUM (
    'leve',
    'moderada',
    'grave'
);


ALTER TYPE "public"."severidad_diagnosis" OWNER TO "postgres";


CREATE TYPE "public"."tipo_atencion_clinica" AS ENUM (
    'evaluacion',
    'consulta'
);


ALTER TYPE "public"."tipo_atencion_clinica" OWNER TO "postgres";


CREATE TYPE "public"."tipo_condicion" AS ENUM (
    'fisiologica',
    'patologica',
    'quirurgica',
    'genetica',
    'alergica'
);


ALTER TYPE "public"."tipo_condicion" OWNER TO "postgres";


CREATE TYPE "public"."tipo_contraindicacion" AS ENUM (
    'absoluta',
    'relativa'
);


ALTER TYPE "public"."tipo_contraindicacion" OWNER TO "postgres";


CREATE TYPE "public"."tipo_documento" AS ENUM (
    'video',
    'imagen',
    'radiografia'
);


ALTER TYPE "public"."tipo_documento" OWNER TO "postgres";


CREATE TYPE "public"."tipo_movimiento" AS ENUM (
    'ingreso',
    'egreso'
);


ALTER TYPE "public"."tipo_movimiento" OWNER TO "postgres";


CREATE TYPE "public"."tipo_paciente" AS ENUM (
    'emergencia',
    'integrado'
);


ALTER TYPE "public"."tipo_paciente" OWNER TO "postgres";


CREATE TYPE "public"."tipo_sangre" AS ENUM (
    'a_positivo',
    'a_negativo',
    'b_positivo',
    'b_negativo',
    'ab_positivo',
    'ab_negativo',
    'o_positivo',
    'o_negativo',
    'desconocido'
);


ALTER TYPE "public"."tipo_sangre" OWNER TO "postgres";


CREATE TYPE "public"."tipo_superficie" AS ENUM (
    'mesial',
    'distal',
    'vestibular',
    'lingual',
    'palatina',
    'oclusal',
    'incisal'
);


ALTER TYPE "public"."tipo_superficie" OWNER TO "postgres";


CREATE TYPE "public"."tipo_suplidor" AS ENUM (
    'consumible',
    'servicio',
    'mixto'
);


ALTER TYPE "public"."tipo_suplidor" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."actualizar_paciente"("p_paciente_id" "uuid", "p_version" integer, "p_payload" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_version_actual integer;
  v_cedula         text;
begin
  if not public.es_contexto_interno()
     and (auth.uid() is null
          or not (public.es_admin() or public.es_doctor() or public.es_asistente())) then
    raise exception 'Sesión activa requerida para editar un paciente.'
      using errcode = '42501';
  end if;

  select version into v_version_actual
    from public.pacientes
   where id = p_paciente_id and deleted_at is null
   for update;
  if not found then
    raise exception 'El paciente no existe o fue dado de baja.' using errcode = 'P0002';
  end if;

  if p_version is not null and p_version <> v_version_actual then
    raise exception
      'La ficha cambió mientras la editabas. Recárgala para no perder lo que guardó el otro actor.'
      using errcode = 'CL019';
  end if;

  v_cedula := public.hfx_clin_004_normalizar_cedula(p_payload ->> 'cedula');
  if v_cedula is not null and exists (
    select 1 from public.personas
     where deleted_at is null
       and id <> p_paciente_id
       and public.hfx_clin_004_normalizar_cedula(cedula) = v_cedula
  ) then
    raise exception 'Ya existe otro registro con esa cédula.' using errcode = 'CL017';
  end if;

  update public.personas
     set nombre = coalesce(nullif(btrim(coalesce(p_payload ->> 'nombre', '')), ''), nombre),
         apellido = coalesce(nullif(btrim(coalesce(p_payload ->> 'apellido', '')), ''), apellido),
         fecha_nacimiento = coalesce((p_payload ->> 'fecha_nacimiento')::date, fecha_nacimiento),
         cedula = coalesce(p_payload ->> 'cedula', cedula),
         estatus = coalesce(
           nullif(p_payload ->> 'estatus', '')::public.estatus_persona, estatus
         ),
         updated_at = now()
   where id = p_paciente_id;

  update public.pacientes
     set genero = coalesce(nullif(p_payload ->> 'genero', '')::public.genero, genero),
         tipo_paciente = coalesce(
           nullif(p_payload ->> 'tipo_paciente', '')::public.tipo_paciente, tipo_paciente
         ),
         trabajo = coalesce(p_payload ->> 'trabajo', trabajo),
         referencia = coalesce(p_payload ->> 'referencia', referencia),
         peso = coalesce((p_payload ->> 'peso')::numeric, peso),
         altura = coalesce((p_payload ->> 'altura')::numeric, altura),
         -- Las columnas `foto_*` no se tocan: su única ruta de escritura es
         -- `PacienteFotoStorage`, que las mantiene en sincronía con Storage.
         version = version + 1,
         updated_at = now()
   where id = p_paciente_id;

  if p_payload ? 'contactos' then
    perform public.hfx_clin_004_sincronizar_contactos(
      p_paciente_id, p_payload -> 'contactos'
    );
  end if;

  select version into v_version_actual
    from public.pacientes where id = p_paciente_id;

  return jsonb_build_object('paciente_id', p_paciente_id, 'version', v_version_actual);
end;
$$;


ALTER FUNCTION "public"."actualizar_paciente"("p_paciente_id" "uuid", "p_version" integer, "p_payload" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."actualizar_paciente"("p_paciente_id" "uuid", "p_version" integer, "p_payload" "jsonb") IS 'HFX-CLIN-004. Actualización transaccional con versión optimista: o se aplica entera, o no queda ficha parcial.';



CREATE OR REPLACE FUNCTION "public"."actualizar_stock_por_compra"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    IF (NEW.estado = 'recibida' AND OLD.estado != 'recibida') THEN
        UPDATE consumibles c
        SET stock_actual = c.stock_actual + cc.cantidad
        FROM consumibles_compras cc
        WHERE cc.consumible_id = c.id AND cc.compra_id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."actualizar_stock_por_compra"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ajustar_stock_consumible"("p_consumible_id" "uuid", "p_nuevo_stock" integer, "p_motivo" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if not public.es_contexto_interno()
     and (auth.uid() is null or not public.es_admin()) then
    raise exception 'Capacidad administrativa requerida.' using errcode = '42501';
  end if;
  perform public.hfx_base_ajustar_stock_consumible(
    p_consumible_id, p_nuevo_stock, p_motivo
  );
end;
$$;


ALTER FUNCTION "public"."ajustar_stock_consumible"("p_consumible_id" "uuid", "p_nuevo_stock" integer, "p_motivo" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."asiste_a_doctor"("p_doctor_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1 from public.doctor_asistentes da
     where da.asistente_id = auth.uid()
       and da.doctor_id = p_doctor_id
  );
$$;


ALTER FUNCTION "public"."asiste_a_doctor"("p_doctor_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."asiste_a_doctor"("p_doctor_id" "uuid") IS 'true si quien consulta es asistente asignado a ese doctor. Es el alcance de la agenda de una asistente: lo administrativo de los doctores a los que asiste, y de nadie más.';



CREATE OR REPLACE FUNCTION "public"."bloquear_cancelacion_con_consulta_abierta"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
begin
  if new.estado = 'cancelada'::estado_cita
     and (old.estado is distinct from new.estado)
     and exists (
       select 1
       from consultas c
       where c.cita_id = new.id
         and c.deleted_at is null
         and c.finalizada is not true
     )
  then
    raise exception
      'La cita % tiene una consulta en curso: finaliza o elimina la consulta antes de cancelarla.',
      new.id
      using errcode = 'P0001';
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."bloquear_cancelacion_con_consulta_abierta"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."bloquear_cancelacion_con_consulta_abierta"() IS 'SD-160: impide cancelar una cita mientras su consulta siga abierta.';



CREATE OR REPLACE FUNCTION "public"."cancelar_citas_paciente_inactivo"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
begin
  -- Solo la TRANSICIÓN a inactivo cancela. La app manda `estatus` en cada
  -- update de persona, así que sin esta comprobación un simple cambio de
  -- teléfono en un paciente ya inactivo volvería a barrer su agenda.
  if new.estatus = 'inactivo'::estatus_persona
     and old.estatus is distinct from new.estatus
  then
    update citas
       set estado     = 'cancelada'::estado_cita,
           updated_at = now()
     where persona_id = new.id
       and deleted_at is null
       and fecha_hora > now()
       -- Estados vivos y anteriores a la atención. `en_consulta` queda fuera a
       -- propósito: si al paciente lo están atendiendo ahora mismo, un cambio
       -- administrativo no le cierra la cita por debajo. Los terminales
       -- (completada, cancelada, no_asistio, no_asistida) tampoco se tocan.
       and estado in (
             'programada'::estado_cita,
             'confirmada'::estado_cita,
             'en_espera'::estado_cita
           )
       -- Regla de SD-160: no existe cita cancelada con consulta abierta. Sin
       -- este filtro chocaríamos contra
       -- `tr_bloquear_cancelacion_con_consulta_abierta`, cuyo P0001 volvería a
       -- abortar la desactivación del paciente: cambiaríamos un fallo
       -- permanente por uno intermitente y mucho peor de diagnosticar.
       --
       -- Decisión: esas citas se dejan VIVAS, no se silencian ni se marcan.
       -- Su consulta está en curso; la cierra el flujo clínico, que es quien
       -- sabe qué se hizo. Desactivar al paciente no puede reescribir un acto
       -- clínico en marcha.
       and not exists (
             select 1
             from consultas c
             where c.cita_id = citas.id
               and c.deleted_at is null
               and c.finalizada is not true
           );
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."cancelar_citas_paciente_inactivo"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."cancelar_citas_paciente_inactivo"() IS 'SD-169: al pasar una persona a inactivo, cancela sus citas futuras todavía vivas (programada, confirmada, en_espera). Excluye en_consulta y las citas con consulta abierta, que se dejan activas para que las cierre el flujo clínico (regla de SD-160).';



CREATE OR REPLACE FUNCTION "public"."cerrar_consulta"("p_consulta_id" "uuid", "p_version" integer DEFAULT NULL::integer, "p_payload" "jsonb" DEFAULT '{}'::"jsonb", "p_idempotencia_key" "text" DEFAULT NULL::"text", "p_metodo_pago" "text" DEFAULT 'contado'::"text", "p_nota" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_actor_id    uuid;
  v_version     integer;
  v_finalizada  boolean;
  v_cita_id     uuid;
  v_cierre_key  text;
  v_consumo     record;
  v_stock       integer;
  v_nombre      text;
  v_cuenta_id   uuid;
  v_recetas     integer := 0;
  v_facturables integer := 0;
  v_condiciones integer := 0;
begin
  v_actor_id := public.hfx_clin_002_actor_clinico(p_consulta_id);

  select version, coalesce(finalizada, false), cita_id, cierre_key
    into v_version, v_finalizada, v_cita_id, v_cierre_key
    from consultas
   where id = p_consulta_id and deleted_at is null
     for update;

  if v_finalizada then
    if p_idempotencia_key is null
       or v_cierre_key is null
       or v_cierre_key = p_idempotencia_key then
      return public.hfx_clin_002_resultado_cierre(p_consulta_id);
    end if;

    raise exception 'La consulta % ya fue finalizada por otro cierre.', p_consulta_id
      using errcode = 'CL002';
  end if;

  if p_version is not null and p_version <> v_version then
    raise exception 'La consulta cambió en otra sesión (versión % ≠ %). Recarga antes de cerrar.',
      p_version, v_version
      using errcode = 'CL001';
  end if;

  if v_cita_id is not null then
    perform 1 from citas where id = v_cita_id for update;
  end if;

  perform public.hfx_clin_002_aplicar_borrador(p_consulta_id, v_actor_id, p_payload);
  perform public.hfx_clin_003_aplicar_extras(p_consulta_id, v_actor_id, p_payload);

  -- Barreras clínicas antes de mover inventario o dinero: si algo falta, la
  -- consulta sigue abierta y nada cambió.
  perform public.hfx_clin_003_barreras_de_cierre(p_consulta_id);

  v_condiciones := public.hfx_clin_003_incorporar_condiciones(p_consulta_id);

  for v_consumo in
    select cc.consumible_id, cc.cantidad, cc.nombre
      from consumos_consulta cc
     where cc.consulta_id = p_consulta_id and cc.deleted_at is null
     order by cc.consumible_id
  loop
    select c.stock_actual, c.nombre into v_stock, v_nombre
      from consumibles c
     where c.id = v_consumo.consumible_id and c.deleted_at is null
       for update;

    if v_stock is null then
      raise exception 'El consumible % ya no está disponible en el inventario.',
        coalesce(v_consumo.nombre, v_consumo.consumible_id::text)
        using errcode = 'CL004';
    end if;

    if v_stock < v_consumo.cantidad then
      raise exception 'Stock insuficiente de %: quedan % y la consulta consume %.',
        coalesce(v_nombre, v_consumo.nombre, v_consumo.consumible_id::text),
        v_stock, v_consumo.cantidad
        using errcode = 'CL003';
    end if;

    insert into movimientos_stock_consumible (
      consumible_id, diferencia, motivo, creado_por, consulta_id,
      stock_anterior, stock_nuevo
    ) values (
      v_consumo.consumible_id, -v_consumo.cantidad, 'consumoClinico',
      v_actor_id, p_consulta_id, 0, 0
    )
    on conflict (consulta_id, consumible_id) where consulta_id is not null
    do nothing;
  end loop;

  update recetas
     set estado = 'emitida',
         emitida_at = now(),
         fecha_emision = coalesce(fecha_emision, now()),
         version = version + 1,
         updated_at = now()
   where consulta_id = p_consulta_id
     and deleted_at is null
     and estado = 'borrador'
     and jsonb_array_length(coalesce(items_receta, '[]'::jsonb)) > 0;
  get diagnostics v_recetas = row_count;

  update recetas
     set deleted_at = now(), updated_at = now()
   where consulta_id = p_consulta_id
     and deleted_at is null
     and estado = 'borrador';

  select count(*) into v_facturables
    from tratamientos_aplicados
   where consulta_id = p_consulta_id
     and deleted_at is null
     and coalesce(estado, 'aplicado') <> 'indicado';

  if v_facturables > 0 then
    v_cuenta_id := public.hfx_base_finalizar_consulta(p_consulta_id, p_metodo_pago, p_nota);
  elsif v_cita_id is not null then
    update citas
       set estado = 'completada'::estado_cita, updated_at = now()
     where id = v_cita_id
       and estado <> 'completada'::estado_cita
       and estado <> 'cancelada'::estado_cita;
  end if;

  update consultas
     set finalizada = true,
         finalizada_at = now(),
         cerrada_por = v_actor_id,
         cierre_key = p_idempotencia_key,
         version = version + 1,
         updated_at = now()
   where id = p_consulta_id;

  insert into auditoria_clinica (consulta_id, evento, actor_id, rol, metadata)
  values (
    p_consulta_id,
    'consulta_cerrada',
    v_actor_id,
    case when public.es_admin() then 'admin' else 'doctor' end,
    jsonb_build_object(
      'cuenta_id', v_cuenta_id,
      'recetas_emitidas', v_recetas,
      'condiciones_incorporadas', v_condiciones,
      'idempotencia_key', p_idempotencia_key
    )
  );

  return public.hfx_clin_002_resultado_cierre(p_consulta_id);
end;
$$;


ALTER FUNCTION "public"."cerrar_consulta"("p_consulta_id" "uuid", "p_version" integer, "p_payload" "jsonb", "p_idempotencia_key" "text", "p_metodo_pago" "text", "p_nota" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."corregir_consulta_ajena"("p_consulta_id" "uuid", "p_cambios" "jsonb", "p_motivo" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_consulta public.consultas%rowtype;
  v_antes jsonb;
  v_despues jsonb;
begin
  if auth.uid() is null or not public.es_admin() then
    raise exception 'Capacidad administrativa requerida.' using errcode = '42501';
  end if;
  if length(btrim(coalesce(p_motivo, ''))) < 10 then
    raise exception 'La corrección requiere un motivo de al menos 10 caracteres.'
      using errcode = '22023';
  end if;
  if p_cambios - array['motivo_consulta', 'notas'] <> '{}'::jsonb then
    raise exception 'La corrección contiene campos no autorizados.'
      using errcode = '22023';
  end if;

  select * into v_consulta from public.consultas
   where id = p_consulta_id and deleted_at is null for update;
  if not found then
    raise exception 'La consulta no existe.' using errcode = 'P0002';
  end if;
  if v_consulta.doctor_id = auth.uid() then
    raise exception 'La consulta propia se corrige por el flujo clínico normal.'
      using errcode = '22023';
  end if;

  v_antes := jsonb_build_object(
    'motivo_consulta', v_consulta.motivo_consulta, 'notas', v_consulta.notas
  );
  update public.consultas
     set motivo_consulta = case when p_cambios ? 'motivo_consulta'
                            then p_cambios->>'motivo_consulta'
                            else motivo_consulta end,
         notas = case when p_cambios ? 'notas'
                 then p_cambios->>'notas' else notas end,
         updated_at = now()
   where id = p_consulta_id;
  select jsonb_build_object(
    'motivo_consulta', motivo_consulta, 'notas', notas
  ) into v_despues from public.consultas where id = p_consulta_id;

  insert into public.auditoria_correcciones_clinicas (
    consulta_id, autor_original_id, corregido_por, motivo,
    datos_anteriores, datos_nuevos
  ) values (
    p_consulta_id, v_consulta.doctor_id, auth.uid(), btrim(p_motivo),
    v_antes, v_despues
  );
end;
$$;


ALTER FUNCTION "public"."corregir_consulta_ajena"("p_consulta_id" "uuid", "p_cambios" "jsonb", "p_motivo" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."crear_consulta_completa"("p_paciente_id" "uuid", "p_doctor_id" "uuid", "p_cita_id" "uuid", "p_fecha" timestamp with time zone, "p_motivo_consulta" "text", "p_temp_condiciones" "jsonb", "p_dientes" "jsonb", "p_documentos" "jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_cita public.citas%rowtype;
begin
  if not public.es_contexto_interno()
     and (auth.uid() is null or not public.es_doctor()) then
    raise exception 'Sesión clínica activa requerida.' using errcode = '42501';
  end if;
  if not public.es_contexto_interno()
     and p_doctor_id is distinct from auth.uid() then
    raise exception 'No puede firmar una consulta como otro doctor.'
      using errcode = '42501';
  end if;

  select * into v_cita
    from public.citas
   where id = p_cita_id and deleted_at is null
   for update;
  if not found then
    raise exception 'La cita no existe o fue eliminada.' using errcode = 'P0002';
  end if;
  if v_cita.doctor_id is distinct from p_doctor_id
     or v_cita.persona_id is distinct from p_paciente_id then
    raise exception 'La cita no pertenece al doctor y paciente indicados.'
      using errcode = '42501';
  end if;
  if v_cita.estado::text in ('cancelada', 'completada') then
    raise exception 'El estado de la cita no permite iniciar una consulta.'
      using errcode = '55000';
  end if;

  return public.hfx_base_crear_consulta_completa(
    p_paciente_id, p_doctor_id, p_cita_id, p_fecha, p_motivo_consulta,
    p_temp_condiciones, p_dientes, p_documentos
  );
end;
$$;


ALTER FUNCTION "public"."crear_consulta_completa"("p_paciente_id" "uuid", "p_doctor_id" "uuid", "p_cita_id" "uuid", "p_fecha" timestamp with time zone, "p_motivo_consulta" "text", "p_temp_condiciones" "jsonb", "p_dientes" "jsonb", "p_documentos" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."crear_consulta_completa"("p_paciente_id" "uuid", "p_doctor_id" "uuid", "p_cita_id" "uuid", "p_fecha" timestamp with time zone, "p_motivo_consulta" "text", "p_temp_condiciones" "jsonb", "p_dientes" "jsonb", "p_documentos" "jsonb", "p_tipo_atencion" "public"."tipo_atencion_clinica") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_consulta_id uuid;
begin
  v_consulta_id := public.crear_consulta_completa(
    p_paciente_id,
    p_doctor_id,
    p_cita_id,
    p_fecha,
    p_motivo_consulta,
    p_temp_condiciones,
    p_dientes,
    p_documentos
  );

  update public.consultas
     set tipo_atencion = p_tipo_atencion,
         updated_at = now()
   where id = v_consulta_id;

  return v_consulta_id;
end;
$$;


ALTER FUNCTION "public"."crear_consulta_completa"("p_paciente_id" "uuid", "p_doctor_id" "uuid", "p_cita_id" "uuid", "p_fecha" timestamp with time zone, "p_motivo_consulta" "text", "p_temp_condiciones" "jsonb", "p_dientes" "jsonb", "p_documentos" "jsonb", "p_tipo_atencion" "public"."tipo_atencion_clinica") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."debe_ocultar_contacto_paciente"("p_persona_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
    SELECT
        es_doctor_no_admin()
        AND EXISTS (SELECT 1 FROM pacientes p WHERE p.id = p_persona_id);
$$;


ALTER FUNCTION "public"."debe_ocultar_contacto_paciente"("p_persona_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."debe_ocultar_contacto_paciente"("p_persona_id" "uuid") IS 'true si quien consulta es un doctor regular (no admin) y la persona referenciada es un paciente. Usado para enmascarar cédula/teléfono/dirección/referencia en las vistas *_seguro.';



CREATE OR REPLACE FUNCTION "public"."es_admin"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select auth.uid() is not null and exists (
    select 1
      from public.usuarios u
      join public.admins a on a.id = u.id and a.deleted_at is null
     where u.id = auth.uid() and u.deleted_at is null
  );
$$;


ALTER FUNCTION "public"."es_admin"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."es_asistente"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select auth.uid() is not null and exists (
    select 1
      from public.usuarios u
      join public.asistentes a on a.id = u.id and a.deleted_at is null
     where u.id = auth.uid() and u.deleted_at is null
  );
$$;


ALTER FUNCTION "public"."es_asistente"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."es_contexto_interno"() RETURNS boolean
    LANGUAGE "sql" STABLE
    SET "search_path" TO ''
    AS $$
  select session_user in ('postgres', 'service_role')
     and current_setting('role', true) in ('none', 'postgres', 'service_role');
$$;


ALTER FUNCTION "public"."es_contexto_interno"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."es_doctor"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select auth.uid() is not null and exists (
    select 1
      from public.usuarios u
      join public.doctores d on d.id = u.id and d.deleted_at is null
     where u.id = auth.uid() and u.deleted_at is null
  );
$$;


ALTER FUNCTION "public"."es_doctor"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."es_doctor_no_admin"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
    SELECT es_doctor() AND NOT es_admin();
$$;


ALTER FUNCTION "public"."es_doctor_no_admin"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."es_doctor_no_admin"() IS 'Distingue un doctor regular de un admin (que también es doctor por herencia). Necesario porque la regla de visibilidad de pacientes difiere entre ambos.';



CREATE OR REPLACE FUNCTION "public"."finalizar_consulta"("p_consulta_id" "uuid", "p_metodo_pago" "text" DEFAULT 'contado'::"text", "p_nota" "text" DEFAULT NULL::"text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if not public.es_contexto_interno()
     and (
       auth.uid() is null
       or not public.puede_editar_consulta_propia(p_consulta_id)
     ) then
    raise exception 'Solo el autor clínico activo puede finalizar la consulta.'
      using errcode = '42501';
  end if;
  return public.hfx_base_finalizar_consulta(
    p_consulta_id, p_metodo_pago, p_nota
  );
end;
$$;


ALTER FUNCTION "public"."finalizar_consulta"("p_consulta_id" "uuid", "p_metodo_pago" "text", "p_nota" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_aplicar_movimiento_stock"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
declare
  v_stock_actual int;
  v_stock_nuevo  int;
  v_stock_minimo int;
begin
  select stock_actual, stock_minimo
    into v_stock_actual, v_stock_minimo
    from public.consumibles
   where id = new.consumible_id
     for update; -- bloquea la fila mientras se calcula: evita la carrera con
                 -- otro movimiento simultáneo sobre el mismo consumible.

  if v_stock_actual is null then
    raise exception 'Consumible % no existe', new.consumible_id;
  end if;

  v_stock_nuevo := greatest(v_stock_actual + new.diferencia, 0);

  new.stock_anterior := v_stock_actual;
  new.stock_nuevo := v_stock_nuevo;

  update public.consumibles
     set stock_actual = v_stock_nuevo,
         estado = case
           when v_stock_nuevo <= 0 then 'agotado'::public.estado_consumible
           when v_stock_nuevo <= coalesce(v_stock_minimo, 0)
             then 'bajo_stock'::public.estado_consumible
           else 'disponible'::public.estado_consumible
         end,
         updated_at = now()
   where id = new.consumible_id;

  return new;
end;
$$;


ALTER FUNCTION "public"."fn_aplicar_movimiento_stock"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."fn_aplicar_movimiento_stock"() IS 'Aplica el movimiento bajo lock y recalcula el estado del consumible. HFX-CLIN-007: el estado vive aquí para que ninguna vía de consumo lo olvide.';



CREATE OR REPLACE FUNCTION "public"."fn_auditoria_log"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_usuario_id UUID;
  v_entidad_id TEXT;
  v_detalles JSONB;
BEGIN
  SELECT id INTO v_usuario_id FROM public.usuarios WHERE id = auth.uid();

  IF TG_OP = 'DELETE' THEN
    v_entidad_id := OLD.id::text;
    v_detalles := jsonb_build_object('eliminado', to_jsonb(OLD));
    INSERT INTO auditoria_log (usuario_id, accion, entidad, entidad_id, detalles, fecha)
    VALUES (v_usuario_id, 'DELETE', TG_TABLE_NAME, v_entidad_id, v_detalles, NOW());
    RETURN OLD;

  ELSIF TG_OP = 'UPDATE' THEN
    v_entidad_id := NEW.id::text;
    v_detalles := jsonb_build_object(
      'antes', to_jsonb(OLD),
      'despues', to_jsonb(NEW)
    );
    INSERT INTO auditoria_log (usuario_id, accion, entidad, entidad_id, detalles, fecha)
    VALUES (v_usuario_id, 'UPDATE', TG_TABLE_NAME, v_entidad_id, v_detalles, NOW());
    RETURN NEW;

  ELSIF TG_OP = 'INSERT' THEN
    v_entidad_id := NEW.id::text;
    v_detalles := jsonb_build_object('creado', to_jsonb(NEW));
    INSERT INTO auditoria_log (usuario_id, accion, entidad, entidad_id, detalles, fecha)
    VALUES (v_usuario_id, 'CREATE', TG_TABLE_NAME, v_entidad_id, v_detalles, NOW());
    RETURN NEW;
  END IF;

  RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."fn_auditoria_log"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_autoasignar_doctor_paciente"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
    -- Cada doctor que atiende una consulta de este paciente queda con acceso
    -- activo, sin importar si otro doctor ya lo tenía (cobertura de emergencia,
    -- referencias, co-tratamiento). El chequeo es por PAR doctor-paciente, no
    -- exclusivo por paciente, así que múltiples doctores pueden acumular acceso
    -- legítimamente con el tiempo.
    IF NOT EXISTS (
        SELECT 1 FROM doctor_paciente
        WHERE paciente_id = NEW.paciente_id
          AND doctor_id = NEW.doctor_id
          AND activo = true
    ) THEN
        INSERT INTO doctor_paciente (doctor_id, paciente_id, asignado_por, motivo)
        VALUES (
            NEW.doctor_id,
            NEW.paciente_id,
            NEW.doctor_id,
            'asignación automática: consulta ' || NEW.id::text
        );
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."fn_autoasignar_doctor_paciente"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."fn_autoasignar_doctor_paciente"() IS 'Cada doctor que crea una consulta para un paciente queda con acceso activo en doctor_paciente. No es exclusivo: varios doctores pueden acumular acceso (cobertura de emergencia, co-tratamiento) sin que eso desactive el acceso de otros. La revocación de acceso (transferencia formal) sigue siendo una acción manual explícita en doctor_paciente, no automática.';



CREATE OR REPLACE FUNCTION "public"."fn_cascade_deleted_at_doctor"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  IF NEW.deleted_at IS DISTINCT FROM OLD.deleted_at THEN
    UPDATE admins SET deleted_at = NEW.deleted_at WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."fn_cascade_deleted_at_doctor"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_cascade_deleted_at_usuario"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  IF NEW.deleted_at IS DISTINCT FROM OLD.deleted_at THEN
    UPDATE doctores SET deleted_at = NEW.deleted_at WHERE id = NEW.id;
    UPDATE asistentes SET deleted_at = NEW.deleted_at WHERE id = NEW.id;
    -- Ya NO se toca admin aquí directamente:
    -- admin ahora cuelga de doctor, no de usuario.
    -- El UPDATE de arriba a `doctor` disparará el trigger de nivel 2 solito.
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."fn_cascade_deleted_at_usuario"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generar_codigo_receta"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  IF NEW.codigo_receta IS NULL OR NEW.codigo_receta = '' THEN
    NEW.codigo_receta := 'RX-' || TO_CHAR(NOW(), 'YYYY') || '-' || LPAD(NEXTVAL('secuencia_codigo_receta')::TEXT, 5, '0');
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."generar_codigo_receta"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generar_plan_cuotas"("p_cuenta_id" "uuid", "p_cuotas" "jsonb") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if not public.es_contexto_interno()
     and (
       auth.uid() is null
       or not (public.es_admin() or public.es_asistente())
     ) then
    raise exception 'Capacidad de caja requerida.' using errcode = '42501';
  end if;
  perform public.hfx_base_generar_plan_cuotas(p_cuenta_id, p_cuotas);
end;
$$;


ALTER FUNCTION "public"."generar_plan_cuotas"("p_cuenta_id" "uuid", "p_cuotas" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_active_doctors"() RETURNS TABLE("doctor_id" "uuid", "especialidad" "text", "esta_disponible" boolean, "username" "text", "nombre" "text", "apellido" "text", "fecha_nacimiento" "date", "cedula" "text", "deleted_at" timestamp with time zone, "es_admin" boolean)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select d.id,
         d.especialidad,
         d.esta_disponible,
         u.username,
         p.nombre,
         p.apellido,
         p.fecha_nacimiento,
         p.cedula,
         u.deleted_at,
         (a.id is not null) as es_admin
    from public.doctores d
    join public.usuarios u on u.id = d.id
    join public.personas p on p.id = d.id
    left join public.admins a on a.id = d.id and a.deleted_at is null
   where d.deleted_at is null
     and u.deleted_at is null
     and p.deleted_at is null;
$$;


ALTER FUNCTION "public"."get_active_doctors"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_active_doctors"() IS 'HFX-CLIN-000: doctores activos, administradores incluidos. Ya no devuelve password_hash: era PII que acababa impresa en la consola del navegador.';



CREATE OR REPLACE FUNCTION "public"."guardar_borrador_consulta"("p_consulta_id" "uuid", "p_version" integer DEFAULT NULL::integer, "p_payload" "jsonb" DEFAULT '{}'::"jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_actor_id    uuid;
  v_version     integer;
  v_finalizada  boolean;
  v_resultado   jsonb;
  v_alertas     jsonb;
  v_actualizado timestamptz;
begin
  v_actor_id := public.hfx_clin_002_actor_clinico(p_consulta_id);

  select version, coalesce(finalizada, false)
    into v_version, v_finalizada
    from consultas
   where id = p_consulta_id and deleted_at is null
     for update;

  if v_finalizada then
    raise exception 'La consulta % ya fue finalizada y no admite cambios de borrador.', p_consulta_id
      using errcode = 'CL002';
  end if;

  if p_version is not null and p_version <> v_version then
    raise exception 'La consulta cambió en otra sesión (versión % ≠ %). Recarga antes de guardar.',
      p_version, v_version
      using errcode = 'CL001';
  end if;

  v_resultado := public.hfx_clin_002_aplicar_borrador(p_consulta_id, v_actor_id, p_payload);
  v_alertas := public.hfx_clin_003_aplicar_extras(p_consulta_id, v_actor_id, p_payload);

  update consultas
     set version = version + 1, updated_at = now()
   where id = p_consulta_id
  returning version, updated_at into v_version, v_actualizado;

  return v_resultado || jsonb_build_object(
    'consulta_id', p_consulta_id,
    'version', v_version,
    'actualizado_en', v_actualizado,
    'finalizada', false,
    'alertas', v_alertas
  );
end;
$$;


ALTER FUNCTION "public"."guardar_borrador_consulta"("p_consulta_id" "uuid", "p_version" integer, "p_payload" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_persona_id  uuid;
  v_contacto_id uuid;
  v_meta        jsonb := new.raw_user_meta_data;
  v_rol         text  := v_meta ->> 'rol';
  v_telefono    text  := nullif(trim(v_meta ->> 'telefono'), '');
  v_nombre      text  := nullif(trim(v_meta ->> 'nombre'), '');
  v_apellido    text  := nullif(trim(v_meta ->> 'apellido'), '');
  v_cedula      text  := nullif(trim(v_meta ->> 'cedula'), '');
  v_username    text  := nullif(trim(v_meta ->> 'username'), '');
begin
  if v_rol is null or v_rol not in ('doctor', 'admin', 'asistente') then
    raise exception
      'El rol proporcionado ("%") es inválido o no fue enviado en la metadata.',
      coalesce(v_rol, 'NULL')
      using errcode = 'P0001';
  end if;

  -- Validar antes de escribir: si falta un dato obligatorio, el alta no debe
  -- dejar media persona creada ni un usuario de Auth sin perfil. `personas`
  -- exige nombre, apellido, fecha de nacimiento y cédula, y `usuarios` exige
  -- username; sin este bloque el fallo llegaba como un error de constraint.
  if v_nombre is null
     or v_apellido is null
     or v_username is null
     or v_cedula is null
     or nullif(v_meta ->> 'fecha_nacimiento', '') is null
  then
    raise exception
      'Faltan datos obligatorios para crear el usuario: nombre, apellido, fecha_nacimiento, cedula y username.'
      using errcode = 'P0001',
            hint = 'Los envía admin-crear-usuario dentro de user_metadata.';
  end if;

  if v_rol = 'asistente' and nullif(trim(v_meta ->> 'turno'), '') is null then
    raise exception 'Un asistente necesita turno.' using errcode = 'P0001';
  end if;

  -- El UUID de Auth manda: es el mismo en persona, usuario y perfil, y es el
  -- que compara `auth.uid()` en RLS y en las RPC clínicas.
  insert into public.personas (
    id, nombre, apellido, fecha_nacimiento, cedula, estatus
  ) values (
    new.id,
    v_nombre,
    v_apellido,
    nullif(v_meta ->> 'fecha_nacimiento', '')::date,
    v_cedula,
    coalesce(v_meta ->> 'estatus', 'activo')::estatus_persona
  )
  returning id into v_persona_id;

  if v_telefono is not null then
    insert into public.contactos (numero_telefono)
    values (v_telefono)
    returning id into v_contacto_id;

    insert into public.persona_contactos (
      persona_id, tipo_contacto, contacto_id, es_principal
    ) values (
      v_persona_id, 'telefono', v_contacto_id, true
    );
  end if;

  insert into public.usuarios (id, username)
  values (v_persona_id, v_username);

  -- Doctor y admin comparten identidad clínica; el admin sólo añade la fila
  -- administrativa encima.
  if v_rol in ('doctor', 'admin') then
    insert into public.doctores (id, especialidad, esta_disponible)
    values (
      v_persona_id,
      coalesce(nullif(trim(v_meta ->> 'especialidad'), ''), 'General'),
      true
    );
  end if;

  if v_rol = 'admin' then
    insert into public.admins (id, departamento)
    values (
      v_persona_id,
      coalesce(nullif(trim(v_meta ->> 'departamento'), ''), 'Administración')
    );
  elsif v_rol = 'asistente' then
    insert into public.asistentes (id, turno)
    values (v_persona_id, trim(v_meta ->> 'turno'));
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."handle_new_user"() IS 'HFX-CLIN-000: aprovisiona persona, usuario y perfil con el UUID de Auth. El admin recibe además fila en `doctores`, porque ejerce clínica.';



CREATE OR REPLACE FUNCTION "public"."hfx_base_ajustar_stock_consumible"("p_consumible_id" "uuid", "p_nuevo_stock" integer, "p_motivo" "text") RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
declare
  v_stock_anterior integer;
begin
  if p_nuevo_stock < 0 then
    raise exception 'El stock no puede ser negativo.' using errcode = '22023';
  end if;
  if p_motivo not in ('merma', 'correccion', 'usoInterno') then
    raise exception 'El motivo del ajuste no es válido.' using errcode = '22023';
  end if;

  select stock_actual into v_stock_anterior
    from public.consumibles
   where id = p_consumible_id and activo = true and deleted_at is null
   for update;
  if not found then
    raise exception 'No se encontró un consumible activo para ajustar.'
      using errcode = 'P0002';
  end if;

  -- El trigger de movimientos aplica la diferencia bajo lock. Actualizar el
  -- stock aquí también lo aplicaba dos veces y rompía el CHECK de auditoría.
  insert into public.movimientos_stock_consumible (
    consumible_id, stock_anterior, stock_nuevo, diferencia, motivo, creado_por
  ) values (
    p_consumible_id, v_stock_anterior, p_nuevo_stock,
    p_nuevo_stock - v_stock_anterior, p_motivo, auth.uid()
  );

  update public.consumibles
     set estado = case
           when stock_actual <= 0
             then 'agotado'::public.estado_consumible
           when stock_actual <= stock_minimo
             then 'bajo_stock'::public.estado_consumible
           else 'disponible'::public.estado_consumible
         end
   where id = p_consumible_id;
end;
$$;


ALTER FUNCTION "public"."hfx_base_ajustar_stock_consumible"("p_consumible_id" "uuid", "p_nuevo_stock" integer, "p_motivo" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_base_crear_consulta_completa"("p_paciente_id" "uuid", "p_doctor_id" "uuid", "p_cita_id" "uuid", "p_fecha" timestamp with time zone, "p_motivo_consulta" "text", "p_temp_condiciones" "jsonb", "p_dientes" "jsonb", "p_documentos" "jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  v_consulta_id    uuid;
  v_odontograma_id uuid;
  v_diente_id      uuid;
  v_diente         jsonb;
  v_superficie     jsonb;
  v_doc            jsonb;
begin
  -- 1. Consulta
  insert into consultas (
    paciente_id, doctor_id, cita_id, fecha,
    motivo_consulta, temp_condiciones, created_at, updated_at
  )
  values (
    p_paciente_id, p_doctor_id, p_cita_id, p_fecha,
    p_motivo_consulta,
    -- temp_condiciones es text[]: convertimos el array jsonb de strings a text[].
    coalesce(
      (select array_agg(val)
         from jsonb_array_elements_text(coalesce(p_temp_condiciones, '[]'::jsonb)) as t(val)),
      '{}'::text[]
    ),
    now(), now()
  )
  returning id into v_consulta_id;

  -- 2. Odontograma (1:1 con la consulta)
  insert into odontogramas (consulta_id, created_at, updated_at)
  values (v_consulta_id, now(), now())
  returning id into v_odontograma_id;

  -- 3. Dientes + superficies descritos por quien llama
  for v_diente in select * from jsonb_array_elements(coalesce(p_dientes, '[]'::jsonb))
  loop
    insert into dientes (
      odontograma_id, fdi_code, created_at, updated_at
    )
    values (
      v_odontograma_id, (v_diente ->> 'fdi_code')::int, now(), now()
    )
    returning id into v_diente_id;

    for v_superficie in
      select * from jsonb_array_elements(coalesce(v_diente -> 'superficies', '[]'::jsonb))
    loop
      insert into superficies (
        diente_id, tipo_superficie, tratamientos_ids, created_at, updated_at
      )
      values (
        -- el enum tipo_superficie es minúscula; la app envía 'Mesial', etc.
        v_diente_id, lower(v_superficie #>> '{}')::tipo_superficie,
        '{}'::uuid[], now(), now()
      );
    end loop;
  end loop;

  -- 3.bis. HFX-CLIN-008 — el resto de la dentición.
  -- Es la corrección: sin esto, una llamada con `p_dientes = []` dejaba la
  -- consulta con un odontograma vacío y ninguna anotación clínica podía
  -- guardarse, porque `guardar_borrador_consulta` busca la pieza por su
  -- `fdi_code` y la rechaza con CL004 si no existe.
  perform public.hfx_clin_008_completar_odontograma(v_odontograma_id);

  -- 4. Documentos clínicos (radiografías ya subidas a Storage)
  if p_documentos is not null then
    for v_doc in select * from jsonb_array_elements(p_documentos)
    loop
      insert into documentos_clinicos (
        paciente_id, consulta_id, descripcion, tipo_documento,
        url_archivo, created_at, updated_at
      )
      values (
        p_paciente_id,
        v_consulta_id,
        v_doc ->> 'descripcion',
        (v_doc ->> 'tipo_documento')::tipo_documento,
        v_doc ->> 'url_archivo',
        now(), now()
      );
    end loop;
  end if;

  return v_consulta_id;
end;
$$;


ALTER FUNCTION "public"."hfx_base_crear_consulta_completa"("p_paciente_id" "uuid", "p_doctor_id" "uuid", "p_cita_id" "uuid", "p_fecha" timestamp with time zone, "p_motivo_consulta" "text", "p_temp_condiciones" "jsonb", "p_dientes" "jsonb", "p_documentos" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_base_finalizar_consulta"("p_consulta_id" "uuid", "p_metodo_pago" "text" DEFAULT 'contado'::"text", "p_nota" "text" DEFAULT NULL::"text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_paciente_id uuid;
  v_cita_id     uuid;
  v_cuenta_id   uuid;
  v_monto_total numeric(12,2);
  v_metodo_pago modo_pago;
begin
  -- El método llega como texto desde la app; la columna es el enum `modo_pago`.
  begin
    v_metodo_pago := lower(btrim(coalesce(p_metodo_pago, 'contado')))::modo_pago;
  exception when invalid_text_representation then
    raise exception 'Método de pago inválido: %. Valores admitidos: contado, credito.',
      p_metodo_pago using errcode = '22023';
  end;

  select paciente_id, cita_id into v_paciente_id, v_cita_id
  from consultas where id = p_consulta_id and deleted_at is null;
  if v_paciente_id is null then
    raise exception 'La consulta % no existe o fue eliminada.', p_consulta_id;
  end if;

  -- Cierre clínico ANTES de cualquier retorno: finalizar una consulta cierra su
  -- cita, y eso debe valer también cuando la pre-factura ya existía. El estado
  -- terminal se respeta (no se reabre una cita cancelada a mano).
  if v_cita_id is not null then
    update citas
       set estado     = 'completada'::estado_cita,
           updated_at = now()
     where id = v_cita_id
       and estado <> 'completada'::estado_cita
       and estado <> 'cancelada'::estado_cita;
  end if;

  -- Idempotencia: reintentar finalizar no duplica la pre-factura.
  select id into v_cuenta_id from cuentas
  where consulta_id = p_consulta_id and deleted_at is null limit 1;
  if v_cuenta_id is not null then return v_cuenta_id; end if;

  -- Solo procedimientos ejecutados. Las actividades del plan (propuestas,
  -- aceptadas o pendientes) y los hallazgos de la evaluación no facturan.
  select coalesce(sum(precio_aplicado), 0) into v_monto_total
  from tratamientos_aplicados
  where consulta_id = p_consulta_id
    and deleted_at is null
    and coalesce(estado, 'aplicado') <> 'indicado';

  insert into cuentas (
    paciente_id, consulta_id, estado, monto_total, metodo_pago,
    fecha_creacion, nota, created_at, updated_at
  ) values (
    v_paciente_id, p_consulta_id, 'abierta', v_monto_total, v_metodo_pago,
    now(), p_nota, now(), now()
  ) returning id into v_cuenta_id;

  insert into items_cuenta (
    cuenta_id, descripcion, precio_unitario, cantidad, created_at, updated_at
  )
  select v_cuenta_id, coalesce(t.nombre, 'Tratamiento'),
         coalesce(ta.precio_aplicado, 0), 1, now(), now()
  from tratamientos_aplicados ta
  left join tratamientos t on t.id = ta.tratamiento_id
  where ta.consulta_id = p_consulta_id
    and ta.deleted_at is null
    and coalesce(ta.estado, 'aplicado') <> 'indicado';

  return v_cuenta_id;
end;
$$;


ALTER FUNCTION "public"."hfx_base_finalizar_consulta"("p_consulta_id" "uuid", "p_metodo_pago" "text", "p_nota" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_base_generar_plan_cuotas"("p_cuenta_id" "uuid", "p_cuotas" "jsonb") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_total numeric(15,2);
  v_pagado numeric(15,2);
  v_saldo numeric(15,2);
  v_suma_cuotas numeric(15,2);
  v_num_cuotas integer;
begin
  if p_cuotas is null or jsonb_typeof(p_cuotas) <> 'array' then
    raise exception 'El plan de cuotas no tiene un formato válido.';
  end if;

  v_num_cuotas := jsonb_array_length(p_cuotas);
  if v_num_cuotas < 2 or v_num_cuotas > 36 then
    raise exception 'El plan debe tener entre 2 y 36 cuotas.';
  end if;

  select monto_total
    into v_total
    from public.cuentas
   where id = p_cuenta_id
     and deleted_at is null
   for update;

  if not found then
    raise exception 'No se encontró la cuenta solicitada.';
  end if;

  if exists (
    select 1
      from public.cuotas
     where cuenta_id = p_cuenta_id
       and deleted_at is null
  ) then
    raise exception 'La cuenta ya tiene un plan de cuotas.';
  end if;

  select coalesce(sum(monto), 0)
    into v_pagado
    from public.pagos
   where cuenta_id = p_cuenta_id
     and estado = 'completado'
     and deleted_at is null;

  v_saldo := round(v_total - v_pagado, 2);
  if v_saldo <= 0 then
    raise exception 'Esta cuenta ya está saldada.';
  end if;

  select coalesce(sum((item->>'monto')::numeric), 0)
    into v_suma_cuotas
    from jsonb_array_elements(p_cuotas) item;

  if abs(v_suma_cuotas - v_saldo) > 0.01 then
    raise exception 'La suma de las cuotas (%) debe coincidir con el saldo pendiente (%).',
      v_suma_cuotas, v_saldo;
  end if;

  if exists (
    select 1
      from jsonb_array_elements(p_cuotas) item
     where (item->>'monto')::numeric <= 0
        or (item->>'fecha_vencimiento')::date < current_date
  ) then
    raise exception 'Todas las cuotas deben tener monto positivo y fecha vigente.';
  end if;

  insert into public.cuotas (
    cuenta_id,
    monto,
    monto_pagado,
    fecha_vencimiento,
    estado,
    created_at,
    updated_at
  )
  select
    p_cuenta_id,
    (item->>'monto')::numeric,
    0,
    (item->>'fecha_vencimiento')::date,
    'pendiente',
    now(),
    now()
  from jsonb_array_elements(p_cuotas) item;

  update public.cuentas
     set metodo_pago = 'credito',
         estado = 'pendiente',
         updated_at = now()
   where id = p_cuenta_id;
end;
$$;


ALTER FUNCTION "public"."hfx_base_generar_plan_cuotas"("p_cuenta_id" "uuid", "p_cuotas" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_base_marcar_cuotas_vencidas"("p_cuenta_id" "uuid") RETURNS "void"
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  update public.cuotas
     set estado = 'vencida',
         updated_at = now()
   where cuenta_id = p_cuenta_id
     and deleted_at is null
     and estado = 'pendiente'
     and fecha_vencimiento < current_date;
$$;


ALTER FUNCTION "public"."hfx_base_marcar_cuotas_vencidas"("p_cuenta_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_base_recibir_compra"("p_compra_id" "uuid", "p_usuario_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_caja_id UUID;
  v_monto_total NUMERIC(12, 2);
  v_estado_compra TEXT;
  v_item RECORD;
BEGIN
  SELECT estado::text INTO v_estado_compra
  FROM compras
  WHERE id = p_compra_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'La compra especificada no existe.';
  END IF;

  IF v_estado_compra IN ('recibido', 'recibida') THEN
    RAISE EXCEPTION 'Esta compra ya fue recibida anteriormente.';
  END IF;

  SELECT COALESCE(SUM(cantidad * precio_unitario), 0)
  INTO v_monto_total
  FROM consumibles_compras
  WHERE compra_id = p_compra_id;

  SELECT id INTO v_caja_id
  FROM cajas
  WHERE cerrada = false
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_caja_id IS NULL THEN
    RAISE EXCEPTION 'No hay ninguna caja abierta actualmente.';
  END IF;

  UPDATE compras
  SET
    estado = 'recibido'::estado_compra,
    updated_at = NOW()
  WHERE id = p_compra_id;

  -- 5. Registrar movimiento de stock por cada artículo recibido.
  --    El trigger fn_aplicar_movimiento_stock actualiza consumibles.stock_actual
  --    y calcula stock_anterior/stock_nuevo, con FOR UPDATE para evitar carreras
  --    con otros movimientos concurrentes sobre el mismo consumible.
  FOR v_item IN
    SELECT consumible_id, cantidad
    FROM consumibles_compras
    WHERE compra_id = p_compra_id
  LOOP
    INSERT INTO movimientos_stock_consumible (
      consumible_id,
      diferencia,
      motivo
    ) VALUES (
      v_item.consumible_id,
      v_item.cantidad,
      'compra_recibida'
    );
  END LOOP;

  IF v_monto_total > 0 THEN
    INSERT INTO movimientos_caja (
      caja_diaria_id,
      tipo,
      monto,
      descripcion,
      metodo_pago,
      fecha,
      created_at
    ) VALUES (
      v_caja_id,
      'egreso',
      v_monto_total,
      'Pago por recepción de compra #' || SUBSTRING(p_compra_id::text, 1, 8),
      'efectivo',
      NOW(),
      NOW()
    );

    UPDATE cajas
    SET
      monto_esperado = COALESCE(monto_esperado, 0) - v_monto_total,
      updated_at = NOW()
    WHERE id = v_caja_id;
  END IF;
END;
$$;


ALTER FUNCTION "public"."hfx_base_recibir_compra"("p_compra_id" "uuid", "p_usuario_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_base_registrar_mantenimiento_equipo"("p_equipo_id" "uuid", "p_suplidor_id" "uuid", "p_costo" numeric, "p_fecha_mantenimiento" timestamp with time zone, "p_descripcion" "text" DEFAULT 'Mantenimiento'::"text") RETURNS "uuid"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
declare
  v_mantenimiento_id uuid;
begin
  if p_costo < 0 then
    raise exception 'El costo no puede ser negativo.' using errcode = '22023';
  end if;

  if p_fecha_mantenimiento::date > current_date then
    raise exception 'La fecha de mantenimiento no puede estar en el futuro.'
      using errcode = '22023';
  end if;

  insert into public.equipos_mantenimientos (
    equipo_id,
    suplidor_id,
    descripcion,
    costo,
    fecha_mantenimiento
  ) values (
    p_equipo_id,
    p_suplidor_id,
    coalesce(nullif(trim(p_descripcion), ''), 'Mantenimiento'),
    p_costo,
    p_fecha_mantenimiento
  )
  returning id into v_mantenimiento_id;

  update public.equipos
     set ultimo_mantenimiento = p_fecha_mantenimiento,
         updated_at = now()
   where id = p_equipo_id
     and deleted_at is null;

  if not found then
    raise exception 'El equipo no existe o fue eliminado.' using errcode = 'P0002';
  end if;

  return v_mantenimiento_id;
end;
$$;


ALTER FUNCTION "public"."hfx_base_registrar_mantenimiento_equipo"("p_equipo_id" "uuid", "p_suplidor_id" "uuid", "p_costo" numeric, "p_fecha_mantenimiento" timestamp with time zone, "p_descripcion" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_base_registrar_pago"("p_cuenta_id" "uuid", "p_monto" numeric, "p_metodo_pago" "text", "p_cuota_id" "uuid" DEFAULT NULL::"uuid") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_monto_total numeric(15,2);
  v_estado text;
  v_pagado numeric(15,2);
  v_saldo numeric(15,2);
  v_pago_id uuid;
  v_cuota_monto numeric(15,2);
  v_cuota_pagado numeric(15,2);
  v_cuota_estado public.estado_cuota;
begin
  select monto_total, estado
    into v_monto_total, v_estado
    from public.cuentas
   where id = p_cuenta_id
     and deleted_at is null
   for update;

  if not found then
    raise exception 'No se encontró la cuenta solicitada.';
  end if;
  if v_estado in ('saldada', 'cancelada') then
    raise exception 'La cuenta no admite nuevos pagos porque está %.', v_estado;
  end if;
  if p_monto is null or p_monto <= 0 then
    raise exception 'El monto del pago debe ser mayor que cero.';
  end if;

  select coalesce(sum(monto), 0)
    into v_pagado
    from public.pagos
   where cuenta_id = p_cuenta_id
     and estado = 'completado'
     and deleted_at is null;

  v_saldo := round(v_monto_total - v_pagado, 2);
  if p_monto > v_saldo + 0.01 then
    raise exception 'El monto del pago (%) excede el saldo pendiente (%).',
      p_monto, v_saldo;
  end if;

  if p_cuota_id is not null then
    select monto, monto_pagado, estado
      into v_cuota_monto, v_cuota_pagado, v_cuota_estado
      from public.cuotas
     where id = p_cuota_id
       and cuenta_id = p_cuenta_id
       and deleted_at is null
     for update;

    if not found then
      raise exception 'La cuota no pertenece a esta cuenta.';
    end if;
    if v_cuota_estado in ('pagada', 'cancelada') then
      raise exception 'La cuota no admite nuevos pagos porque está %.', v_cuota_estado;
    end if;
    if p_monto > (v_cuota_monto - v_cuota_pagado) + 0.01 then
      raise exception 'El monto del pago (%) excede el saldo de la cuota (%).',
        p_monto, v_cuota_monto - v_cuota_pagado;
    end if;
  end if;

  begin
    insert into public.pagos (
      cuenta_id,
      cuota_id,
      monto,
      fecha,
      estado,
      metodo_pago,
      created_at,
      updated_at
    ) values (
      p_cuenta_id,
      p_cuota_id,
      round(p_monto, 2),
      now(),
      'completado',
      p_metodo_pago::public.metodo_pago,
      now(),
      now()
    ) returning id into v_pago_id;
  exception
    when invalid_text_representation then
      raise exception 'El método de pago no es válido.';
  end;

  if p_cuota_id is not null then
    update public.cuotas
       set monto_pagado = least(monto, monto_pagado + round(p_monto, 2)),
           estado = case
             when monto_pagado + round(p_monto, 2) >= monto then 'pagada'::public.estado_cuota
             when fecha_vencimiento < current_date then 'vencida'::public.estado_cuota
             else 'pendiente'::public.estado_cuota
           end,
           updated_at = now()
     where id = p_cuota_id;
  end if;

  if v_pagado + p_monto >= v_monto_total then
    update public.cuentas
       set estado = 'saldada',
           fecha_pago = now(),
           updated_at = now()
     where id = p_cuenta_id;
  else
    update public.cuentas
       set estado = 'pendiente',
           updated_at = now()
     where id = p_cuenta_id;
  end if;

  return v_pago_id;
end;
$$;


ALTER FUNCTION "public"."hfx_base_registrar_pago"("p_cuenta_id" "uuid", "p_monto" numeric, "p_metodo_pago" "text", "p_cuota_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_002_actor_clinico"("p_consulta_id" "uuid") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_doctor_id uuid;
  v_finalizada boolean;
begin
  select doctor_id, coalesce(finalizada, false)
    into v_doctor_id, v_finalizada
    from consultas
   where id = p_consulta_id and deleted_at is null;

  if v_doctor_id is null then
    raise exception 'La consulta % no existe o fue eliminada.', p_consulta_id
      using errcode = 'CL004';
  end if;

  if public.es_contexto_interno() then
    return v_doctor_id;
  end if;

  if auth.uid() is null then
    raise exception 'Se requiere una sesión activa para operar sobre la consulta.'
      using errcode = '42501';
  end if;

  -- Un admin tiene identidad clínica, pero más permisos no le permiten firmar
  -- por otro doctor: la autoría del expediente no se transfiere.
  if v_doctor_id <> auth.uid() or not public.es_doctor() then
    raise exception 'Solo el autor clínico activo puede modificar esta consulta.'
      using errcode = '42501';
  end if;

  return v_doctor_id;
end;
$$;


ALTER FUNCTION "public"."hfx_clin_002_actor_clinico"("p_consulta_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_002_aplicar_borrador"("p_consulta_id" "uuid", "p_actor_id" "uuid", "p_payload" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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
  v_lista            jsonb;
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

        update tratamientos_aplicados
           set deleted_at = now(), updated_at = now()
         where consulta_id = p_consulta_id
           and diente_id = v_diente_id
           and deleted_at is null
           and not (id = any (v_conservados));

        v_ids := '{}'::uuid[];
        for v_fila in select value from jsonb_array_elements(coalesce(v_diente -> 'tratamientos', '[]'::jsonb))
        loop
          v_id := nullif(v_fila ->> 'id', '')::uuid;

          if v_id is null then
            insert into tratamientos_aplicados (
              tratamiento_id, diente_id, consulta_id, es_continuo, esta_terminado,
              superficie, precio_aplicado, notas, estado, item_plan_id,
              justificacion_no_planificada, doctor_ejecuta_id, fecha_ejecucion,
              created_at, updated_at
            ) values (
              (v_fila ->> 'tratamiento_id')::uuid,
              v_diente_id,
              p_consulta_id,
              coalesce((v_fila ->> 'es_continuo')::boolean, false),
              coalesce((v_fila ->> 'esta_terminado')::boolean, false),
              nullif(v_fila ->> 'superficie', '')::tipo_superficie,
              nullif(v_fila ->> 'precio_aplicado', '')::numeric,
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

        update diagnosticos_aplicados
           set deleted_at = now(), updated_at = now()
         where consulta_id = p_consulta_id
           and diente_id = v_diente_id
           and deleted_at is null
           and not (id = any (v_conservados));

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


ALTER FUNCTION "public"."hfx_clin_002_aplicar_borrador"("p_consulta_id" "uuid", "p_actor_id" "uuid", "p_payload" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_002_proteger_receta_emitida"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if tg_op = 'DELETE' then
    if old.estado <> 'borrador' and not public.es_contexto_interno() then
      raise exception 'La receta % ya fue emitida: anúlala o reemplázala, no la borres.', old.id
        using errcode = 'CL005';
    end if;
    return old;
  end if;

  if old.estado = 'borrador' or public.es_contexto_interno() then
    return new;
  end if;

  -- Transiciones permitidas sobre una receta emitida.
  if new.estado in ('anulada', 'reemplazada') and old.estado = 'emitida' then
    return new;
  end if;

  if new.estado is distinct from old.estado then
    raise exception 'Transición de estado no permitida para la receta %: % → %.',
      old.id, old.estado, new.estado
      using errcode = 'CL005';
  end if;

  if new.items_receta is distinct from old.items_receta
     or new.medicina_id is distinct from old.medicina_id
     or new.titulo is distinct from old.titulo
     or new.title is distinct from old.title
     or new.dosis is distinct from old.dosis
     or new.frecuencia is distinct from old.frecuencia
     or new.duracion is distinct from old.duracion
     or new.indicaciones is distinct from old.indicaciones
     or new.indicaciones_generales is distinct from old.indicaciones_generales
     or new.notas is distinct from old.notas
     or new.paciente_id is distinct from old.paciente_id
     or new.doctor_id is distinct from old.doctor_id
     or new.consulta_id is distinct from old.consulta_id
     or (new.deleted_at is not null and old.deleted_at is null) then
    raise exception 'La receta % ya fue emitida y no admite cambios de contenido.', old.id
      using errcode = 'CL005';
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."hfx_clin_002_proteger_receta_emitida"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_002_resultado_cierre"("p_consulta_id" "uuid") RETURNS "jsonb"
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select jsonb_build_object(
    'consulta_id', c.id,
    'version', c.version,
    'finalizada', true,
    'finalizada_en', c.finalizada_at,
    'cita_id', c.cita_id,
    'cita_estado', (select ci.estado::text from citas ci where ci.id = c.cita_id),
    'cuenta_id', cu.id,
    'monto_total', coalesce(cu.monto_total, 0),
    'items_cuenta', (
      select coalesce(count(*), 0) from items_cuenta ic where ic.cuenta_id = cu.id
    ),
    'movimientos', coalesce((
      select jsonb_agg(jsonb_build_object(
               'consumible_id', m.consumible_id,
               'cantidad', abs(m.diferencia),
               'stock_nuevo', m.stock_nuevo))
        from movimientos_stock_consumible m
       where m.consulta_id = c.id), '[]'::jsonb),
    'recetas_emitidas', coalesce((
      select jsonb_agg(jsonb_build_object('id', r.id, 'version', r.version))
        from recetas r
       where r.consulta_id = c.id and r.deleted_at is null and r.estado = 'emitida'
    ), '[]'::jsonb)
  )
    from consultas c
    left join cuentas cu on cu.consulta_id = c.id and cu.deleted_at is null
   where c.id = p_consulta_id;
$$;


ALTER FUNCTION "public"."hfx_clin_002_resultado_cierre"("p_consulta_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_003_aplicar_extras"("p_consulta_id" "uuid", "p_actor_id" "uuid", "p_payload" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_fila        jsonb;
  v_conservados uuid[];
  v_codigos     text[];
  v_sistolica   numeric;
  v_diastolica  numeric;
  v_paciente    uuid;
  v_record      uuid;
  v_id          uuid;
  v_diente_id   uuid;
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
  -- de arcada. Antes solo existía la vía por diente, que es justo lo que la
  -- base ahora rechaza.
  if jsonb_exists(p_payload, 'generales')
     and jsonb_typeof(p_payload -> 'generales') = 'object' then

    v_conservados := coalesce((
      select array_agg((f ->> 'id')::uuid)
        from jsonb_array_elements(
               coalesce(p_payload -> 'generales' -> 'tratamientos', '[]'::jsonb)) as f
       where nullif(f ->> 'id', '') is not null), '{}'::uuid[]);

    update tratamientos_aplicados
       set deleted_at = now(), updated_at = now()
     where consulta_id = p_consulta_id
       and diente_id is null
       and deleted_at is null
       and not (id = any (v_conservados));

    for v_fila in
      select value from jsonb_array_elements(
        coalesce(p_payload -> 'generales' -> 'tratamientos', '[]'::jsonb))
    loop
      v_id := nullif(v_fila ->> 'id', '')::uuid;
      if v_id is null then
        insert into tratamientos_aplicados (
          tratamiento_id, consulta_id, precio_aplicado, notas, estado,
          item_plan_id, justificacion_no_planificada, doctor_ejecuta_id,
          fecha_ejecucion, created_at, updated_at
        ) values (
          (v_fila ->> 'tratamiento_id')::uuid,
          p_consulta_id,
          nullif(v_fila ->> 'precio_aplicado', '')::numeric,
          v_fila ->> 'notas',
          coalesce(nullif(v_fila ->> 'estado', ''), 'aplicado'),
          nullif(v_fila ->> 'item_plan_id', '')::uuid,
          v_fila ->> 'justificacion_no_planificada',
          coalesce(nullif(v_fila ->> 'doctor_ejecuta_id', '')::uuid, p_actor_id),
          coalesce(nullif(v_fila ->> 'fecha_ejecucion', '')::timestamptz, now()),
          now(), now()
        );
      else
        update tratamientos_aplicados
           set tratamiento_id = (v_fila ->> 'tratamiento_id')::uuid,
               precio_aplicado = nullif(v_fila ->> 'precio_aplicado', '')::numeric,
               notas = v_fila ->> 'notas',
               estado = coalesce(nullif(v_fila ->> 'estado', ''), estado),
               item_plan_id = nullif(v_fila ->> 'item_plan_id', '')::uuid,
               justificacion_no_planificada = v_fila ->> 'justificacion_no_planificada',
               deleted_at = null,
               updated_at = now()
         where id = v_id and consulta_id = p_consulta_id and diente_id is null;

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

    update diagnosticos_aplicados
       set deleted_at = now(), updated_at = now()
     where consulta_id = p_consulta_id
       and diente_id is null
       and deleted_at is null
       and not (id = any (v_conservados));

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
               deleted_at = null,
               updated_at = now()
         where id = v_id and consulta_id = p_consulta_id and diente_id is null;

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


ALTER FUNCTION "public"."hfx_clin_003_aplicar_extras"("p_consulta_id" "uuid", "p_actor_id" "uuid", "p_payload" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_003_barreras_de_cierre"("p_consulta_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_alerta record;
  v_items  jsonb;
begin
  -- Una alerta que exige acción no se cierra por cansancio: o se confirma, o se
  -- documenta.
  for v_alerta in
    select * from alertas_clinicas
     where consulta_id = p_consulta_id
       and estado = 'pendiente'
       and accion in ('confirmar', 'documentar', 'bloquear_electivo', 'referir')
     order by created_at
  loop
    raise exception 'Alerta clínica sin resolver: %. Confírmala o documenta la acción antes de cerrar.',
      v_alerta.mensaje
      using errcode = 'CL007';
  end loop;

  -- Lo que se va a emitir se valida entero: es un documento que sale de aquí.
  for v_items in
    select r.items_receta
      from recetas r
     where r.consulta_id = p_consulta_id
       and r.deleted_at is null
       and r.estado = 'borrador'
       and jsonb_array_length(coalesce(r.items_receta, '[]'::jsonb)) > 0
  loop
    perform public.hfx_clin_003_validar_receta(p_consulta_id, v_items, true);
  end loop;
end;
$$;


ALTER FUNCTION "public"."hfx_clin_003_barreras_de_cierre"("p_consulta_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_003_coherencia_ejecucion"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
begin
  new.esta_terminado := (coalesce(new.estado, 'aplicado') = 'completado');
  return new;
end;
$$;


ALTER FUNCTION "public"."hfx_clin_003_coherencia_ejecucion"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_003_conflictos_receta"("p_consulta_id" "uuid", "p_items" "jsonb") RETURNS TABLE("medicina_id" "uuid", "medicina" "text", "condicion" "text", "tipo" "text", "descripcion" "text")
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select m.id,
         coalesce(m.nombre, i ->> 'nombre_medicamento'),
         c.nombre,
         ci.tipo_contraindicacion::text,
         ci.descripcion
    from jsonb_array_elements(coalesce(p_items, '[]'::jsonb)) i
    join medicinas m on m.id = nullif(i ->> 'medicamento_id', '')::uuid
    join contraindicaciones ci
      on ci.medicina_id = m.id and ci.deleted_at is null
    join condiciones c on c.id = ci.condicion_id
   where exists (
     select 1
       from condiciones_activas_paciente cap
       join consultas cons on cons.id = p_consulta_id
      where cap.paciente_id = cons.paciente_id
        and cap.condicion_id = ci.condicion_id
   );
$$;


ALTER FUNCTION "public"."hfx_clin_003_conflictos_receta"("p_consulta_id" "uuid", "p_items" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_003_edad_paciente"("p_paciente_id" "uuid") RETURNS numeric
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select case
           when p.fecha_nacimiento is null then null
           else extract(epoch from age(current_date, p.fecha_nacimiento)) / 31557600.0
         end
    from personas p
   where p.id = p_paciente_id;
$$;


ALTER FUNCTION "public"."hfx_clin_003_edad_paciente"("p_paciente_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_003_evaluar_alertas"("p_consulta_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_regla     record;
  v_signo     record;
  v_vigentes  text[] := '{}';
  v_valor     numeric;
  v_min       numeric;
  v_max       numeric;
  v_codigo    text;
  v_mensaje   text;
  v_cond      text;
  v_paciente  uuid;
  v_edad      numeric;
begin
  select paciente_id into v_paciente from consultas where id = p_consulta_id;
  v_edad := public.hfx_clin_003_edad_paciente(v_paciente);

  for v_regla in
    select * from reglas_clinicas
     where estado = 'aprobada'
       and parametros is not null
       and tipo in ('valor_critico', 'combinacion_condicion_signo',
                    'requisito_dato')
     order by codigo
  loop
    -- Una regla limitada a una franja etaria no se evalúa fuera de ella.
    if not public.hfx_clin_003_regla_aplica_edad(v_regla.parametros, v_edad) then
      continue;
    end if;

    if v_regla.tipo = 'requisito_dato' then
      v_codigo := v_regla.parametros ->> 'codigo';

      -- El dato exigido ya está: nada que avisar.
      if exists (
        select 1 from signos_vitales_consulta sv
         where sv.consulta_id = p_consulta_id
           and sv.codigo = v_codigo
           and sv.deleted_at is null
      ) then
        continue;
      end if;

      v_mensaje := format('%s: falta registrar %s en esta consulta.',
        v_regla.nombre,
        coalesce((select lower(etiqueta) from catalogo_signos_vitales
                   where codigo = v_codigo), v_codigo));

      insert into alertas_clinicas (
        consulta_id, regla_id, regla_codigo, regla_version, severidad, accion,
        mensaje, disparador
      ) values (
        p_consulta_id, v_regla.id, v_regla.codigo, v_regla.version,
        v_regla.severidad, v_regla.accion, v_mensaje,
        jsonb_build_object('codigo', v_codigo, 'valor', null,
                           'edad_anios', round(v_edad, 1), 'faltante', true)
      )
      on conflict (consulta_id, regla_codigo, regla_version)
        where estado <> 'obsoleta'
      do update set mensaje = excluded.mensaje,
                    disparador = excluded.disparador,
                    updated_at = now();

      v_vigentes := v_vigentes || v_regla.codigo;

    elsif v_regla.tipo = 'valor_critico' then
      v_codigo := v_regla.parametros ->> 'codigo';
      v_min := nullif(v_regla.parametros ->> 'min', '')::numeric;
      v_max := nullif(v_regla.parametros ->> 'max', '')::numeric;

      select sv.valor, cat.etiqueta, cat.unidad
        into v_signo
        from signos_vitales_consulta sv
        join catalogo_signos_vitales cat on cat.codigo = sv.codigo
       where sv.consulta_id = p_consulta_id
         and sv.codigo = v_codigo
         and sv.deleted_at is null
       limit 1;

      if not found then
        continue;
      end if;

      v_valor := v_signo.valor;
      if (v_min is not null and v_valor < v_min)
         or (v_max is not null and v_valor > v_max) then
        v_mensaje := format('%s = %s %s fuera del rango clínico aprobado (%s a %s).',
          v_signo.etiqueta, v_valor, v_signo.unidad,
          coalesce(v_min::text, '—'), coalesce(v_max::text, '—'));

        insert into alertas_clinicas (
          consulta_id, regla_id, regla_codigo, regla_version, severidad, accion,
          mensaje, disparador
        ) values (
          p_consulta_id, v_regla.id, v_regla.codigo, v_regla.version,
          v_regla.severidad, v_regla.accion, v_mensaje,
          jsonb_build_object('codigo', v_codigo, 'valor', v_valor,
                             'min', v_min, 'max', v_max)
        )
        on conflict (consulta_id, regla_codigo, regla_version)
          where estado <> 'obsoleta'
        do update set mensaje = excluded.mensaje,
                      disparador = excluded.disparador,
                      updated_at = now();

        v_vigentes := v_vigentes || v_regla.codigo;
      end if;

    else -- combinacion_condicion_signo
      v_cond := v_regla.parametros ->> 'condicion';

      if not exists (
        select 1 from condiciones_activas_paciente cap
          join condiciones c on c.id = cap.condicion_id
         where cap.paciente_id = v_paciente
           and lower(c.nombre) like '%' || lower(v_cond) || '%'
      ) then
        continue;
      end if;

      for v_signo in
        select (s ->> 'codigo') as codigo,
               nullif(s ->> 'min', '')::numeric as minimo,
               nullif(s ->> 'max', '')::numeric as maximo
          from jsonb_array_elements(coalesce(v_regla.parametros -> 'signos', '[]'::jsonb)) s
      loop
        select sv.valor into v_valor
          from signos_vitales_consulta sv
         where sv.consulta_id = p_consulta_id
           and sv.codigo = v_signo.codigo
           and sv.deleted_at is null
         limit 1;

        if v_valor is null then
          continue;
        end if;

        if (v_signo.minimo is not null and v_valor < v_signo.minimo)
           or (v_signo.maximo is not null and v_valor > v_signo.maximo) then
          v_mensaje := format('%s: %s = %s con la condición "%s" registrada.',
            v_regla.nombre, v_signo.codigo, v_valor, v_cond);

          insert into alertas_clinicas (
            consulta_id, regla_id, regla_codigo, regla_version, severidad,
            accion, mensaje, disparador
          ) values (
            p_consulta_id, v_regla.id, v_regla.codigo, v_regla.version,
            v_regla.severidad, v_regla.accion, v_mensaje,
            jsonb_build_object('condicion', v_cond, 'codigo', v_signo.codigo,
                               'valor', v_valor)
          )
          on conflict (consulta_id, regla_codigo, regla_version)
            where estado <> 'obsoleta'
          do update set mensaje = excluded.mensaje,
                        disparador = excluded.disparador,
                        updated_at = now();

          v_vigentes := v_vigentes || v_regla.codigo;
          exit;
        end if;
      end loop;
    end if;
  end loop;

  -- Lo que dejó de aplicar no sigue exigiendo acción, pero queda registrado.
  update alertas_clinicas
     set estado = 'obsoleta', updated_at = now()
   where consulta_id = p_consulta_id
     and estado = 'pendiente'
     and not (regla_codigo = any (v_vigentes));

  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', a.id,
             'regla', a.regla_codigo,
             'severidad', a.severidad,
             'accion', a.accion,
             'mensaje', a.mensaje,
             'estado', a.estado,
             'disparador', a.disparador
           ) order by a.created_at)
      from alertas_clinicas a
     where a.consulta_id = p_consulta_id
       and a.estado <> 'obsoleta'
  ), '[]'::jsonb);
end;
$$;


ALTER FUNCTION "public"."hfx_clin_003_evaluar_alertas"("p_consulta_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_003_exigir_consentimiento"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if new.estado::text not in ('aceptado', 'rechazado') then
    return new;
  end if;
  if old.estado::text = new.estado::text then
    return new;
  end if;

  if not exists (
    select 1 from consentimientos_plan cp
     where cp.plan_id = new.id
       and cp.decision = new.estado::text
       and cp.version_plan = new.version
  ) then
    raise exception 'El plan % no puede pasar a "%" sin consentimiento registrado de la versión % del plan.',
      new.id, new.estado, new.version
      using errcode = 'CL013';
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."hfx_clin_003_exigir_consentimiento"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_003_incorporar_condiciones"("p_consulta_id" "uuid") RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_record uuid;
  v_total  integer := 0;
begin
  select r.id into v_record
    from records r
    join consultas c on c.paciente_id = r.paciente_id
   where c.id = p_consulta_id and r.deleted_at is null
   limit 1;

  if v_record is null then
    return 0;
  end if;

  insert into record_condicion (record_id, condicion_id, fecha_deteccion, notas, activo)
  select v_record, cc.condicion_id, cc.detectada_en, cc.notas, true
    from condiciones_consulta cc
   where cc.consulta_id = p_consulta_id
     and cc.deleted_at is null
     and cc.incorporar_al_expediente
     and not exists (
       select 1 from record_condicion rc
        where rc.record_id = v_record and rc.condicion_id = cc.condicion_id
     );

  get diagnostics v_total = row_count;
  return v_total;
end;
$$;


ALTER FUNCTION "public"."hfx_clin_003_incorporar_condiciones"("p_consulta_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_003_regla_aplica_edad"("p_parametros" "jsonb", "p_edad" numeric) RETURNS boolean
    LANGUAGE "sql" IMMUTABLE
    AS $$
  select case
           when p_parametros is null then true
           when (p_parametros ? 'edad_min_anios') is false
            and (p_parametros ? 'edad_max_anios') is false then true
           when p_edad is null then false
           else coalesce(p_edad >= (p_parametros ->> 'edad_min_anios')::numeric, true)
            and coalesce(p_edad <  (p_parametros ->> 'edad_max_anios')::numeric, true)
         end;
$$;


ALTER FUNCTION "public"."hfx_clin_003_regla_aplica_edad"("p_parametros" "jsonb", "p_edad" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_003_validar_alcance"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_alcance text;
  v_nombre  text;
begin
  if tg_table_name = 'diagnosticos_aplicados' then
    select d.alcance::text, d.nombre into v_alcance, v_nombre
      from diagnosticos d where d.id = new.diagnosis_id;
  else
    select t.alcance::text, t.nombre into v_alcance, v_nombre
      from tratamientos t where t.id = new.tratamiento_id;
  end if;

  if v_alcance is null then
    return new; -- El catálogo responde por su propia integridad referencial.
  end if;

  if v_alcance = 'puntual' then
    if new.diente_id is null then
      raise exception '"%" se aplica sobre una superficie y llegó sin pieza.', v_nombre
        using errcode = 'CL012';
    end if;
    if new.superficie is null then
      raise exception '"%" se aplica sobre una superficie concreta: falta indicarla.', v_nombre
        using errcode = 'CL012';
    end if;
  elsif v_alcance = 'diente' then
    if new.diente_id is null then
      raise exception '"%" se aplica sobre una pieza y llegó sin pieza.', v_nombre
        using errcode = 'CL012';
    end if;
    if new.superficie is not null then
      raise exception '"%" se aplica a la pieza completa, no a una superficie.', v_nombre
        using errcode = 'CL012';
    end if;
  else -- arcada, global
    if new.diente_id is not null then
      raise exception '"%" tiene alcance % y no puede asignarse a una pieza.',
        v_nombre, v_alcance
        using errcode = 'CL012';
    end if;
    if new.superficie is not null then
      raise exception '"%" tiene alcance % y no puede asignarse a una superficie.',
        v_nombre, v_alcance
        using errcode = 'CL012';
    end if;
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."hfx_clin_003_validar_alcance"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_003_validar_receta"("p_consulta_id" "uuid", "p_items" "jsonb", "p_estricto" boolean DEFAULT false) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_item        jsonb;
  v_conflicto   record;
  v_nombre      text;
  v_dosis       numeric;
  v_frecuencia  numeric;
  v_duracion    numeric;
  v_cantidad    numeric;
  v_esperada    numeric;
  v_vistos      text[] := '{}';
  v_clave       text;
  v_principio   text;
  v_paciente    uuid;
  v_edad        numeric;
  v_req         record;
begin
  if p_items is null or jsonb_typeof(p_items) <> 'array'
     or jsonb_array_length(p_items) = 0 then
    return;
  end if;

  -- 9.1 Contraindicación absoluta: sin excepción, ni con justificación.
  for v_conflicto in
    select * from public.hfx_clin_003_conflictos_receta(p_consulta_id, p_items)
     where tipo = 'absoluta'
  loop
    raise exception '% está contraindicado de forma absoluta por "%": %.',
      v_conflicto.medicina, v_conflicto.condicion, v_conflicto.descripcion
      using errcode = 'CL010';
  end loop;

  -- 9.1.b Dosificación por peso: si el dueño clínico aprobó hasta qué edad la
  -- receta exige peso registrado, no se emite sin ese dato. Mientras la regla
  -- siga pendiente no hay barrera: aquí no se inventa el corte pediátrico.
  if p_estricto then
    select paciente_id into v_paciente from consultas where id = p_consulta_id;
    v_edad := public.hfx_clin_003_edad_paciente(v_paciente);

    for v_req in
      select * from reglas_clinicas
       where estado = 'aprobada'
         and parametros is not null
         and tipo = 'requisito_dato'
         and coalesce((parametros ->> 'exige_al_recetar')::boolean, false)
    loop
      if not public.hfx_clin_003_regla_aplica_edad(v_req.parametros, v_edad) then
        continue;
      end if;

      if not exists (
        select 1 from signos_vitales_consulta sv
         where sv.consulta_id = p_consulta_id
           and sv.codigo = v_req.parametros ->> 'codigo'
           and sv.deleted_at is null
      ) then
        raise exception 'No se puede emitir la receta: falta % y la dosificación de este paciente depende de ese dato.',
          coalesce((select lower(etiqueta) from catalogo_signos_vitales
                     where codigo = v_req.parametros ->> 'codigo'),
                   v_req.parametros ->> 'codigo')
          using errcode = 'CL012';
      end if;
    end loop;
  end if;

  for v_item in select value from jsonb_array_elements(p_items)
  loop
    v_nombre := coalesce(nullif(v_item ->> 'nombre_medicamento', ''), 'el medicamento');

    -- 9.2 Riesgo relativo: justificación por medicamento, no una nota global.
    if exists (
      select 1 from public.hfx_clin_003_conflictos_receta(
                   p_consulta_id, jsonb_build_array(v_item))
       where tipo = 'relativa'
    ) and coalesce(btrim(v_item ->> 'justificacion_riesgo'), '') = '' then
      raise exception '% tiene una contraindicación relativa para este paciente y exige justificación clínica propia.',
        v_nombre
        using errcode = 'CL011';
    end if;

    if not p_estricto then
      continue;
    end if;

    -- 9.3 Renglón estructurado.
    v_dosis      := nullif(v_item ->> 'dosis_cantidad', '')::numeric;
    v_frecuencia := nullif(v_item ->> 'frecuencia_horas', '')::numeric;
    v_duracion   := nullif(v_item ->> 'duracion_dias', '')::numeric;
    v_cantidad   := nullif(v_item ->> 'cantidad_total', '')::numeric;

    if v_dosis is null or v_dosis <= 0
       or coalesce(btrim(v_item ->> 'dosis_unidad'), '') = ''
       or coalesce(btrim(v_item ->> 'via_administracion'), '') = '' then
      raise exception 'El renglón de % no tiene dosis, unidad o vía de administración.',
        v_nombre using errcode = 'CL008';
    end if;

    if v_frecuencia is null or v_frecuencia <= 0 or v_frecuencia > 168 then
      raise exception 'La frecuencia de % debe estar entre 1 y 168 horas.',
        v_nombre using errcode = 'CL008';
    end if;

    if v_duracion is null or v_duracion <= 0 or v_duracion > 365 then
      raise exception 'La duración de % debe estar entre 1 y 365 días.',
        v_nombre using errcode = 'CL008';
    end if;

    if v_cantidad is null or v_cantidad <= 0 then
      raise exception 'Falta la cantidad total a despachar de %.',
        v_nombre using errcode = 'CL008';
    end if;

    -- 9.4 Coherencia: lo que se despacha tiene que alcanzar para el tratamiento
    -- indicado, y no duplicarlo.
    v_esperada := ceil(24.0 / v_frecuencia) * v_duracion * v_dosis;
    if v_cantidad < v_esperada or v_cantidad > v_esperada * 2 then
      raise exception 'La cantidad de % (%) no cuadra con % cada % horas durante % días (se esperaban ~%).',
        v_nombre, v_cantidad, v_dosis, v_frecuencia, v_duracion, v_esperada
        using errcode = 'CL008';
    end if;

    -- 9.5 Duplicidad: por medicamento y por principio activo cuando se conoce.
    v_clave := coalesce(nullif(v_item ->> 'medicamento_id', ''),
                        lower(btrim(coalesce(v_item ->> 'nombre_medicamento', ''))));
    if v_clave = any (v_vistos) then
      raise exception 'La receta repite %.', v_nombre using errcode = 'CL009';
    end if;
    v_vistos := v_vistos || v_clave;

    select lower(btrim(m.principio_activo)) into v_principio
      from medicinas m
     where m.id = nullif(v_item ->> 'medicamento_id', '')::uuid
       and coalesce(btrim(m.principio_activo), '') <> '';

    if v_principio is not null then
      if ('pa:' || v_principio) = any (v_vistos) then
        raise exception 'La receta repite el principio activo "%" en más de un medicamento.',
          v_principio using errcode = 'CL009';
      end if;
      v_vistos := v_vistos || ('pa:' || v_principio);
    end if;
  end loop;
end;
$$;


ALTER FUNCTION "public"."hfx_clin_003_validar_receta"("p_consulta_id" "uuid", "p_items" "jsonb", "p_estricto" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_003_validar_signo_vital"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_cat record;
begin
  select * into v_cat
    from catalogo_signos_vitales
   where codigo = new.codigo;

  if not found then
    raise exception 'El signo vital "%" no está en el catálogo.', new.codigo
      using errcode = 'CL006';
  end if;

  if new.valor < v_cat.minimo_posible or new.valor > v_cat.maximo_posible then
    raise exception '% = % % está fuera del rango físicamente posible (% a % %).',
      v_cat.etiqueta, new.valor, v_cat.unidad,
      v_cat.minimo_posible, v_cat.maximo_posible, v_cat.unidad
      using errcode = 'CL006';
  end if;

  new.unidad := coalesce(nullif(new.unidad, ''), v_cat.unidad);

  if new.unidad <> v_cat.unidad then
    raise exception '% se registra en % y llegó en "%".',
      v_cat.etiqueta, v_cat.unidad, new.unidad
      using errcode = 'CL006';
  end if;

  new.updated_at := now();
  return new;
end;
$$;


ALTER FUNCTION "public"."hfx_clin_003_validar_signo_vital"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_003_versionar_plan"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_plan uuid := coalesce(new.plan_id, old.plan_id);
begin
  if tg_op = 'UPDATE'
     and new.tratamiento_id is not distinct from old.tratamiento_id
     and new.precio_estimado is not distinct from old.precio_estimado
     and new.diente_id is not distinct from old.diente_id
     and new.superficie is not distinct from old.superficie
     and new.deleted_at is not distinct from old.deleted_at then
    return new;
  end if;

  update planes_tratamiento
     set version = version + 1, updated_at = now()
   where id = v_plan;

  return coalesce(new, old);
end;
$$;


ALTER FUNCTION "public"."hfx_clin_003_versionar_plan"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_004_calcular_fin_cita"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
begin
  new.fin := new.fecha_hora + make_interval(mins => new.duracion_minutos::int);
  return new;
end;
$$;


ALTER FUNCTION "public"."hfx_clin_004_calcular_fin_cita"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_004_estado_cita_canonico"("p_estado" "text") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE
    SET "search_path" TO ''
    AS $$
  select case p_estado
           when 'pendiente'   then 'programada'
           when 'atendida'    then 'completada'
           when 'no_asistida' then 'no_asistio'
           else p_estado
         end;
$$;


ALTER FUNCTION "public"."hfx_clin_004_estado_cita_canonico"("p_estado" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_004_normalizar_cedula"("p_cedula" "text") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE
    SET "search_path" TO ''
    AS $$
  select nullif(
    upper(regexp_replace(coalesce(p_cedula, ''), '[\s\-\._]', '', 'g')),
    ''
  );
$$;


ALTER FUNCTION "public"."hfx_clin_004_normalizar_cedula"("p_cedula" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_004_normalizar_email"("p_email" "text") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE
    SET "search_path" TO ''
    AS $$
  select nullif(lower(btrim(coalesce(p_email, ''))), '');
$$;


ALTER FUNCTION "public"."hfx_clin_004_normalizar_email"("p_email" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_004_normalizar_telefono"("p_telefono" "text") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE
    SET "search_path" TO ''
    AS $$
  select nullif(regexp_replace(coalesce(p_telefono, ''), '[^0-9]', '', 'g'), '');
$$;


ALTER FUNCTION "public"."hfx_clin_004_normalizar_telefono"("p_telefono" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_004_sincronizar_contactos"("p_persona_id" "uuid", "p_contactos" "jsonb") RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
declare
  v_contacto   jsonb;
  v_indice     integer := 0;
  v_telefono   text;
  v_id         uuid;
begin
  for v_contacto in
    select * from jsonb_array_elements(coalesce(p_contactos, '[]'::jsonb))
  loop
    v_telefono := public.hfx_clin_004_normalizar_telefono(
      v_contacto ->> 'numero_telefono'
    );
    v_id := nullif(v_contacto ->> 'id', '')::uuid;

    if v_telefono is null then
      v_indice := v_indice + 1;
      continue;
    end if;

    if v_id is not null and exists (
      select 1 from public.contactos where id = v_id
    ) then
      update public.contactos
         set numero_telefono = v_telefono,
             email = public.hfx_clin_004_normalizar_email(v_contacto ->> 'email'),
             direccion = nullif(btrim(coalesce(v_contacto ->> 'direccion', '')), ''),
             updated_at = now()
       where id = v_id;
    else
      insert into public.contactos (email, numero_telefono, direccion)
      values (
        public.hfx_clin_004_normalizar_email(v_contacto ->> 'email'),
        v_telefono,
        nullif(btrim(coalesce(v_contacto ->> 'direccion', '')), '')
      )
      returning id into v_id;

      insert into public.persona_contactos (
        persona_id, contacto_id, es_principal, es_emergencia
      )
      values (
        p_persona_id, v_id, v_indice = 0,
        coalesce((v_contacto ->> 'es_emergencia')::boolean, v_indice > 0)
      );
    end if;

    v_indice := v_indice + 1;
  end loop;
end;
$$;


ALTER FUNCTION "public"."hfx_clin_004_sincronizar_contactos"("p_persona_id" "uuid", "p_contactos" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_004_validar_transicion_cita"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
declare
  v_desde text := public.hfx_clin_004_estado_cita_canonico(old.estado::text);
  v_hasta text := public.hfx_clin_004_estado_cita_canonico(new.estado::text);
  v_permitidas text[];
begin
  if v_desde = v_hasta then
    return new;
  end if;

  v_permitidas := case v_desde
    when 'programada'  then array['confirmada', 'en_espera', 'cancelada', 'no_asistio']
    when 'confirmada'  then array['en_espera', 'cancelada', 'no_asistio']
    when 'en_espera'   then array['en_consulta', 'cancelada', 'no_asistio']
    when 'en_consulta' then array['completada', 'cancelada']
    else array[]::text[]
  end;

  if not (v_hasta = any(v_permitidas)) then
    raise exception
      'La cita está en "%" y no puede pasar a "%".', v_desde, v_hasta
      using errcode = 'CL016';
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."hfx_clin_004_validar_transicion_cita"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."hfx_clin_004_validar_transicion_cita"() IS 'HFX-CLIN-004. Mismo grafo que EstadoCita en Dart. `programada → en_espera` existe porque el paciente puede llegar sin haber confirmado.';



CREATE OR REPLACE FUNCTION "public"."hfx_clin_005_auditar_alerta"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  perform public.hfx_clin_005_registrar_evento(
    'alerta_emitida', new.consulta_id, null,
    jsonb_build_object(
      'alerta_id', new.id,
      'regla', new.regla_codigo,
      'severidad', new.severidad,
      'accion', new.accion
    )
  );
  return null;
end;
$$;


ALTER FUNCTION "public"."hfx_clin_005_auditar_alerta"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_005_auditar_cita"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_evento text;
begin
  if tg_op = 'INSERT' then
    perform public.hfx_clin_005_registrar_evento(
      'cita_creada', null, new.id,
      jsonb_build_object(
        'estado', new.estado,
        'es_emergencia', coalesce(new.es_emergencia, false),
        'duracion_minutos', new.duracion_minutos
      )
    );
    return null;
  end if;

  if new.deleted_at is not null and old.deleted_at is null then
    perform public.hfx_clin_005_registrar_evento(
      'cita_eliminada', null, new.id, '{}'::jsonb
    );
    return null;
  end if;

  if new.estado is distinct from old.estado then
    v_evento := case new.estado::text
      when 'en_espera'   then 'cita_llegada'
      when 'en_consulta' then 'cita_en_consulta'
      when 'completada'  then 'cita_completada'
      when 'cancelada'   then 'cita_cancelada'
      when 'no_asistio'  then 'cita_no_asistio'
      when 'no_asistida' then 'cita_no_asistio'
      else 'cita_estado_cambiado'
    end;
    perform public.hfx_clin_005_registrar_evento(
      v_evento, null, new.id,
      jsonb_build_object('estado_previo', old.estado, 'estado', new.estado)
    );
  elsif new.fecha_hora is distinct from old.fecha_hora
     or new.doctor_id is distinct from old.doctor_id
  then
    perform public.hfx_clin_005_registrar_evento(
      'cita_reprogramada', null, new.id,
      jsonb_build_object(
        'fecha_hora_previa', old.fecha_hora,
        'fecha_hora', new.fecha_hora,
        'cambio_doctor', new.doctor_id is distinct from old.doctor_id
      )
    );
  end if;

  return null;
end;
$$;


ALTER FUNCTION "public"."hfx_clin_005_auditar_cita"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_005_auditar_consentimiento"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_consulta uuid;
begin
  select p.consulta_origen_id into v_consulta
    from public.planes_tratamiento p where p.id = new.plan_id;

  perform public.hfx_clin_005_registrar_evento(
    'consentimiento_' || new.decision, v_consulta, null,
    jsonb_build_object(
      'plan_id', new.plan_id,
      'version_plan', new.version_plan,
      'metodo', new.metodo,
      'relacion_con_paciente', new.relacion_con_paciente,
      'total_aceptado', new.total_aceptado,
      'motivo', new.motivo_rechazo
    )
  );
  return null;
end;
$$;


ALTER FUNCTION "public"."hfx_clin_005_auditar_consentimiento"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_005_auditar_consulta"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if new.version is distinct from old.version
     and coalesce(new.finalizada, false) = coalesce(old.finalizada, false)
  then
    perform public.hfx_clin_005_registrar_evento(
      'consulta_guardada', new.id, new.cita_id,
      jsonb_build_object('version', new.version)
    );
  end if;
  return null;
end;
$$;


ALTER FUNCTION "public"."hfx_clin_005_auditar_consulta"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_005_auditar_correccion"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  perform public.hfx_clin_005_registrar_evento(
    'correccion_administrativa', new.consulta_id, null,
    jsonb_build_object(
      'motivo', new.motivo,
      'autor_original_id', new.autor_original_id,
      'campos', (
        select coalesce(jsonb_agg(k order by k), '[]'::jsonb)
          from jsonb_object_keys(coalesce(new.datos_nuevos, '{}'::jsonb)) as k
      )
    )
  );
  return null;
end;
$$;


ALTER FUNCTION "public"."hfx_clin_005_auditar_correccion"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_005_auditar_diagnostico"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_nombre text;
begin
  select d.nombre into v_nombre
    from public.diagnosticos d where d.id = new.diagnosis_id;

  if tg_op = 'INSERT' then
    perform public.hfx_clin_005_registrar_evento(
      'diagnostico_agregado', new.consulta_id, null,
      jsonb_build_object(
        'diagnostico', v_nombre,
        'severidad', new.severidad,
        'diente_id', new.diente_id,
        'superficie', new.superficie
      )
    );
  elsif new.deleted_at is not null and old.deleted_at is null then
    perform public.hfx_clin_005_registrar_evento(
      'diagnostico_retirado', new.consulta_id, null,
      jsonb_build_object('diagnostico', v_nombre, 'diente_id', new.diente_id)
    );
  end if;
  return null;
end;
$$;


ALTER FUNCTION "public"."hfx_clin_005_auditar_diagnostico"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_005_auditar_plan"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_estado_previo text := case tg_op when 'INSERT' then null else old.estado::text end;
  v_evento text;
begin
  if new.estado::text is not distinct from v_estado_previo then
    return null;
  end if;

  v_evento := case new.estado::text
    when 'propuesto' then 'plan_propuesto'
    when 'aceptado'  then 'plan_aceptado'
    when 'rechazado' then 'plan_rechazado'
    else null
  end;
  if v_evento is null then
    return null;
  end if;

  perform public.hfx_clin_005_registrar_evento(
    v_evento, new.consulta_origen_id, null,
    jsonb_build_object(
      'plan_id', new.id,
      'version', new.version,
      'motivo', new.motivo_rechazo
    )
  );
  return null;
end;
$$;


ALTER FUNCTION "public"."hfx_clin_005_auditar_plan"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_005_auditar_receta"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_estado_previo text := case tg_op when 'INSERT' then null else old.estado end;
begin
  if new.estado is not distinct from v_estado_previo then
    return null;
  end if;

  if new.estado not in ('emitida', 'anulada', 'reemplazada') then
    return null;
  end if;

  perform public.hfx_clin_005_registrar_evento(
    'receta_' || new.estado, new.consulta_id, null,
    jsonb_build_object(
      'receta_id', new.id,
      'items', jsonb_array_length(coalesce(new.items_receta, '[]'::jsonb)),
      'motivo', new.motivo_anulacion,
      'reemplaza_a', new.receta_reemplazada_id
    )
  );
  return null;
end;
$$;


ALTER FUNCTION "public"."hfx_clin_005_auditar_receta"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_005_auditar_tratamiento"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_nombre text;
begin
  select t.nombre into v_nombre
    from public.tratamientos t where t.id = new.tratamiento_id;

  if tg_op = 'INSERT' then
    perform public.hfx_clin_005_registrar_evento(
      'tratamiento_ejecutado', new.consulta_id, null,
      jsonb_build_object(
        'tratamiento', v_nombre,
        'estado', new.estado,
        'diente_id', new.diente_id,
        'superficie', new.superficie,
        'planificado', new.item_plan_id is not null
      )
    );
  elsif new.deleted_at is not null and old.deleted_at is null then
    perform public.hfx_clin_005_registrar_evento(
      'tratamiento_anulado', new.consulta_id, null,
      jsonb_build_object('tratamiento', v_nombre)
    );
  elsif new.estado is distinct from old.estado
     or new.esta_terminado is distinct from old.esta_terminado
  then
    perform public.hfx_clin_005_registrar_evento(
      'tratamiento_actualizado', new.consulta_id, null,
      jsonb_build_object(
        'tratamiento', v_nombre,
        'estado_previo', old.estado,
        'estado', new.estado
      )
    );
  end if;
  return null;
end;
$$;


ALTER FUNCTION "public"."hfx_clin_005_auditar_tratamiento"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_clin_005_registrar_evento"("p_evento" "text", "p_consulta_id" "uuid", "p_cita_id" "uuid", "p_metadata" "jsonb" DEFAULT '{}'::"jsonb") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if p_consulta_id is null and p_cita_id is null then
    return;
  end if;

  insert into public.auditoria_clinica (
    consulta_id, cita_id, evento, actor_id, rol, metadata
  )
  values (
    p_consulta_id,
    p_cita_id,
    p_evento,
    auth.uid(),
    case
      when auth.uid() is null then 'sistema'
      when public.es_admin() then 'admin'
      when public.es_doctor() then 'doctor'
      when public.es_asistente() then 'asistente'
      else 'desconocido'
    end,
    coalesce(p_metadata, '{}'::jsonb)
  );
end;
$$;


ALTER FUNCTION "public"."hfx_clin_005_registrar_evento"("p_evento" "text", "p_consulta_id" "uuid", "p_cita_id" "uuid", "p_metadata" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."hfx_clin_005_registrar_evento"("p_evento" "text", "p_consulta_id" "uuid", "p_cita_id" "uuid", "p_metadata" "jsonb") IS 'HFX-CLIN-005. Escribe un evento de auditoría resolviendo actor y rol de la sesión. Sin sesión el rol es "sistema" y el actor queda nulo.';



CREATE OR REPLACE FUNCTION "public"."hfx_clin_006_validar_parametros_regla"("p_tipo" "text", "p_parametros" "jsonb") RETURNS "void"
    LANGUAGE "plpgsql" IMMUTABLE
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."hfx_clin_006_validar_parametros_regla"("p_tipo" "text", "p_parametros" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."hfx_clin_006_validar_parametros_regla"("p_tipo" "text", "p_parametros" "jsonb") IS 'HFX-CLIN-006. Comprueba la forma de los parámetros según el tipo de regla. El motor de alertas los lee sin validar: una clave mal escrita deja la regla muda en vez de fallar.';



CREATE OR REPLACE FUNCTION "public"."hfx_clin_006_validar_signos_de_regla"("p_tipo" "text", "p_parametros" "jsonb") RETURNS "void"
    LANGUAGE "plpgsql" STABLE
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."hfx_clin_006_validar_signos_de_regla"("p_tipo" "text", "p_parametros" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."hfx_clin_006_validar_signos_de_regla"("p_tipo" "text", "p_parametros" "jsonb") IS 'HFX-CLIN-006. Verifica contra el catálogo que los signos que la regla vigila existen. Vigilar un código inexistente equivale a no vigilar nada.';



CREATE OR REPLACE FUNCTION "public"."hfx_clin_008_completar_odontograma"("p_odontograma_id" "uuid") RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_creadas integer;
begin
  with nuevas as (
    insert into dientes (odontograma_id, fdi_code, created_at, updated_at)
    select p_odontograma_id, d.fdi, now(), now()
      from public.hfx_clin_008_denticion_fdi() as d
     where not exists (
       select 1 from dientes x
        where x.odontograma_id = p_odontograma_id
          and x.fdi_code = d.fdi
     )
    returning id, fdi_code
  )
  insert into superficies (diente_id, tipo_superficie, tratamientos_ids, created_at, updated_at)
  select n.id, s.cara, '{}'::uuid[], now(), now()
    from nuevas n,
         unnest(public.hfx_clin_008_superficies_de(n.fdi_code)) as s(cara);

  get diagnostics v_creadas = row_count;
  -- Cada pieza nueva trae cinco caras.
  return v_creadas / 5;
end;
$$;


ALTER FUNCTION "public"."hfx_clin_008_completar_odontograma"("p_odontograma_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."hfx_clin_008_completar_odontograma"("p_odontograma_id" "uuid") IS 'HFX-CLIN-008. Materializa las piezas FDI que falten, con sus caras. Idempotente.';



CREATE OR REPLACE FUNCTION "public"."hfx_clin_008_denticion_fdi"() RETURNS TABLE("fdi" integer)
    LANGUAGE "sql" IMMUTABLE
    AS $$
  -- Permanentes: cuadrantes 1 a 4, piezas 1 a 8.
  select q * 10 + p
    from generate_series(1, 4) as q,
         generate_series(1, 8) as p
  union all
  -- Temporales: cuadrantes 5 a 8, piezas 1 a 5.
  select q * 10 + p
    from generate_series(5, 8) as q,
         generate_series(1, 5) as p;
$$;


ALTER FUNCTION "public"."hfx_clin_008_denticion_fdi"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."hfx_clin_008_denticion_fdi"() IS 'HFX-CLIN-008. Las 52 piezas FDI (32 permanentes + 20 temporales).';



CREATE OR REPLACE FUNCTION "public"."hfx_clin_008_superficies_de"("p_fdi" integer) RETURNS "public"."tipo_superficie"[]
    LANGUAGE "sql" IMMUTABLE
    AS $$
  select array[
    'mesial'::public.tipo_superficie,
    'distal'::public.tipo_superficie,
    'vestibular'::public.tipo_superficie,
    -- Cara interna: palatina arriba (cuadrantes 1-2 y 5-6), lingual abajo.
    case when p_fdi between 11 and 28 or p_fdi between 51 and 68
         then 'palatina'::public.tipo_superficie
         else 'lingual'::public.tipo_superficie end,
    -- Quinta cara: incisal en anteriores (último dígito 1-3), oclusal en el resto.
    case when p_fdi % 10 between 1 and 3
         then 'incisal'::public.tipo_superficie
         else 'oclusal'::public.tipo_superficie end
  ];
$$;


ALTER FUNCTION "public"."hfx_clin_008_superficies_de"("p_fdi" integer) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."hfx_clin_008_superficies_de"("p_fdi" integer) IS 'HFX-CLIN-008. Caras que corresponden a una pieza según su código FDI.';



CREATE OR REPLACE FUNCTION "public"."hfx_qa_103_transicion_estado_cita"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
begin
  if new.estado is not distinct from old.estado then
    return new;
  end if;

  if current_user in ('postgres', 'service_role', 'supabase_admin') then
    return new;
  end if;

  if not public.puede_cambiar_estado_cita(new.doctor_id, new.estado::text) then
    raise exception
      'Tu rol no puede cambiar esta cita a «%».', new.estado
      using errcode = '42501';
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."hfx_qa_103_transicion_estado_cita"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."hfx_qa_108_normalizar_alcance_historico"() RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_tratamientos_generales integer := 0;
  v_tratamientos_diente integer := 0;
  v_diagnosticos_generales integer := 0;
  v_diagnosticos_diente integer := 0;
  v_arrays_reconstruidos integer := 0;
  v_ambiguos_tratamiento integer := 0;
  v_ambiguos_diagnostico integer := 0;
begin
  update tratamientos_aplicados ta
     set diente_id = null,
         superficie = null,
         updated_at = now()
    from tratamientos t
   where t.id = ta.tratamiento_id
     and ta.deleted_at is null
     and t.alcance in ('arcada', 'global')
     and (ta.diente_id is not null or ta.superficie is not null);
  get diagnostics v_tratamientos_generales = row_count;

  update tratamientos_aplicados ta
     set superficie = null,
         updated_at = now()
    from tratamientos t
   where t.id = ta.tratamiento_id
     and ta.deleted_at is null
     and t.alcance = 'diente'
     and ta.diente_id is not null
     and ta.superficie is not null;
  get diagnostics v_tratamientos_diente = row_count;

  update diagnosticos_aplicados da
     set diente_id = null,
         superficie = null,
         updated_at = now()
    from diagnosticos d
   where d.id = da.diagnosis_id
     and da.deleted_at is null
     and d.alcance in ('arcada', 'global')
     and (da.diente_id is not null or da.superficie is not null);
  get diagnostics v_diagnosticos_generales = row_count;

  update diagnosticos_aplicados da
     set superficie = null,
         updated_at = now()
    from diagnosticos d
   where d.id = da.diagnosis_id
     and da.deleted_at is null
     and d.alcance = 'diente'
     and da.diente_id is not null
     and da.superficie is not null;
  get diagnostics v_diagnosticos_diente = row_count;

  -- `dientes.tratamientos_aplicados_ids` es una proyección auxiliar. Al
  -- desligar los generales se reconstruye desde la tabla normalizada para que
  -- ningún lector antiguo los siga atribuyendo a la pieza anterior.
  with esperados as (
    select di.id,
           coalesce(
             array_agg(ta.id order by ta.created_at)
               filter (where ta.id is not null),
             '{}'::uuid[]
           ) ids
      from dientes di
      left join tratamientos_aplicados ta
        on ta.diente_id = di.id and ta.deleted_at is null
     group by di.id
  )
  update dientes di
     set tratamientos_aplicados_ids = e.ids,
         updated_at = now()
    from esperados e
   where e.id = di.id
     and di.tratamientos_aplicados_ids is distinct from e.ids;
  get diagnostics v_arrays_reconstruidos = row_count;

  select count(*) into v_ambiguos_tratamiento
    from tratamientos_aplicados ta
    join tratamientos t on t.id = ta.tratamiento_id
   where ta.deleted_at is null
     and ((t.alcance = 'puntual'
           and (ta.diente_id is null or ta.superficie is null))
       or (t.alcance = 'diente' and ta.diente_id is null));

  select count(*) into v_ambiguos_diagnostico
    from diagnosticos_aplicados da
    join diagnosticos d on d.id = da.diagnosis_id
   where da.deleted_at is null
     and ((d.alcance = 'puntual'
           and (da.diente_id is null or da.superficie is null))
       or (d.alcance = 'diente' and da.diente_id is null));

  return jsonb_build_object(
    'tratamientos_generales_normalizados', v_tratamientos_generales,
    'tratamientos_diente_normalizados', v_tratamientos_diente,
    'diagnosticos_generales_normalizados', v_diagnosticos_generales,
    'diagnosticos_diente_normalizados', v_diagnosticos_diente,
    'arrays_diente_reconstruidos', v_arrays_reconstruidos,
    'tratamientos_ambiguos_pendientes', v_ambiguos_tratamiento,
    'diagnosticos_ambiguos_pendientes', v_ambiguos_diagnostico
  );
end;
$$;


ALTER FUNCTION "public"."hfx_qa_108_normalizar_alcance_historico"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."hfx_qa_108_normalizar_alcance_historico"() IS 'HFX-QA-108. Normaliza aplicaciones históricas cuando el alcance del catálogo determina su ubicación sin ambigüedad; informa las que requieren revisión clínica.';



CREATE OR REPLACE FUNCTION "public"."iniciar_consulta_de_cita"("p_cita_id" "uuid", "p_dientes" "jsonb" DEFAULT '[]'::"jsonb", "p_documentos" "jsonb" DEFAULT '[]'::"jsonb", "p_temp_condiciones" "jsonb" DEFAULT '[]'::"jsonb", "p_motivo_consulta" "text" DEFAULT NULL::"text", "p_tipo_atencion" "public"."tipo_atencion_clinica" DEFAULT 'consulta'::"public"."tipo_atencion_clinica") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_cita        public.citas%rowtype;
  v_consulta_id uuid;
  v_finalizada  boolean;
  v_estado      text;
begin
  if not public.es_contexto_interno()
     and (auth.uid() is null or not public.es_doctor()) then
    raise exception 'Sesión clínica activa requerida.' using errcode = '42501';
  end if;

  -- El bloqueo es lo que hace segura la comprobación siguiente: dos pestañas
  -- que pulsen "Iniciar consulta" a la vez se serializan aquí, y la segunda ve
  -- la consulta que creó la primera.
  select * into v_cita
    from public.citas
   where id = p_cita_id and deleted_at is null
   for update;
  if not found then
    raise exception 'La cita ya no existe o fue eliminada.' using errcode = 'CL015';
  end if;

  if not public.es_contexto_interno()
     and v_cita.doctor_id is distinct from auth.uid() then
    raise exception 'No puede atender una cita asignada a otro doctor.'
      using errcode = '42501';
  end if;

  select c.id, coalesce(c.finalizada, false)
    into v_consulta_id, v_finalizada
    from public.consultas c
   where c.cita_id = p_cita_id
     and c.deleted_at is null
   order by coalesce(c.finalizada, false), c.created_at desc
   limit 1;

  -- Reanudar es la respuesta correcta al reintento, y también la única forma
  -- de volver a una consulta que quedó abierta ayer.
  if found and not v_finalizada then
    return jsonb_build_object(
      'consulta_id', v_consulta_id,
      'estado', 'reanudada',
      'cita_estado', v_cita.estado::text
    );
  end if;

  -- Una cita ya atendida no se reabre: se consulta. Quien llame decide si
  -- navega al detalle, pero no puede escribir sobre ella.
  if found and v_finalizada then
    return jsonb_build_object(
      'consulta_id', v_consulta_id,
      'estado', 'finalizada',
      'cita_estado', v_cita.estado::text
    );
  end if;

  -- La llegada es un hecho clínico, no un trámite de recepción: sin ella nadie
  -- puede afirmar que el paciente está presente. Se exige explícitamente en vez
  -- de darla por supuesta, y el doctor que trabaja solo la registra él mismo
  -- con `registrar_llegada_cita`.
  v_estado := public.hfx_clin_004_estado_cita_canonico(v_cita.estado::text);
  if v_estado in ('cancelada', 'completada', 'no_asistio') then
    raise exception
      'La cita está "%" y no admite iniciar una consulta.', v_estado
      using errcode = 'CL015';
  end if;
  if v_estado not in ('en_espera', 'en_consulta') then
    raise exception
      'La cita está "%": registra la llegada del paciente antes de iniciar la consulta.',
      v_estado
      using errcode = 'CL015';
  end if;

  v_consulta_id := public.crear_consulta_completa(
    v_cita.persona_id,
    v_cita.doctor_id,
    v_cita.id,
    -- La consulta hereda la fecha agendada, no la del clic (SD-160).
    v_cita.fecha_hora,
    coalesce(nullif(btrim(coalesce(p_motivo_consulta, '')), ''), v_cita.motivo),
    coalesce(p_temp_condiciones, '[]'::jsonb),
    coalesce(p_dientes, '[]'::jsonb),
    coalesce(p_documentos, '[]'::jsonb),
    p_tipo_atencion
  );

  -- La transición viaja dentro de la misma transacción que la creación: no
  -- puede quedar una consulta abierta sobre una cita que sigue "en espera".
  if v_estado <> 'en_consulta' then
    update public.citas
       set estado = 'en_consulta',
           updated_at = now()
     where id = p_cita_id;
  end if;

  insert into public.auditoria_clinica (consulta_id, evento, actor_id, rol, metadata)
  values (
    v_consulta_id,
    'consulta_iniciada',
    auth.uid(),
    case when public.es_admin() then 'admin' else 'doctor' end,
    jsonb_build_object(
      'cita_id', p_cita_id,
      'es_emergencia', coalesce(v_cita.es_emergencia, false),
      'estado_cita_previo', v_estado
    )
  );

  return jsonb_build_object(
    'consulta_id', v_consulta_id,
    'estado', 'creada',
    'cita_estado', 'en_consulta'
  );
end;
$$;


ALTER FUNCTION "public"."iniciar_consulta_de_cita"("p_cita_id" "uuid", "p_dientes" "jsonb", "p_documentos" "jsonb", "p_temp_condiciones" "jsonb", "p_motivo_consulta" "text", "p_tipo_atencion" "public"."tipo_atencion_clinica") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."iniciar_consulta_de_cita"("p_cita_id" "uuid", "p_dientes" "jsonb", "p_documentos" "jsonb", "p_temp_condiciones" "jsonb", "p_motivo_consulta" "text", "p_tipo_atencion" "public"."tipo_atencion_clinica") IS 'HFX-CLIN-004. Idempotente: crea, reanuda o señala finalizada. Bloquea la cita y mueve su estado en la misma transacción.';



CREATE OR REPLACE FUNCTION "public"."limpiar_diagnosticos_superficie"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    UPDATE superficies 
    SET diagnostico_aplicado_id = NULL 
    WHERE diagnostico_aplicado_id = OLD.id;
    RETURN OLD;
END;
$$;


ALTER FUNCTION "public"."limpiar_diagnosticos_superficie"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."linea_tiempo_consulta"("p_consulta_id" "uuid") RETURNS TABLE("id" "uuid", "evento" "text", "categoria" "text", "ocurrido_en" timestamp with time zone, "actor_id" "uuid", "actor_nombre" "text", "rol" "text", "motivo" "text", "metadata" "jsonb")
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_cita_id uuid;
begin
  if not public.es_contexto_interno()
     and not public.puede_ver_consulta(p_consulta_id) then
    raise exception 'CL020: la consulta no existe o no es visible para este usuario'
      using errcode = 'check_violation';
  end if;

  select c.cita_id into v_cita_id
    from public.consultas c where c.id = p_consulta_id;

  return query
  select a.id,
         a.evento,
         case
           when a.evento like 'cita_%' then 'agenda'
           when a.evento like 'plan_%'
             or a.evento like 'consentimiento_%' then 'plan'
           when a.evento like 'receta_%' then 'receta'
           when a.evento like 'alerta_%' then 'alerta'
           when a.evento like 'correccion_%' then 'correccion'
           else 'clinico'
         end as categoria,
         a.created_at,
         a.actor_id,
         nullif(btrim(coalesce(p.nombre, '') || ' ' || coalesce(p.apellido, '')), ''),
         a.rol,
         nullif(btrim(coalesce(a.metadata ->> 'motivo', '')), ''),
         a.metadata
    from public.auditoria_clinica a
    left join public.personas p on p.id = a.actor_id
   where a.consulta_id = p_consulta_id
      or (v_cita_id is not null and a.cita_id = v_cita_id)
   order by a.created_at, a.id;
end;
$$;


ALTER FUNCTION "public"."linea_tiempo_consulta"("p_consulta_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."linea_tiempo_consulta"("p_consulta_id" "uuid") IS 'HFX-CLIN-005. Historia cronológica de una consulta y de su cita, con actor, rol, fecha y motivo. Comprueba visibilidad antes de devolver nada.';



CREATE OR REPLACE FUNCTION "public"."manejar_cita_cancelada"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$BEGIN
    IF (NEW.estado = 'cancelada') THEN
        -- Aquí podrías insertar una notificación para el doctor
        RAISE NOTICE 'Cita cancelada para la persona id: %. El horario ha sido liberado.', NEW.persona_id;
    
    END IF;
    RETURN NEW;
END;$$;


ALTER FUNCTION "public"."manejar_cita_cancelada"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."marcar_cuotas_vencidas"("p_cuenta_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if not public.es_contexto_interno()
     and (
       auth.uid() is null
       or not (public.es_admin() or public.es_asistente())
     ) then
    raise exception 'Capacidad de caja requerida.' using errcode = '42501';
  end if;
  perform public.hfx_base_marcar_cuotas_vencidas(p_cuenta_id);
end;
$$;


ALTER FUNCTION "public"."marcar_cuotas_vencidas"("p_cuenta_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."marcar_item_plan_ejecutado"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
begin
  if new.item_plan_id is null then
    return new;
  end if;

  if new.deleted_at is not null then
    if not exists (
      select 1
      from public.tratamientos_aplicados otra
      where otra.item_plan_id = new.item_plan_id
        and otra.id <> new.id
        and otra.deleted_at is null
    ) then
      update public.items_plan_tratamiento
         set estado = 'pendiente',
             fecha_completado = null,
             updated_at = now()
       where id = new.item_plan_id
         and deleted_at is null;
    end if;
    return new;
  end if;

  update public.items_plan_tratamiento
     set estado = case
           when new.estado = 'en_proceso' then 'en_proceso'::public.estado_item_plan
           else 'completado'::public.estado_item_plan
         end,
         fecha_inicio = coalesce(fecha_inicio, new.fecha_ejecucion, now()),
         fecha_completado = case
           when new.estado = 'en_proceso' then fecha_completado
           else coalesce(fecha_completado, new.fecha_ejecucion, now())
         end,
         updated_at = now()
   where id = new.item_plan_id
     and deleted_at is null;
  return new;
end;
$$;


ALTER FUNCTION "public"."marcar_item_plan_ejecutado"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."perfil_actual"() RETURNS TABLE("id" "uuid", "rol" "text", "nombre" "text", "apellido" "text", "fecha_nacimiento" "date", "cedula" "text", "estatus" "text", "username" "text", "telefono" "text", "email" "text", "direccion" "text", "especialidad" "text", "esta_disponible" boolean, "departamento" "text", "turno" "text")
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select
    u.id,
    case
      when a.id is not null then 'admin'
      when d.id is not null then 'doctor'
      when s.id is not null then 'asistente'
    end                                       as rol,
    p.nombre,
    p.apellido,
    p.fecha_nacimiento,
    p.cedula,
    p.estatus::text,
    u.username,
    c.numero_telefono                         as telefono,
    c.email,
    c.direccion,
    d.especialidad,
    d.esta_disponible,
    a.departamento,
    s.turno
  from public.usuarios u
  join public.personas p on p.id = u.id
  left join public.doctores   d on d.id = u.id and d.deleted_at is null
  left join public.admins     a on a.id = u.id and a.deleted_at is null
  left join public.asistentes s on s.id = u.id and s.deleted_at is null
  left join lateral (
    select ct.numero_telefono, ct.email, ct.direccion
      from public.persona_contactos pc
      join public.contactos ct on ct.id = pc.contacto_id
     where pc.persona_id = p.id
     order by pc.es_principal desc nulls last
     limit 1
  ) c on true
 where u.id = auth.uid()
   and u.deleted_at is null
   and p.deleted_at is null
   and (a.id is not null or d.id is not null or s.id is not null);
$$;


ALTER FUNCTION "public"."perfil_actual"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."perfil_actual"() IS 'HFX-CLIN-000: perfil de la sesión actual. Nunca devuelve password_hash y no admite consultar el perfil de otro usuario.';



CREATE OR REPLACE FUNCTION "public"."publicar_regla_clinica"("p_codigo" "text", "p_parametros" "jsonb", "p_severidad" "text" DEFAULT NULL::"text", "p_accion" "text" DEFAULT NULL::"text", "p_nota" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."publicar_regla_clinica"("p_codigo" "text", "p_parametros" "jsonb", "p_severidad" "text", "p_accion" "text", "p_nota" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."publicar_regla_clinica"("p_codigo" "text", "p_parametros" "jsonb", "p_severidad" "text", "p_accion" "text", "p_nota" "text") IS 'HFX-CLIN-006. Publica una versión nueva de una regla clínica y retira la anterior. Un umbral clínico es una decisión médica: se cambia desde la aplicación, no con un despliegue.';



CREATE OR REPLACE FUNCTION "public"."puede_cambiar_estado_cita"("p_doctor_id" "uuid", "p_destino" "text") RETURNS boolean
    LANGUAGE "sql" STABLE
    SET "search_path" TO 'public'
    AS $$
  select case
    when public.es_admin() then true

    when public.es_asistente() and public.asiste_a_doctor(p_doctor_id) then
      p_destino in ('confirmada', 'en_espera', 'cancelada',
                    'no_asistio', 'no_asistida')

    when public.es_doctor() and p_doctor_id = auth.uid() then
      -- Lo clínico de su propia cita: dar por presente al paciente y cancelar.
      p_destino in ('en_espera', 'cancelada')

    else false
  end;
$$;


ALTER FUNCTION "public"."puede_cambiar_estado_cita"("p_doctor_id" "uuid", "p_destino" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."puede_cambiar_estado_cita"("p_doctor_id" "uuid", "p_destino" "text") IS 'Matriz de transiciones de estado de cita por rol (QA 1-ago-2026): el asistente maneja lo administrativo de la agenda de los doctores que asiste, el doctor lo clínico de sus propias citas, y el admin todo. Los estados en_consulta y completada no pasan por aquí: los producen las RPC de consulta, que corren como `postgres`.';



CREATE OR REPLACE FUNCTION "public"."puede_editar_consulta_propia"("p_consulta_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1 from public.consultas c
     where c.id = p_consulta_id
       and c.deleted_at is null
       and c.doctor_id = auth.uid()
       and coalesce(c.finalizada, false) = false
       and public.es_doctor()
  );
$$;


ALTER FUNCTION "public"."puede_editar_consulta_propia"("p_consulta_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."puede_ver_consulta"("p_consulta_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  -- TEMPORAL (QA 1-ago): revertir cuando Isaac entregue el modelo definitivo.
  select public.es_admin() or public.es_doctor() or exists (
    select 1 from public.consultas c
     where c.id = p_consulta_id
       and c.deleted_at is null
       and c.doctor_id = auth.uid()
  );
$$;


ALTER FUNCTION "public"."puede_ver_consulta"("p_consulta_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."puede_ver_consulta"("p_consulta_id" "uuid") IS 'Encadena hasta puede_ver_paciente() para tablas colgadas de consultas. TEMPORAL (QA 1-ago-2026): mientras dure la decisión D11, cualquier doctor pasa.';



CREATE OR REPLACE FUNCTION "public"."puede_ver_cuenta"("p_cuenta_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
    SELECT puede_ver_paciente(COALESCE(cu.paciente_id, c.paciente_id))
    FROM cuentas cu LEFT JOIN consultas c ON c.id = cu.consulta_id
    WHERE cu.id = p_cuenta_id;
$$;


ALTER FUNCTION "public"."puede_ver_cuenta"("p_cuenta_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."puede_ver_cuenta"("p_cuenta_id" "uuid") IS 'Encadena: cuenta -> paciente (directo o vía consulta).';



CREATE OR REPLACE FUNCTION "public"."puede_ver_diente"("p_diente_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
    SELECT puede_ver_odontograma(d.odontograma_id) FROM dientes d WHERE d.id = p_diente_id;
$$;


ALTER FUNCTION "public"."puede_ver_diente"("p_diente_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."puede_ver_diente"("p_diente_id" "uuid") IS 'Encadena: diente -> odontograma -> consulta -> paciente.';



CREATE OR REPLACE FUNCTION "public"."puede_ver_evaluacion"("p_evaluacion_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
    SELECT puede_ver_paciente(e.paciente_id) FROM evaluaciones_clinicas e WHERE e.id = p_evaluacion_id;
$$;


ALTER FUNCTION "public"."puede_ver_evaluacion"("p_evaluacion_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."puede_ver_odontograma"("p_odontograma_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
    SELECT puede_ver_consulta(o.consulta_id) FROM odontogramas o WHERE o.id = p_odontograma_id;
$$;


ALTER FUNCTION "public"."puede_ver_odontograma"("p_odontograma_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."puede_ver_odontograma"("p_odontograma_id" "uuid") IS 'Encadena: odontograma -> consulta -> paciente.';



CREATE OR REPLACE FUNCTION "public"."puede_ver_paciente"("p_paciente_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
    SELECT
        es_asistente()
        OR (
            es_doctor_no_admin() AND EXISTS (
                SELECT 1 FROM doctor_paciente dp
                WHERE dp.paciente_id = p_paciente_id
                  AND dp.doctor_id = auth.uid()
                  AND dp.activo
            )
        )
        OR (
            es_admin() AND NOT EXISTS (
                SELECT 1 FROM doctor_paciente dp
                JOIN admins a ON a.id = dp.doctor_id
                WHERE dp.paciente_id = p_paciente_id
                  AND dp.activo
                  AND dp.doctor_id <> auth.uid()
            )
        );
$$;


ALTER FUNCTION "public"."puede_ver_paciente"("p_paciente_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."puede_ver_paciente"("p_paciente_id" "uuid") IS 'Regla de negocio: un doctor regular solo ve pacientes con asignación activa en doctor_paciente; un admin ve todos los pacientes excepto los asignados activamente a OTRO admin; un asistente ve todos. Reutilizar esta función en toda policy que filtre por paciente_id.';



CREATE OR REPLACE FUNCTION "public"."puede_ver_plan"("p_plan_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
    SELECT puede_ver_paciente(pt.paciente_id) FROM planes_tratamiento pt WHERE pt.id = p_plan_id;
$$;


ALTER FUNCTION "public"."puede_ver_plan"("p_plan_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."puede_ver_receta"("p_receta_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
    SELECT puede_ver_paciente(COALESCE(r.paciente_id, c.paciente_id))
    FROM recetas r LEFT JOIN consultas c ON c.id = r.consulta_id
    WHERE r.id = p_receta_id;
$$;


ALTER FUNCTION "public"."puede_ver_receta"("p_receta_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."puede_ver_receta"("p_receta_id" "uuid") IS 'Encadena: receta -> paciente (directo o vía consulta).';



CREATE OR REPLACE FUNCTION "public"."realinear_consulta_al_reprogramar_cita"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
begin
  if new.fecha_hora is distinct from old.fecha_hora then
    update consultas
       set fecha      = new.fecha_hora,
           updated_at = now()
     where cita_id = new.id
       and deleted_at is null
       and finalizada is not true;
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."realinear_consulta_al_reprogramar_cita"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."realinear_consulta_al_reprogramar_cita"() IS 'SD-160: al mover una cita, su consulta abierta hereda la nueva fecha.';



CREATE OR REPLACE FUNCTION "public"."recibir_compra"("p_compra_id" "uuid", "p_usuario_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if not public.es_contexto_interno()
     and (
       auth.uid() is null
       or not (public.es_admin() or public.es_asistente())
     ) then
    raise exception 'Capacidad de compras requerida.' using errcode = '42501';
  end if;
  if not public.es_contexto_interno()
     and p_usuario_id is distinct from auth.uid() then
    raise exception 'El actor de la compra no coincide con la sesión.'
      using errcode = '42501';
  end if;
  perform public.hfx_base_recibir_compra(p_compra_id, p_usuario_id);
end;
$$;


ALTER FUNCTION "public"."recibir_compra"("p_compra_id" "uuid", "p_usuario_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."registrar_cita_emergencia"("p_paciente_id" "uuid", "p_doctor_id" "uuid" DEFAULT NULL::"uuid", "p_motivo" "text" DEFAULT NULL::"text", "p_duracion_minutos" integer DEFAULT 30) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_doctor_id uuid;
  v_cita_id   uuid;
begin
  if not public.es_contexto_interno()
     and (auth.uid() is null
          or not (public.es_admin() or public.es_doctor() or public.es_asistente())) then
    raise exception 'Sesión activa requerida para registrar una emergencia.'
      using errcode = '42501';
  end if;

  -- Sin doctor explícito, la emergencia es de quien la registra si ejerce.
  -- Un asistente tiene que decir a quién se la asigna: no puede firmar por
  -- nadie ni dejar la urgencia sin responsable.
  v_doctor_id := coalesce(p_doctor_id, auth.uid());
  if v_doctor_id is null then
    raise exception 'La emergencia necesita un doctor responsable.'
      using errcode = 'CL018';
  end if;
  if not exists (
    select 1 from public.doctores where id = v_doctor_id and deleted_at is null
  ) then
    raise exception 'El responsable indicado no es un doctor activo.'
      using errcode = 'CL018';
  end if;

  if not exists (
    select 1 from public.pacientes where id = p_paciente_id and deleted_at is null
  ) then
    raise exception 'El paciente de la emergencia no existe.' using errcode = 'P0002';
  end if;

  insert into public.citas (
    persona_id, doctor_id, fecha_hora, duracion_minutos,
    es_emergencia, estado, motivo, created_at, updated_at
  )
  values (
    p_paciente_id, v_doctor_id, now(), greatest(coalesce(p_duracion_minutos, 30), 1),
    true, 'en_espera',
    coalesce(nullif(btrim(coalesce(p_motivo, '')), ''), 'Emergencia'),
    now(), now()
  )
  returning id into v_cita_id;

  return jsonb_build_object(
    'cita_id', v_cita_id,
    'doctor_id', v_doctor_id,
    'paciente_id', p_paciente_id
  );
end;
$$;


ALTER FUNCTION "public"."registrar_cita_emergencia"("p_paciente_id" "uuid", "p_doctor_id" "uuid", "p_motivo" "text", "p_duracion_minutos" integer) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."registrar_cita_emergencia"("p_paciente_id" "uuid", "p_doctor_id" "uuid", "p_motivo" "text", "p_duracion_minutos" integer) IS 'HFX-CLIN-004. Crea la cita de urgencia ya en espera y marcada como emergencia. Queda fuera de la restricción de solapamiento a propósito.';



CREATE OR REPLACE FUNCTION "public"."registrar_consentimiento_plan"("p_plan_id" "uuid", "p_decision" "text", "p_persona" "text", "p_metodo" "text", "p_relacion" "text" DEFAULT 'titular'::"text", "p_motivo" "text" DEFAULT NULL::"text", "p_items" "jsonb" DEFAULT NULL::"jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_plan     record;
  v_items    jsonb;
  v_total    numeric(15,2);
  v_actor    uuid := auth.uid();
  v_id       uuid;
begin
  if p_decision not in ('aceptado', 'rechazado') then
    raise exception 'Decisión de consentimiento no válida: %.', p_decision
      using errcode = 'CL013';
  end if;

  select * into v_plan from planes_tratamiento
   where id = p_plan_id and deleted_at is null
     for update;

  if not found then
    raise exception 'El plan % no existe o fue eliminado.', p_plan_id
      using errcode = 'CL004';
  end if;

  if not public.es_contexto_interno() then
    if v_actor is null or not (public.es_doctor() or public.es_admin()) then
      raise exception 'Solo un doctor puede registrar el consentimiento de un plan.'
        using errcode = '42501';
    end if;
  end if;

  if coalesce(btrim(p_persona), '') = '' then
    raise exception 'Falta el nombre de quien acepta o rechaza el plan.'
      using errcode = 'CL013';
  end if;

  -- Los precios que se guardan como aceptados son los del plan en este momento,
  -- no los que el cliente diga: la evidencia no la redacta la pantalla.
  select coalesce(jsonb_agg(jsonb_build_object(
           'item_plan_id', i.id,
           'tratamiento_id', i.tratamiento_id,
           'diente_id', i.diente_id,
           'superficie', i.superficie,
           'precio_estimado', i.precio_estimado,
           'estado', i.estado
         ) order by i.orden), '[]'::jsonb),
         coalesce(sum(i.precio_estimado), 0)
    into v_items, v_total
    from items_plan_tratamiento i
   where i.plan_id = p_plan_id
     and i.deleted_at is null
     and (p_items is null or i.id::text in (
           select jsonb_array_elements_text(p_items)));

  insert into consentimientos_plan (
    plan_id, version_plan, decision, items, total_aceptado, persona_acepta,
    relacion_con_paciente, metodo, motivo_rechazo, registrado_por
  ) values (
    p_plan_id, v_plan.version, p_decision, v_items,
    case when p_decision = 'aceptado' then v_total else 0 end,
    btrim(p_persona), coalesce(nullif(btrim(p_relacion), ''), 'titular'),
    p_metodo, nullif(btrim(p_motivo), ''), v_actor
  ) returning id into v_id;

  update planes_tratamiento
     set estado = p_decision::estado_plan_tratamiento,
         fecha_aceptacion = case when p_decision = 'aceptado' then now() else fecha_aceptacion end,
         fecha_rechazo = case when p_decision = 'rechazado' then now() else fecha_rechazo end,
         motivo_rechazo = case when p_decision = 'rechazado' then nullif(btrim(p_motivo), '') else motivo_rechazo end,
         updated_at = now()
   where id = p_plan_id;

  return jsonb_build_object(
    'consentimiento_id', v_id,
    'plan_id', p_plan_id,
    'version_plan', v_plan.version,
    'decision', p_decision,
    'total_aceptado', case when p_decision = 'aceptado' then v_total else 0 end,
    'items', v_items
  );
end;
$$;


ALTER FUNCTION "public"."registrar_consentimiento_plan"("p_plan_id" "uuid", "p_decision" "text", "p_persona" "text", "p_metodo" "text", "p_relacion" "text", "p_motivo" "text", "p_items" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."registrar_llegada_cita"("p_cita_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_cita   public.citas%rowtype;
  v_estado text;
begin
  if not public.es_contexto_interno()
     and (auth.uid() is null
          or not (public.es_admin() or public.es_doctor() or public.es_asistente())) then
    raise exception 'Sesión activa requerida para registrar la llegada.'
      using errcode = '42501';
  end if;

  select * into v_cita
    from public.citas
   where id = p_cita_id and deleted_at is null
   for update;
  if not found then
    raise exception 'La cita ya no existe o fue eliminada.' using errcode = 'CL015';
  end if;

  -- Un doctor registra la llegada de sus pacientes; quien gestiona la agenda
  -- completa (admin y asistente) la de cualquiera.
  if not public.es_contexto_interno()
     and not (public.es_admin() or public.es_asistente())
     and v_cita.doctor_id is distinct from auth.uid() then
    raise exception 'No puede registrar la llegada de una cita ajena.'
      using errcode = '42501';
  end if;

  v_estado := public.hfx_clin_004_estado_cita_canonico(v_cita.estado::text);
  if v_estado = 'en_espera' then
    return jsonb_build_object('cita_id', p_cita_id, 'estado', 'en_espera',
                             'ya_registrada', true);
  end if;

  update public.citas
     set estado = 'en_espera', updated_at = now()
   where id = p_cita_id;

  return jsonb_build_object('cita_id', p_cita_id, 'estado', 'en_espera',
                           'ya_registrada', false);
end;
$$;


ALTER FUNCTION "public"."registrar_llegada_cita"("p_cita_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."registrar_llegada_cita"("p_cita_id" "uuid") IS 'HFX-CLIN-004. Idempotente. El doctor puede marcar la llegada de sus propias citas sin depender de recepción.';



CREATE OR REPLACE FUNCTION "public"."registrar_mantenimiento_equipo"("p_equipo_id" "uuid", "p_suplidor_id" "uuid", "p_costo" numeric, "p_fecha_mantenimiento" timestamp with time zone, "p_descripcion" "text" DEFAULT 'Mantenimiento'::"text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if not public.es_contexto_interno()
     and (auth.uid() is null or not public.es_admin()) then
    raise exception 'Capacidad administrativa requerida.' using errcode = '42501';
  end if;
  return public.hfx_base_registrar_mantenimiento_equipo(
    p_equipo_id, p_suplidor_id, p_costo, p_fecha_mantenimiento, p_descripcion
  );
end;
$$;


ALTER FUNCTION "public"."registrar_mantenimiento_equipo"("p_equipo_id" "uuid", "p_suplidor_id" "uuid", "p_costo" numeric, "p_fecha_mantenimiento" timestamp with time zone, "p_descripcion" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."registrar_paciente"("p_payload" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_persona_id  uuid;
  v_record_id   uuid;
  v_cedula      text;
  v_telefono    text;
  v_condicion   jsonb;
begin
  if not public.es_contexto_interno()
     and (auth.uid() is null
          or not (public.es_admin() or public.es_doctor() or public.es_asistente())) then
    raise exception 'Sesión activa requerida para registrar un paciente.'
      using errcode = '42501';
  end if;

  if nullif(btrim(coalesce(p_payload ->> 'nombre', '')), '') is null
     or nullif(btrim(coalesce(p_payload ->> 'apellido', '')), '') is null then
    raise exception 'El paciente necesita nombre y apellido.' using errcode = 'CL018';
  end if;

  if p_payload ->> 'fecha_nacimiento' is null then
    raise exception 'El paciente necesita fecha de nacimiento.' using errcode = 'CL018';
  end if;

  v_cedula := public.hfx_clin_004_normalizar_cedula(p_payload ->> 'cedula');
  v_telefono := public.hfx_clin_004_normalizar_telefono(
    p_payload #>> '{contactos,0,numero_telefono}'
  );
  if v_telefono is null then
    raise exception 'El paciente necesita al menos un teléfono de contacto.'
      using errcode = 'CL018';
  end if;

  if v_cedula is not null and exists (
    select 1 from public.personas
     where deleted_at is null
       and public.hfx_clin_004_normalizar_cedula(cedula) = v_cedula
  ) then
    raise exception 'Ya existe un registro con esa cédula.' using errcode = 'CL017';
  end if;

  insert into public.personas (nombre, apellido, fecha_nacimiento, cedula, estatus)
  values (
    btrim(p_payload ->> 'nombre'),
    btrim(p_payload ->> 'apellido'),
    (p_payload ->> 'fecha_nacimiento')::date,
    coalesce(btrim(p_payload ->> 'cedula'), ''),
    coalesce(nullif(p_payload ->> 'estatus', ''), 'activo')::public.estatus_persona
  )
  returning id into v_persona_id;

  perform public.hfx_clin_004_sincronizar_contactos(
    v_persona_id, p_payload -> 'contactos'
  );

  insert into public.pacientes (
    id, genero, tipo_paciente, trabajo, referencia, peso, altura,
    created_at, updated_at
  )
  values (
    v_persona_id,
    coalesce(nullif(p_payload ->> 'genero', ''), 'otro')::public.genero,
    coalesce(nullif(p_payload ->> 'tipo_paciente', ''), 'integrado')::public.tipo_paciente,
    coalesce(p_payload ->> 'trabajo', ''),
    coalesce(p_payload ->> 'referencia', ''),
    (p_payload ->> 'peso')::numeric,
    (p_payload ->> 'altura')::numeric,
    now(), now()
  );

  -- El expediente nace con el paciente: sin él, el asistente que registra al
  -- paciente no puede crearlo después (RLS de `records` es clínica) y la
  -- primera consulta se encontraba una ficha a medias.
  insert into public.records (
    paciente_id, tipo_sangre, cant_hijos, cirugias_previas, historial_familiar
  )
  values (
    v_persona_id,
    coalesce(nullif(p_payload #>> '{record,tipo_sangre}', ''), 'desconocido')::public.tipo_sangre,
    coalesce((p_payload #>> '{record,cant_hijos}')::integer, 0),
    coalesce(
      (select array_agg(value)
         from jsonb_array_elements_text(
           coalesce(p_payload #> '{record,cirugias_previas}', '[]'::jsonb)
         )),
      '{}'::text[]
    ),
    coalesce(p_payload #>> '{record,historial_familiar}', '')
  )
  returning id into v_record_id;

  for v_condicion in
    select * from jsonb_array_elements(coalesce(p_payload -> 'condiciones', '[]'::jsonb))
  loop
    insert into public.record_condicion (record_id, condicion_id, notas)
    values (
      v_record_id,
      (v_condicion ->> 'condicion_id')::uuid,
      nullif(btrim(coalesce(v_condicion ->> 'notas', '')), '')
    );
  end loop;

  return jsonb_build_object(
    'paciente_id', v_persona_id,
    'record_id', v_record_id,
    'version', 1
  );
end;
$$;


ALTER FUNCTION "public"."registrar_paciente"("p_payload" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."registrar_paciente"("p_payload" "jsonb") IS 'HFX-CLIN-004. Alta completa del paciente en una transacción: persona, contacto principal, ficha, expediente y condiciones iniciales.';



CREATE OR REPLACE FUNCTION "public"."registrar_pago"("p_cuenta_id" "uuid", "p_monto" numeric, "p_metodo_pago" "text", "p_cuota_id" "uuid" DEFAULT NULL::"uuid") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if not public.es_contexto_interno()
     and (
       auth.uid() is null
       or not (public.es_admin() or public.es_asistente())
     ) then
    raise exception 'Capacidad de caja requerida.' using errcode = '42501';
  end if;
  return public.hfx_base_registrar_pago(
    p_cuenta_id, p_monto, p_metodo_pago, p_cuota_id
  );
end;
$$;


ALTER FUNCTION "public"."registrar_pago"("p_cuenta_id" "uuid", "p_monto" numeric, "p_metodo_pago" "text", "p_cuota_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."registrar_pago_en_caja"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_caja_id uuid;
  v_zona_horaria constant text := 'America/Santo_Domingo';
begin
  if new.estado <> 'completado' or new.deleted_at is not null then
    return new;
  end if;

  select id
    into v_caja_id
    from public.cajas
   where cerrada = false
     and (fecha at time zone v_zona_horaria)::date =
         (current_timestamp at time zone v_zona_horaria)::date
   limit 1
   for update;

  if v_caja_id is null then
    raise exception using
      errcode = 'P0001',
      message = 'No hay una caja abierta para hoy. Abre la caja antes de registrar el pago.';
  end if;

  insert into public.movimientos_caja (
    caja_diaria_id,
    tipo,
    monto,
    descripcion,
    referencia_id,
    fecha
  ) values (
    v_caja_id,
    'ingreso',
    new.monto,
    'Cobro a cuenta',
    new.id,
    new.fecha
  );

  return new;
end;
$$;


ALTER FUNCTION "public"."registrar_pago_en_caja"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."reglas_clinicas_vigentes"() RETURNS "jsonb"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."reglas_clinicas_vigentes"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."reglas_clinicas_vigentes"() IS 'HFX-CLIN-006. Reglas no retiradas, para la pantalla de ajustes clínicos. Las de tipo rango/relación imposible viajan marcadas como no editables: no dependen de un umbral, sino del catálogo.';



CREATE OR REPLACE FUNCTION "public"."resolver_alerta_clinica"("p_alerta_id" "uuid", "p_estado" "text", "p_justificacion" "text" DEFAULT NULL::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_alerta record;
  v_actor  uuid;
begin
  if p_estado not in ('confirmada', 'documentada') then
    raise exception 'Estado de alerta no válido: %.', p_estado
      using errcode = 'CL007';
  end if;

  select * into v_alerta from alertas_clinicas where id = p_alerta_id;
  if not found then
    raise exception 'La alerta % no existe.', p_alerta_id using errcode = 'CL004';
  end if;

  v_actor := public.hfx_clin_002_actor_clinico(v_alerta.consulta_id);

  if p_estado = 'documentada' and coalesce(btrim(p_justificacion), '') = '' then
    raise exception 'Esta alerta exige una acción documentada: falta la justificación clínica.'
      using errcode = 'CL007';
  end if;

  update alertas_clinicas
     set estado = p_estado,
         justificacion = nullif(btrim(p_justificacion), ''),
         resuelta_por = v_actor,
         resuelta_en = now(),
         updated_at = now()
   where id = p_alerta_id;

  insert into auditoria_clinica (consulta_id, evento, actor_id, rol, metadata)
  values (
    v_alerta.consulta_id, 'alerta_resuelta', v_actor,
    case when public.es_admin() then 'admin' else 'doctor' end,
    jsonb_build_object('alerta_id', p_alerta_id, 'regla', v_alerta.regla_codigo,
                       'estado', p_estado)
  );

  return jsonb_build_object('id', p_alerta_id, 'estado', p_estado);
end;
$$;


ALTER FUNCTION "public"."resolver_alerta_clinica"("p_alerta_id" "uuid", "p_estado" "text", "p_justificacion" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."retirar_regla_clinica"("p_codigo" "text", "p_motivo" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."retirar_regla_clinica"("p_codigo" "text", "p_motivo" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."retirar_regla_clinica"("p_codigo" "text", "p_motivo" "text") IS 'HFX-CLIN-006. Retira la versión vigente de una regla clínica dejando constancia del motivo. No borra: las alertas que emitió siguen explicándose.';



CREATE OR REPLACE FUNCTION "public"."sync_disponibilidad_doctor"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$DECLARE
  doctor_id_afectado uuid;
  tiene_otra_consulta boolean;
BEGIN
  -- Determinar qué doctor revisar (cubre INSERT, UPDATE y DELETE)
  IF TG_OP = 'DELETE' THEN
    doctor_id_afectado := OLD.doctor_id;
  ELSE
    doctor_id_afectado := NEW.doctor_id;
  END IF;

  -- Caso: la cita ENTRA a enConsulta -> doctor no disponible
  IF TG_OP IN ('INSERT', 'UPDATE') AND NEW.estado = 'en_consulta' THEN
    UPDATE doctores
    SET esta_disponible = false
    WHERE id = doctor_id_afectado;
    RETURN NEW;
  END IF;

  -- Caso: la cita SALE de enConsulta (update donde antes era enConsulta y ya no lo es,
  -- o un delete de una cita que estaba enConsulta)
  IF (TG_OP = 'UPDATE' AND OLD.estado = 'en_consulta' AND NEW.estado <> 'en_consulta')
     OR (TG_OP = 'DELETE' AND OLD.estado = 'en_consulta') THEN

    -- Verificar que no haya OTRA cita activa de ese doctor en enConsulta
    SELECT EXISTS (
      SELECT 1 FROM citas
      WHERE doctor_id = doctor_id_afectado
        AND estado = 'en_consulta'
        AND id <> COALESCE(NEW.id, OLD.id)
    ) INTO tiene_otra_consulta;

    IF NOT tiene_otra_consulta THEN
      UPDATE doctores
      SET esta_disponible = true
      WHERE id = doctor_id_afectado;
    END IF;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;$$;


ALTER FUNCTION "public"."sync_disponibilidad_doctor"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_modified_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_modified_column"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_timestamp"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_timestamp"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validar_caja_abierta"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if exists (
    select 1
      from public.cajas
     where id = new.caja_diaria_id
       and cerrada = true
  ) then
    raise exception 'No se pueden registrar movimientos en una caja que ya está cerrada.';
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."validar_caja_abierta"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validar_cita_item_plan"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_paciente_cita uuid;
  v_paciente_item uuid;
  v_estado        estado_item_plan;
  v_anulada       timestamptz;
begin
  select persona_id into v_paciente_cita
    from citas
   where id = new.cita_id and deleted_at is null;

  if v_paciente_cita is null then
    raise exception 'La cita % no existe o fue eliminada.', new.cita_id
      using errcode = '23503';
  end if;

  select pt.paciente_id, ipt.estado, ipt.deleted_at
    into v_paciente_item, v_estado, v_anulada
    from items_plan_tratamiento ipt
    join planes_tratamiento pt on pt.id = ipt.plan_id
   where ipt.id = new.item_plan_id
     and pt.deleted_at is null;

  if v_paciente_item is null then
    raise exception 'La actividad % no existe o su plan fue eliminado.', new.item_plan_id
      using errcode = '23503';
  end if;

  if v_anulada is not null then
    raise exception 'La actividad % fue retirada del plan y no puede agendarse.', new.item_plan_id
      using errcode = '23514';
  end if;

  if v_paciente_item <> v_paciente_cita then
    raise exception 'La actividad % pertenece al plan de otro paciente.', new.item_plan_id
      using errcode = '23514';
  end if;

  -- Agendar algo ya rechazado, cancelado o terminado no es una decisión válida:
  -- es un defecto de quien llama.
  if v_estado in ('rechazado', 'cancelado', 'completado') then
    raise exception 'La actividad % está %; no puede agendarse.', new.item_plan_id, v_estado
      using errcode = '23514';
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."validar_cita_item_plan"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."validar_cita_item_plan"() IS 'SD-146. Impide vincular a una cita una actividad de otro paciente, retirada del plan o ya decidida en contra/terminada.';



CREATE OR REPLACE FUNCTION "public"."validar_doctor_activo"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM personas 
        WHERE id = NEW.id AND estatus = 'activo'
    ) THEN
        RAISE EXCEPTION 'No se puede registrar o activar un doctor si la persona no está en estatus activo.';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."validar_doctor_activo"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validar_fecha_nacimiento"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    IF NEW.fecha_nacimiento > CURRENT_DATE THEN
        RAISE EXCEPTION 'La fecha de nacimiento (%) no puede ser una fecha futura.', NEW.fecha_nacimiento;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."validar_fecha_nacimiento"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validar_monto_cuotas"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
declare
  monto_total_cuenta decimal(15,2);
  monto_total_cuotas decimal(15,2);
begin
  select coalesce(sum(precio_unitario * cantidad), 0)
    into monto_total_cuenta
    from public.items_cuenta
   where cuenta_id = new.cuenta_id
     and deleted_at is null;

  select coalesce(sum(monto), 0) + new.monto
    into monto_total_cuotas
    from public.cuotas
   where cuenta_id = new.cuenta_id
     and id != new.id;

  if monto_total_cuotas > monto_total_cuenta then
    raise exception 'La suma de las cuotas (%) no puede ser mayor al total de la cuenta (%)',
      monto_total_cuotas, monto_total_cuenta;
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."validar_monto_cuotas"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validar_monto_pago"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
declare
  v_total   numeric(15,2);
  v_pagado  numeric(15,2);
  v_balance numeric(15,2);
begin
  -- Solo un pago marcado como recibido ('completado') consume saldo.
  if new.estado <> 'completado' then
    return new;
  end if;

  -- Total congelado de la cuenta (misma fuente que la RPC registrar_pago).
  select coalesce(monto_total, 0)
    into v_total
    from public.cuentas
   where id = new.cuenta_id;

  -- Pagos vigentes ya aplicados, excluyendo la fila actual (relevante en UPDATE).
  select coalesce(sum(monto), 0)
    into v_pagado
    from public.pagos
   where cuenta_id = new.cuenta_id
     and deleted_at is null
     and id is distinct from new.id;

  v_balance := v_total - v_pagado;

  if new.monto > v_balance + 0.01 then
    raise exception 'El monto del pago (%) excede el balance pendiente (%).',
      new.monto, v_balance;
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."validar_monto_pago"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."verificar_item_plan_ejecutable"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
declare
  v_estado public.estado_item_plan;
begin
  if new.item_plan_id is null then
    return new;
  end if;

  select estado into v_estado
  from public.items_plan_tratamiento
  where id = new.item_plan_id and deleted_at is null;

  if v_estado is null then
    raise exception 'El item de plan % no existe o fue eliminado.', new.item_plan_id;
  end if;

  if v_estado in ('propuesto', 'rechazado', 'cancelado') then
    raise exception
      'No se puede registrar la ejecución de una actividad en estado %. '
      'Debe estar aceptada, pendiente, en proceso o completada.', v_estado;
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."verificar_item_plan_ejecutable"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."dientes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "odontograma_id" "uuid" NOT NULL,
    "fdi_code" smallint NOT NULL,
    "observaciones" "text",
    "diagnostico_principal_id" "uuid",
    "tratamientos_aplicados_ids" "uuid"[] DEFAULT '{}'::"uuid"[],
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone,
    "deleted_at" timestamp with time zone,
    "superficies" "jsonb" DEFAULT '[]'::"jsonb",
    "esta_ausente" boolean DEFAULT false NOT NULL,
    CONSTRAINT "check_fdi_range" CHECK ((("fdi_code" >= 11) AND ("fdi_code" <= 85)))
);


ALTER TABLE "public"."dientes" OWNER TO "postgres";


COMMENT ON COLUMN "public"."dientes"."deleted_at" IS 'Marca de tiempo para borrado lógico. Si es NULL, el registro está activo.';



CREATE TABLE IF NOT EXISTS "public"."items_plan_tratamiento" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "plan_id" "uuid" NOT NULL,
    "tratamiento_id" "uuid" NOT NULL,
    "diagnostico_aplicado_id" "uuid",
    "diente_id" "uuid",
    "superficie" "public"."tipo_superficie",
    "estado" "public"."estado_item_plan" DEFAULT 'propuesto'::"public"."estado_item_plan" NOT NULL,
    "precio_estimado" numeric(15,2) DEFAULT 0 NOT NULL,
    "orden" integer DEFAULT 0 NOT NULL,
    "notas" "text",
    "doctor_propone_id" "uuid",
    "fecha_propuesta" timestamp with time zone DEFAULT "now"() NOT NULL,
    "fecha_aceptacion" timestamp with time zone,
    "fecha_rechazo" timestamp with time zone,
    "motivo_rechazo" "text",
    "fecha_inicio" timestamp with time zone,
    "fecha_completado" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "tipo_ejecucion" "text" DEFAULT 'unica'::"text" NOT NULL,
    "sesiones_planificadas" integer,
    CONSTRAINT "items_plan_fechas_coherentes" CHECK (((("estado" <> 'rechazado'::"public"."estado_item_plan") OR ("fecha_rechazo" IS NOT NULL)) AND (("estado" <> 'completado'::"public"."estado_item_plan") OR ("fecha_completado" IS NOT NULL)))),
    CONSTRAINT "items_plan_precio_no_negativo" CHECK (("precio_estimado" >= (0)::numeric)),
    CONSTRAINT "items_plan_sesiones_coherentes" CHECK (((("tipo_ejecucion" = 'unica'::"text") AND ("sesiones_planificadas" IS NULL)) OR ("tipo_ejecucion" = 'por_sesiones'::"text"))),
    CONSTRAINT "items_plan_tratamiento_sesiones_planificadas_check" CHECK ((("sesiones_planificadas" IS NULL) OR ("sesiones_planificadas" > 0))),
    CONSTRAINT "items_plan_tratamiento_tipo_ejecucion_check" CHECK (("tipo_ejecucion" = ANY (ARRAY['unica'::"text", 'por_sesiones'::"text"])))
);


ALTER TABLE "public"."items_plan_tratamiento" OWNER TO "postgres";


COMMENT ON TABLE "public"."items_plan_tratamiento" IS 'Actividad planificada sobre un diente/superficie. Su estado es la decisión clínica y del paciente; no genera cargo hasta ejecutarse.';



CREATE TABLE IF NOT EXISTS "public"."planes_tratamiento" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "paciente_id" "uuid" NOT NULL,
    "evaluacion_id" "uuid",
    "consulta_origen_id" "uuid",
    "doctor_id" "uuid" NOT NULL,
    "estado" "public"."estado_plan_tratamiento" DEFAULT 'borrador'::"public"."estado_plan_tratamiento" NOT NULL,
    "notas" "text",
    "fecha_propuesta" timestamp with time zone DEFAULT "now"() NOT NULL,
    "fecha_aceptacion" timestamp with time zone,
    "fecha_rechazo" timestamp with time zone,
    "motivo_rechazo" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "version" integer DEFAULT 1 NOT NULL
);


ALTER TABLE "public"."planes_tratamiento" OWNER TO "postgres";


COMMENT ON TABLE "public"."planes_tratamiento" IS 'Lo que se decide tratar. Agrupa las actividades propuestas al paciente a partir de una evaluación; solo un subconjunto de los hallazgos llega aquí.';



COMMENT ON COLUMN "public"."planes_tratamiento"."version" IS 'HFX-CLIN-003. Sube con cada cambio de actividades o precios; el consentimiento guarda la versión que el paciente vio.';



CREATE TABLE IF NOT EXISTS "public"."tratamientos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nombre" "text" NOT NULL,
    "descripcion" "text",
    "costo" numeric(15,2) DEFAULT 0.00 NOT NULL,
    "alcance" "public"."alcance" DEFAULT 'diente'::"public"."alcance" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "clave_odontograma" "text"
);


ALTER TABLE "public"."tratamientos" OWNER TO "postgres";


COMMENT ON TABLE "public"."tratamientos" IS 'Catálogo maestro de procedimientos dentales y sus costos base.';



CREATE OR REPLACE VIEW "public"."actividades_agendables_paciente" AS
 SELECT "pt"."paciente_id",
    "ipt"."id" AS "item_plan_id",
    "ipt"."plan_id",
    "ipt"."tratamiento_id",
    "t"."nombre" AS "tratamiento_nombre",
    "d"."fdi_code" AS "fdi_diente",
    "ipt"."superficie",
    "ipt"."estado",
    "ipt"."precio_estimado",
    "ipt"."orden"
   FROM ((("public"."items_plan_tratamiento" "ipt"
     JOIN "public"."planes_tratamiento" "pt" ON (("pt"."id" = "ipt"."plan_id")))
     LEFT JOIN "public"."tratamientos" "t" ON (("t"."id" = "ipt"."tratamiento_id")))
     LEFT JOIN "public"."dientes" "d" ON (("d"."id" = "ipt"."diente_id")))
  WHERE (("ipt"."deleted_at" IS NULL) AND ("pt"."deleted_at" IS NULL) AND ("ipt"."estado" = ANY (ARRAY['propuesto'::"public"."estado_item_plan", 'aceptado'::"public"."estado_item_plan", 'pendiente'::"public"."estado_item_plan", 'en_proceso'::"public"."estado_item_plan"])) AND ("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));


ALTER VIEW "public"."actividades_agendables_paciente" OWNER TO "postgres";


COMMENT ON VIEW "public"."actividades_agendables_paciente" IS 'SD-146. Actividades del plan de un paciente que todavía pueden agendarse en una cita. Mismo alcance de estados que acepta trg_validar_cita_item_plan.';



CREATE TABLE IF NOT EXISTS "public"."admins" (
    "id" "uuid" NOT NULL,
    "departamento" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone
);


ALTER TABLE "public"."admins" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."alertas_clinicas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "consulta_id" "uuid" NOT NULL,
    "regla_id" "uuid",
    "regla_codigo" "text" NOT NULL,
    "regla_version" integer DEFAULT 1 NOT NULL,
    "severidad" "text" NOT NULL,
    "accion" "text" NOT NULL,
    "mensaje" "text" NOT NULL,
    "disparador" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "estado" "text" DEFAULT 'pendiente'::"text" NOT NULL,
    "justificacion" "text",
    "resuelta_por" "uuid",
    "resuelta_en" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "alertas_clinicas_estado_check" CHECK (("estado" = ANY (ARRAY['pendiente'::"text", 'confirmada'::"text", 'documentada'::"text", 'obsoleta'::"text"]))),
    CONSTRAINT "alertas_clinicas_justificacion_check" CHECK ((("estado" <> 'documentada'::"text") OR (COALESCE("btrim"("justificacion"), ''::"text") <> ''::"text")))
);


ALTER TABLE "public"."alertas_clinicas" OWNER TO "postgres";


COMMENT ON TABLE "public"."alertas_clinicas" IS 'HFX-CLIN-003. Alerta emitida por el motor sobre una consulta. Guarda qué dato la disparó y qué acción exige.';



CREATE TABLE IF NOT EXISTS "public"."asistentes" (
    "id" "uuid" NOT NULL,
    "turno" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone
);


ALTER TABLE "public"."asistentes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."auditoria_clinica" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "consulta_id" "uuid",
    "evento" "text" NOT NULL,
    "actor_id" "uuid",
    "rol" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "cita_id" "uuid",
    CONSTRAINT "auditoria_clinica_ancla" CHECK ((("consulta_id" IS NOT NULL) OR ("cita_id" IS NOT NULL)))
);


ALTER TABLE "public"."auditoria_clinica" OWNER TO "postgres";


COMMENT ON COLUMN "public"."auditoria_clinica"."cita_id" IS 'HFX-CLIN-005. Ancla del evento cuando ocurre antes de existir la consulta (creación de la cita, llegada, reprogramación).';



CREATE TABLE IF NOT EXISTS "public"."auditoria_correcciones_clinicas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "consulta_id" "uuid" NOT NULL,
    "autor_original_id" "uuid" NOT NULL,
    "corregido_por" "uuid" NOT NULL,
    "motivo" "text" NOT NULL,
    "datos_anteriores" "jsonb" NOT NULL,
    "datos_nuevos" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "auditoria_correcciones_clinicas_motivo_check" CHECK (("length"("btrim"("motivo")) >= 10))
);


ALTER TABLE "public"."auditoria_correcciones_clinicas" OWNER TO "postgres";


COMMENT ON TABLE "public"."auditoria_correcciones_clinicas" IS 'HFX-CLIN-001: correcciones administrativas que conservan autoría clínica.';



CREATE TABLE IF NOT EXISTS "public"."auditoria_log" (
    "id" bigint NOT NULL,
    "usuario_id" "uuid",
    "accion" character varying(20) NOT NULL,
    "entidad" character varying(50) NOT NULL,
    "entidad_id" "text" NOT NULL,
    "detalles" "jsonb",
    "fecha" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."auditoria_log" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."auditoria_log_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."auditoria_log_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."auditoria_log_id_seq" OWNED BY "public"."auditoria_log"."id";



CREATE TABLE IF NOT EXISTS "public"."auditoria_operaciones_admin" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "actor_id" "uuid" NOT NULL,
    "operacion" "text" NOT NULL,
    "recurso_tipo" "text" NOT NULL,
    "recurso_id" "uuid",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."auditoria_operaciones_admin" OWNER TO "postgres";


COMMENT ON TABLE "public"."auditoria_operaciones_admin" IS 'HFX-CLIN-001: operaciones administrativas sin contraseñas ni payloads sensibles.';



CREATE TABLE IF NOT EXISTS "public"."auditoria_reglas_clinicas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "actor_id" "uuid",
    "operacion" "text" NOT NULL,
    "regla_id" "uuid" NOT NULL,
    "codigo" "text" NOT NULL,
    "version" integer NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "auditoria_reglas_clinicas_operacion_check" CHECK (("operacion" = ANY (ARRAY['publicada'::"text", 'retirada'::"text"])))
);


ALTER TABLE "public"."auditoria_reglas_clinicas" OWNER TO "postgres";


COMMENT ON TABLE "public"."auditoria_reglas_clinicas" IS 'HFX-CLIN-006. Quién cambió qué umbral clínico y por qué. La escriben sólo las RPC de publicación y retirada: un rastro que el auditado puede editar no audita nada.';



CREATE TABLE IF NOT EXISTS "public"."cajas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "fecha" timestamp with time zone DEFAULT "now"() NOT NULL,
    "monto_apertura" numeric(12,2) NOT NULL,
    "monto_cierre" numeric(12,2) DEFAULT 0 NOT NULL,
    "monto_esperado" numeric(12,2) DEFAULT 0 NOT NULL,
    "monto_real" numeric(12,2) DEFAULT 0 NOT NULL,
    "cerrada" boolean DEFAULT false NOT NULL,
    "abierta_por" "uuid",
    "cerrada_por" "uuid",
    "observaciones" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "cajas_monto_apertura_check" CHECK (("monto_apertura" >= (0)::numeric))
);


ALTER TABLE "public"."cajas" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cajas_diarias" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "fecha" "date" DEFAULT CURRENT_DATE,
    "monto_apertura" numeric(15,2) DEFAULT 0.00 NOT NULL,
    "monto_cierre" numeric(15,2) DEFAULT 0.00 NOT NULL,
    "monto_esperado" numeric(15,2) DEFAULT 0.00 NOT NULL,
    "monto_real" numeric(15,2) DEFAULT 0.00 NOT NULL,
    "cerrada" boolean DEFAULT false,
    "abierta_por" "uuid",
    "cerrada_por" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."cajas_diarias" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."catalogo_signos_vitales" (
    "codigo" "text" NOT NULL,
    "etiqueta" "text" NOT NULL,
    "unidad" "text" NOT NULL,
    "minimo_posible" numeric NOT NULL,
    "maximo_posible" numeric NOT NULL,
    "decimales" integer DEFAULT 0 NOT NULL,
    "orden" integer DEFAULT 0 NOT NULL,
    CONSTRAINT "catalogo_signos_vitales_rango" CHECK (("minimo_posible" < "maximo_posible"))
);


ALTER TABLE "public"."catalogo_signos_vitales" OWNER TO "postgres";


COMMENT ON TABLE "public"."catalogo_signos_vitales" IS 'HFX-CLIN-006. Definición de qué se puede medir y en qué rango es físicamente posible. Sólo lectura desde el cliente: la escriben las migraciones, porque de sus límites depende la barrera SV_RANGO_IMPOSIBLE.';



CREATE TABLE IF NOT EXISTS "public"."citas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "persona_id" "uuid" NOT NULL,
    "doctor_id" "uuid" NOT NULL,
    "fecha_hora" timestamp with time zone NOT NULL,
    "es_emergencia" boolean DEFAULT false,
    "estado" "public"."estado_cita" DEFAULT 'programada'::"public"."estado_cita",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "duracion_minutos" bigint DEFAULT 30 NOT NULL,
    "updated_at" timestamp with time zone,
    "motivo" "text",
    "fin" timestamp with time zone NOT NULL,
    CONSTRAINT "citas_duracion_posible" CHECK ((("duracion_minutos" > 0) AND ("duracion_minutos" <= 1440)))
);


ALTER TABLE "public"."citas" OWNER TO "postgres";


COMMENT ON COLUMN "public"."citas"."duracion_minutos" IS 'HFX-CLIN-004. Minutos que la cita ocupa la agenda del doctor. Obligatoria: define el intervalo que la restricción de exclusión compara.';



COMMENT ON COLUMN "public"."citas"."motivo" IS 'Motivo declarado al agendar la cita. Prellena consultas.motivo_consulta.';



COMMENT ON COLUMN "public"."citas"."fin" IS 'HFX-CLIN-004. Derivada de fecha_hora + duracion_minutos. La mantiene el trigger trg_citas_fin; no se escribe desde el cliente.';



CREATE TABLE IF NOT EXISTS "public"."citas_items_plan" (
    "cita_id" "uuid" NOT NULL,
    "item_plan_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."citas_items_plan" OWNER TO "postgres";


COMMENT ON TABLE "public"."citas_items_plan" IS 'Actividades del plan de tratamiento que se piensan atender en una cita (SD-146). Relación N:M: una cita puede cubrir varias actividades y una actividad puede reprogramarse a otra cita.';



CREATE TABLE IF NOT EXISTS "public"."compras" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "fecha" timestamp with time zone DEFAULT "now"() NOT NULL,
    "estado" "public"."estado_compra" DEFAULT 'pendiente'::"public"."estado_compra" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."compras" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."condiciones" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nombre" "text" NOT NULL,
    "tipo" "public"."tipo_condicion" NOT NULL,
    "categoria" "public"."categoria_condicion" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone
);


ALTER TABLE "public"."condiciones" OWNER TO "postgres";


COMMENT ON TABLE "public"."condiciones" IS 'Catálogo maestro de condiciones médicas, alergias y estados del paciente.';



CREATE TABLE IF NOT EXISTS "public"."condiciones_consulta" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "consulta_id" "uuid" NOT NULL,
    "condicion_id" "uuid" NOT NULL,
    "severidad" "text" DEFAULT 'moderada'::"text" NOT NULL,
    "notas" "text",
    "detectada_en" timestamp with time zone DEFAULT "now"() NOT NULL,
    "incorporar_al_expediente" boolean DEFAULT false NOT NULL,
    "confirmada_por" "uuid",
    "confirmada_en" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    CONSTRAINT "condiciones_consulta_severidad_check" CHECK (("severidad" = ANY (ARRAY['leve'::"text", 'moderada'::"text", 'severa'::"text"])))
);


ALTER TABLE "public"."condiciones_consulta" OWNER TO "postgres";


COMMENT ON TABLE "public"."condiciones_consulta" IS 'HFX-CLIN-003. Condición de catálogo detectada durante la consulta. Participa en contraindicaciones desde el momento en que se registra; el texto libre de consultas.temp_condiciones queda como complemento.';



CREATE TABLE IF NOT EXISTS "public"."consultas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "paciente_id" "uuid" NOT NULL,
    "doctor_id" "uuid" NOT NULL,
    "cita_id" "uuid",
    "fecha" timestamp with time zone DEFAULT "now"() NOT NULL,
    "motivo_consulta" "text",
    "temp_condiciones" "text"[] DEFAULT '{}'::"text"[],
    "created_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "notas" "text",
    "signos_vitales" "jsonb",
    "finalizada" boolean DEFAULT false,
    "tipo_atencion" "public"."tipo_atencion_clinica" DEFAULT 'consulta'::"public"."tipo_atencion_clinica" NOT NULL,
    "version" integer DEFAULT 1 NOT NULL,
    "finalizada_at" timestamp with time zone,
    "cerrada_por" "uuid",
    "cierre_key" "text"
);


ALTER TABLE "public"."consultas" OWNER TO "postgres";


COMMENT ON COLUMN "public"."consultas"."finalizada" IS 'Has the consult ended?';



COMMENT ON COLUMN "public"."consultas"."tipo_atencion" IS 'Evaluación = documenta hallazgos y plan; consulta = registra ejecución clínica.';



COMMENT ON COLUMN "public"."consultas"."version" IS 'Versión optimista del borrador clínico. La incrementa cada guardado servidor.';



COMMENT ON COLUMN "public"."consultas"."cierre_key" IS 'Clave de idempotencia del cierre. HFX-CLIN-007: junto con finalizada, finalizada_at, cerrada_por y version, no es escribible por authenticated; sólo la escribe cerrar_consulta.';



CREATE TABLE IF NOT EXISTS "public"."record_condicion" (
    "record_id" "uuid" NOT NULL,
    "condicion_id" "uuid" NOT NULL,
    "fecha_deteccion" timestamp with time zone DEFAULT "now"(),
    "medicamento" "text",
    "dosis" "text",
    "frecuencia" "text",
    "medico_tratante" "text",
    "contacto_medico" "text",
    "notas" "text",
    "activo" boolean DEFAULT true NOT NULL
);


ALTER TABLE "public"."record_condicion" OWNER TO "postgres";


COMMENT ON TABLE "public"."record_condicion" IS 'Relación entre expediente y condición médica con detalles de tratamiento externo.';



CREATE TABLE IF NOT EXISTS "public"."records" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "paciente_id" "uuid" NOT NULL,
    "tipo_sangre" "public"."tipo_sangre" NOT NULL,
    "cant_hijos" integer DEFAULT 0,
    "cirugias_previas" "text"[] DEFAULT '{}'::"text"[],
    "historial_familiar" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone
);


ALTER TABLE "public"."records" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."condiciones_activas_paciente" WITH ("security_invoker"='on') AS
 SELECT "rc"."record_id",
    "r"."paciente_id",
    "rc"."condicion_id",
    NULL::"uuid" AS "consulta_id",
    'expediente'::"text" AS "origen",
    NULL::"text" AS "severidad",
    "rc"."fecha_deteccion" AS "detectada_en"
   FROM ("public"."record_condicion" "rc"
     JOIN "public"."records" "r" ON (("r"."id" = "rc"."record_id")))
  WHERE ("rc"."activo" AND ("r"."deleted_at" IS NULL))
UNION ALL
 SELECT NULL::"uuid" AS "record_id",
    "c"."paciente_id",
    "cc"."condicion_id",
    "cc"."consulta_id",
    'consulta'::"text" AS "origen",
    "cc"."severidad",
    "cc"."detectada_en"
   FROM ("public"."condiciones_consulta" "cc"
     JOIN "public"."consultas" "c" ON (("c"."id" = "cc"."consulta_id")))
  WHERE (("cc"."deleted_at" IS NULL) AND ("c"."deleted_at" IS NULL));


ALTER VIEW "public"."condiciones_activas_paciente" OWNER TO "postgres";


COMMENT ON VIEW "public"."condiciones_activas_paciente" IS 'HFX-CLIN-003. Condiciones que deben participar en contraindicaciones: las del expediente y las descubiertas en consulta.';



CREATE TABLE IF NOT EXISTS "public"."consentimientos_plan" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "plan_id" "uuid" NOT NULL,
    "version_plan" integer NOT NULL,
    "decision" "text" NOT NULL,
    "items" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "total_aceptado" numeric(15,2) DEFAULT 0 NOT NULL,
    "persona_acepta" "text" NOT NULL,
    "relacion_con_paciente" "text" DEFAULT 'titular'::"text" NOT NULL,
    "metodo" "text" NOT NULL,
    "motivo_rechazo" "text",
    "registrado_por" "uuid",
    "fecha" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "consentimientos_plan_decision_check" CHECK (("decision" = ANY (ARRAY['aceptado'::"text", 'rechazado'::"text"]))),
    CONSTRAINT "consentimientos_plan_metodo_check" CHECK (("metodo" = ANY (ARRAY['verbal_presencial'::"text", 'firma_fisica'::"text", 'firma_digital'::"text", 'telefonico'::"text"]))),
    CONSTRAINT "consentimientos_plan_persona_check" CHECK ((COALESCE("btrim"("persona_acepta"), ''::"text") <> ''::"text")),
    CONSTRAINT "consentimientos_plan_rechazo_check" CHECK ((("decision" <> 'rechazado'::"text") OR (COALESCE("btrim"("motivo_rechazo"), ''::"text") <> ''::"text")))
);


ALTER TABLE "public"."consentimientos_plan" OWNER TO "postgres";


COMMENT ON TABLE "public"."consentimientos_plan" IS 'HFX-CLIN-003. Evidencia de la decisión del paciente: versión del plan mostrado, tratamientos y precios aceptados, quién decidió y por qué medio. Una decisión del doctor en la UI no es una firma del paciente.';



CREATE OR REPLACE VIEW "public"."consulta_resumen" AS
 SELECT "id",
    "paciente_id",
    "doctor_id",
    "fecha"
   FROM "public"."consultas";


ALTER VIEW "public"."consulta_resumen" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."consumibles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nombre" "text" NOT NULL,
    "descripcion" "text",
    "stock_actual" integer DEFAULT 0,
    "stock_minimo" integer DEFAULT 0,
    "estado" "public"."estado_consumible" DEFAULT 'disponible'::"public"."estado_consumible",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "precio" numeric(12,2) DEFAULT 0 NOT NULL,
    "suplidor_id" "uuid",
    "activo" boolean DEFAULT true NOT NULL,
    CONSTRAINT "consumibles_precio_no_negativo" CHECK (("precio" >= (0)::numeric)),
    CONSTRAINT "consumibles_stock_actual_no_negativo" CHECK (("stock_actual" >= 0)),
    CONSTRAINT "consumibles_stock_minimo_no_negativo" CHECK (("stock_minimo" >= 0))
);


ALTER TABLE "public"."consumibles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."consumibles_compras" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "compra_id" "uuid" NOT NULL,
    "consumible_id" "uuid" NOT NULL,
    "suplidor_id" "uuid" NOT NULL,
    "cantidad" integer NOT NULL,
    "precio_unitario" numeric(15,2) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "consumible_compra_cantidad_check" CHECK (("cantidad" > 0)),
    CONSTRAINT "consumible_compra_precio_unitario_check" CHECK (("precio_unitario" >= (0)::numeric))
);


ALTER TABLE "public"."consumibles_compras" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."consumos_consulta" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "consulta_id" "uuid" NOT NULL,
    "consumible_id" "uuid" NOT NULL,
    "nombre" "text",
    "cantidad" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    CONSTRAINT "consumos_consulta_cantidad_check" CHECK (("cantidad" > 0))
);


ALTER TABLE "public"."consumos_consulta" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."contactos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "email" "text",
    "numero_telefono" "text" NOT NULL,
    "direccion" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."contactos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."contraindicaciones" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tratamiento_id" "uuid",
    "medicina_id" "uuid",
    "procedimiento_id" "uuid",
    "descripcion" "text" NOT NULL,
    "tipo_contraindicacion" "public"."tipo_contraindicacion" DEFAULT 'relativa'::"public"."tipo_contraindicacion" NOT NULL,
    "efectos_adversos" "public"."efecto_adverso"[] DEFAULT '{}'::"public"."efecto_adverso"[],
    "created_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "condicion_id" "uuid" NOT NULL
);


ALTER TABLE "public"."contraindicaciones" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cuentas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "consulta_id" "uuid" NOT NULL,
    "fecha_creacion" timestamp with time zone DEFAULT "now"() NOT NULL,
    "fecha_pago" timestamp with time zone,
    "metodo_pago" "public"."modo_pago" NOT NULL,
    "nota" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "estado" "text" DEFAULT 'abierta'::"text" NOT NULL,
    "monto_total" numeric(12,2) DEFAULT 0 NOT NULL,
    "paciente_id" "uuid"
);


ALTER TABLE "public"."cuentas" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cuotas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "cuenta_id" "uuid" NOT NULL,
    "monto" numeric(15,2) NOT NULL,
    "fecha_vencimiento" "date" NOT NULL,
    "estado" "public"."estado_cuota" DEFAULT 'pendiente'::"public"."estado_cuota" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "monto_pagado" numeric(15,2) DEFAULT 0 NOT NULL,
    CONSTRAINT "cuotas_monto_pagado_check" CHECK ((("monto_pagado" >= (0)::numeric) AND ("monto_pagado" <= "monto")))
);


ALTER TABLE "public"."cuotas" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."diagnosticos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nombre" "text" NOT NULL,
    "descripcion" "text",
    "severidad_default" "public"."severidad_diagnosis" DEFAULT 'leve'::"public"."severidad_diagnosis" NOT NULL,
    "alcance" "public"."alcance" NOT NULL,
    "categoria" "public"."categoria_diagnosis" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "clave_odontograma" "text"
);


ALTER TABLE "public"."diagnosticos" OWNER TO "postgres";


COMMENT ON TABLE "public"."diagnosticos" IS 'Catálogo maestro de diagnósticos clínicos para uso en odontogramas y consultas.';



CREATE TABLE IF NOT EXISTS "public"."diagnosticos_aplicados" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "diagnosis_id" "uuid" NOT NULL,
    "severidad" "public"."severidad_diagnosis" NOT NULL,
    "fecha_aplicacion" timestamp with time zone DEFAULT "now"() NOT NULL,
    "notas" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "consulta_id" "uuid",
    "diente_id" "uuid",
    "superficie" "public"."tipo_superficie",
    "origen" "text" DEFAULT 'preexistente'::"text" NOT NULL,
    "evaluacion_id" "uuid"
);


ALTER TABLE "public"."diagnosticos_aplicados" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."pacientes" (
    "id" "uuid" NOT NULL,
    "genero" "public"."genero" NOT NULL,
    "trabajo" "text",
    "referencia" "text",
    "tipo_paciente" "public"."tipo_paciente" DEFAULT 'integrado'::"public"."tipo_paciente" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "created_at" timestamp with time zone,
    "peso" numeric(5,2),
    "altura" numeric(5,2),
    "foto_ruta" "text",
    "foto_mime_type" "text",
    "foto_tamano_bytes" integer,
    "foto_actualizada_en" timestamp with time zone,
    "version" integer DEFAULT 1 NOT NULL,
    CONSTRAINT "pacientes_foto_mime_type_check" CHECK ((("foto_mime_type" IS NULL) OR ("foto_mime_type" = 'image/jpeg'::"text"))),
    CONSTRAINT "pacientes_foto_tamano_bytes_check" CHECK ((("foto_tamano_bytes" IS NULL) OR (("foto_tamano_bytes" >= 1) AND ("foto_tamano_bytes" <= 2097152))))
);


ALTER TABLE "public"."pacientes" OWNER TO "postgres";


COMMENT ON COLUMN "public"."pacientes"."peso" IS 'Peso base del paciente en kg o lbs';



COMMENT ON COLUMN "public"."pacientes"."altura" IS 'Altura del paciente en cm';



COMMENT ON COLUMN "public"."pacientes"."version" IS 'HFX-CLIN-004. Versión optimista de la ficha. La incrementa actualizar_paciente; un desajuste devuelve CL019.';



CREATE TABLE IF NOT EXISTS "public"."personas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nombre" "text" NOT NULL,
    "apellido" "text" NOT NULL,
    "fecha_nacimiento" "date" NOT NULL,
    "cedula" "text" NOT NULL,
    "estatus" "public"."estatus_persona" DEFAULT 'activo'::"public"."estatus_persona",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."personas" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."directorio_pacientes" AS
 SELECT "p"."id",
    "per"."nombre",
    "per"."apellido"
   FROM ("public"."pacientes" "p"
     JOIN "public"."personas" "per" ON (("per"."id" = "p"."id")))
  WHERE ("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"());


ALTER VIEW "public"."directorio_pacientes" OWNER TO "postgres";


COMMENT ON VIEW "public"."directorio_pacientes" IS 'Directorio de nombres de pacientes, legible por todo el personal clínico autenticado. Existe para que los listados (consultas, agenda) puedan mostrar un nombre en filas cuyo paciente el rol no tiene derecho a abrir por completo. Sin datos clínicos ni de contacto: la ficha sigue gobernada por puede_ver_paciente().';



CREATE TABLE IF NOT EXISTS "public"."doctor_asistentes" (
    "doctor_id" "uuid" NOT NULL,
    "asistente_id" "uuid" NOT NULL
);


ALTER TABLE "public"."doctor_asistentes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."doctor_paciente" (
    "id" bigint NOT NULL,
    "doctor_id" "uuid" NOT NULL,
    "paciente_id" "uuid" NOT NULL,
    "fecha_asignacion" timestamp with time zone DEFAULT "now"() NOT NULL,
    "fecha_fin" timestamp with time zone,
    "activo" boolean DEFAULT true NOT NULL,
    "asignado_por" "uuid",
    "motivo" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE ONLY "public"."doctor_paciente" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."doctor_paciente" OWNER TO "postgres";


COMMENT ON TABLE "public"."doctor_paciente" IS 'Asignación explícita de qué doctor(es) tienen acceso a la información de un paciente. Reemplaza cualquier inferencia basada en citas. Una fila con activo=true representa una asignación vigente; el historial se preserva marcando activo=false en vez de borrar.';



CREATE SEQUENCE IF NOT EXISTS "public"."doctor_paciente_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."doctor_paciente_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."doctor_paciente_id_seq" OWNED BY "public"."doctor_paciente"."id";



CREATE TABLE IF NOT EXISTS "public"."doctores" (
    "id" "uuid" NOT NULL,
    "especialidad" "text" NOT NULL,
    "esta_disponible" boolean DEFAULT true,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone
);


ALTER TABLE "public"."doctores" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."documentos_clinicos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "paciente_id" "uuid" NOT NULL,
    "consulta_id" "uuid" NOT NULL,
    "descripcion" "text" NOT NULL,
    "tipo_documento" "public"."tipo_documento" NOT NULL,
    "url_archivo" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."documentos_clinicos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."equipos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nombre" "text" NOT NULL,
    "descripcion" "text",
    "ultimo_mantenimiento" timestamp with time zone NOT NULL,
    "tiempo_para_mantenimiento" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."equipos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."equipos_mantenimientos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "equipo_id" "uuid" NOT NULL,
    "consumible_id" "uuid",
    "suplidor_id" "uuid",
    "descripcion" "text" NOT NULL,
    "costo" numeric(15,2) DEFAULT 0.00 NOT NULL,
    "fecha_mantenimiento" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."equipos_mantenimientos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."evaluaciones_clinicas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "paciente_id" "uuid" NOT NULL,
    "consulta_id" "uuid",
    "doctor_id" "uuid" NOT NULL,
    "fecha" timestamp with time zone DEFAULT "now"() NOT NULL,
    "motivo" "text",
    "resumen" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone
);


ALTER TABLE "public"."evaluaciones_clinicas" OWNER TO "postgres";


COMMENT ON TABLE "public"."evaluaciones_clinicas" IS 'Acto de evaluar al paciente. Sus hallazgos son las filas de diagnosticos_aplicados. Registrar un hallazgo aquí NO crea tratamiento aplicado ni cuenta (SD-135).';



CREATE TABLE IF NOT EXISTS "public"."items_cuenta" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "cuenta_id" "uuid" NOT NULL,
    "descripcion" "text" NOT NULL,
    "precio_unitario" numeric(15,2) DEFAULT 0.00 NOT NULL,
    "cantidad" integer DEFAULT 1 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "tratamiento_aplicado_id" "uuid"
);


ALTER TABLE "public"."items_cuenta" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."items_receta" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "receta_id" "uuid" NOT NULL,
    "medicamento_id" "uuid",
    "nombre_medicamento" "text" NOT NULL,
    "presentacion_concentracion" "text" DEFAULT ''::"text",
    "dosis" "text" NOT NULL,
    "via_administracion" "text" DEFAULT 'vía oral'::"text",
    "frecuencia" "text" NOT NULL,
    "duracion" "text" NOT NULL,
    "cantidad_indicada" "text" DEFAULT ''::"text",
    "indicaciones_especificas" "text" DEFAULT ''::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone
);


ALTER TABLE "public"."items_receta" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."medicinas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nombre" "text" NOT NULL,
    "efectos_secundarios" "public"."efecto_secundario"[],
    "created_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "principio_activo" "text"
);


ALTER TABLE "public"."medicinas" OWNER TO "postgres";


COMMENT ON COLUMN "public"."medicinas"."principio_activo" IS 'HFX-CLIN-003. Cuando falta, el sistema informa "información insuficiente" en vez de afirmar que no hay conflicto.';



CREATE TABLE IF NOT EXISTS "public"."movimientos_caja" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "caja_diaria_id" "uuid" NOT NULL,
    "tipo" "public"."tipo_movimiento" NOT NULL,
    "monto" numeric(15,2) NOT NULL,
    "descripcion" "text" NOT NULL,
    "fecha" timestamp with time zone DEFAULT "now"() NOT NULL,
    "referencia_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone,
    "deleted_at" timestamp with time zone,
    "metodo_pago" "text" DEFAULT 'efectivo'::"text" NOT NULL
);


ALTER TABLE "public"."movimientos_caja" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."movimientos_stock_consumible" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "consumible_id" "uuid" NOT NULL,
    "stock_anterior" integer NOT NULL,
    "stock_nuevo" integer NOT NULL,
    "diferencia" integer NOT NULL,
    "motivo" "text" NOT NULL,
    "creado_por" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "consulta_id" "uuid",
    CONSTRAINT "movimientos_stock_consumible_diferencia_check" CHECK (("diferencia" = ("stock_nuevo" - "stock_anterior"))),
    CONSTRAINT "movimientos_stock_consumible_motivo_check" CHECK (("motivo" = ANY (ARRAY['merma'::"text", 'correccion'::"text", 'usoInterno'::"text", 'consumoClinico'::"text"]))),
    CONSTRAINT "movimientos_stock_consumible_stock_anterior_check" CHECK (("stock_anterior" >= 0)),
    CONSTRAINT "movimientos_stock_consumible_stock_nuevo_check" CHECK (("stock_nuevo" >= 0))
);


ALTER TABLE "public"."movimientos_stock_consumible" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."odontogramas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "consulta_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone,
    "deleted_at" timestamp with time zone,
    "evaluacion_clinica" "jsonb" DEFAULT '{"hallazgos": {}, "tejidos_blandos": {}}'::"jsonb" NOT NULL
);


ALTER TABLE "public"."odontogramas" OWNER TO "postgres";


COMMENT ON COLUMN "public"."odontogramas"."evaluacion_clinica" IS 'Odontodiagrama SD-141: hallazgos FDI por superficie y tejidos blandos.';



CREATE TABLE IF NOT EXISTS "public"."ordenes_medicas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "consulta_id" "uuid" NOT NULL,
    "procedimiento_id" "uuid" NOT NULL,
    "fecha" timestamp with time zone DEFAULT "now"() NOT NULL,
    "notas" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone
);


ALTER TABLE "public"."ordenes_medicas" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."pagos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "cuenta_id" "uuid" NOT NULL,
    "monto" numeric(15,2) NOT NULL,
    "fecha" timestamp with time zone DEFAULT "now"() NOT NULL,
    "estado" "public"."estado_pago" DEFAULT 'pendiente'::"public"."estado_pago" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "metodo_pago" "public"."metodo_pago",
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "cuota_id" "uuid",
    CONSTRAINT "pagos_monto_check" CHECK (("monto" > (0)::numeric))
);


ALTER TABLE "public"."pagos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."persona_contactos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "persona_id" "uuid",
    "contacto_id" "uuid",
    "tipo_contacto" "text" DEFAULT 'personal'::"text",
    "es_principal" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "es_emergencia" boolean DEFAULT false
);


ALTER TABLE "public"."persona_contactos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."procedimientos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nombre" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."procedimientos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."recetas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "consulta_id" "uuid" NOT NULL,
    "medicina_id" "uuid",
    "titulo" "text",
    "dosis" "text",
    "frecuencia" "text",
    "indicaciones" "text",
    "duracion" "text",
    "notas" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "title" "text",
    "paciente_id" "uuid",
    "doctor_id" "uuid",
    "fecha_emision" timestamp with time zone DEFAULT "now"(),
    "indicaciones_generales" "text",
    "justificacion_contraindicaciones" "text",
    "estado" "text" DEFAULT 'borrador'::"text",
    "motivo_anulacion" "text",
    "receta_reemplazada_id" "uuid",
    "items_receta" "jsonb" DEFAULT '[]'::"jsonb",
    "version" integer DEFAULT 1 NOT NULL,
    "emitida_at" timestamp with time zone,
    "codigo_receta" "text",
    CONSTRAINT "recetas_estado_check" CHECK (("estado" = ANY (ARRAY['borrador'::"text", 'emitida'::"text", 'anulada'::"text", 'reemplazada'::"text"])))
);


ALTER TABLE "public"."recetas" OWNER TO "postgres";


COMMENT ON COLUMN "public"."recetas"."estado" IS 'activa | anulada | reemplazada. Una receta corregida apunta a la anterior con receta_reemplazada_id en vez de editarla.';



COMMENT ON COLUMN "public"."recetas"."items_receta" IS 'SD-153: medicinas de la receta. Cada elemento lleva nombre, presentación, dosis, vía, frecuencia, duración, cantidad e indicaciones específicas.';



COMMENT ON COLUMN "public"."recetas"."version" IS 'Versión de la receta. Permite detectar ediciones concurrentes del borrador.';



CREATE TABLE IF NOT EXISTS "public"."reglas_clinicas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "codigo" "text" NOT NULL,
    "version" integer DEFAULT 1 NOT NULL,
    "nombre" "text" NOT NULL,
    "descripcion" "text",
    "categoria" "text" NOT NULL,
    "tipo" "text" NOT NULL,
    "parametros" "jsonb",
    "accion" "text" NOT NULL,
    "severidad" "text" DEFAULT 'advertencia'::"text" NOT NULL,
    "estado" "text" DEFAULT 'pendiente_aprobacion'::"text" NOT NULL,
    "fuente" "text",
    "aprobada_por" "uuid",
    "aprobada_en" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "reglas_clinicas_accion_check" CHECK (("accion" = ANY (ARRAY['advertir'::"text", 'confirmar'::"text", 'documentar'::"text", 'bloquear_electivo'::"text", 'referir'::"text"]))),
    CONSTRAINT "reglas_clinicas_aprobada_completa" CHECK ((("estado" <> 'aprobada'::"text") OR (("parametros" IS NOT NULL) AND ("aprobada_en" IS NOT NULL)))),
    CONSTRAINT "reglas_clinicas_categoria_check" CHECK (("categoria" = ANY (ARRAY['signo_vital'::"text", 'condicion'::"text", 'medicamento'::"text", 'tratamiento'::"text"]))),
    CONSTRAINT "reglas_clinicas_estado_check" CHECK (("estado" = ANY (ARRAY['pendiente_aprobacion'::"text", 'aprobada'::"text", 'retirada'::"text"]))),
    CONSTRAINT "reglas_clinicas_severidad_check" CHECK (("severidad" = ANY (ARRAY['informativa'::"text", 'advertencia'::"text", 'critica'::"text", 'absoluta'::"text"]))),
    CONSTRAINT "reglas_clinicas_tipo_check" CHECK (("tipo" = ANY (ARRAY['rango_imposible'::"text", 'relacion_imposible'::"text", 'valor_critico'::"text", 'combinacion_condicion_signo'::"text", 'requisito_dato'::"text"])))
);


ALTER TABLE "public"."reglas_clinicas" OWNER TO "postgres";


COMMENT ON TABLE "public"."reglas_clinicas" IS 'HFX-CLIN-003. Reglas del motor de alertas. Solo evalúan las aprobadas con parámetros; los umbrales clínicos requieren aprobación del dueño doctor.';



COMMENT ON COLUMN "public"."reglas_clinicas"."parametros" IS 'Forma según tipo. valor_critico: {"codigo":"pulso","min":50,"max":110}. combinacion_condicion_signo: {"condicion":"embarazo","signos":[{"codigo":"presion_sistolica","max":140}]}. requisito_dato: {"codigo":"peso","exige_al_recetar":true}. Cualquier regla admite además "edad_min_anios" y "edad_max_anios" para limitarla a una franja etaria.';



CREATE TABLE IF NOT EXISTS "public"."tratamientos_aplicados" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tratamiento_id" "uuid" NOT NULL,
    "tratamiento_padre_id" "uuid",
    "es_continuo" boolean DEFAULT false,
    "esta_terminado" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "diente_id" "uuid",
    "superficie" "public"."tipo_superficie",
    "precio_aplicado" numeric(10,2),
    "consulta_id" "uuid",
    "notas" "text",
    "estado" "text" DEFAULT 'aplicado'::"text" NOT NULL,
    "item_plan_id" "uuid",
    "doctor_ejecuta_id" "uuid",
    "fecha_ejecucion" timestamp with time zone,
    "justificacion_no_planificada" "text",
    "cantidad_realizada" numeric(10,2) DEFAULT 1 NOT NULL,
    CONSTRAINT "tratamientos_aplicados_cantidad_realizada_check" CHECK (("cantidad_realizada" > (0)::numeric)),
    CONSTRAINT "tratamientos_aplicados_solo_ejecucion" CHECK ((("deleted_at" IS NOT NULL) OR ("estado" = ANY (ARRAY['aplicado'::"text", 'en_proceso'::"text", 'completado'::"text"]))))
);


ALTER TABLE "public"."tratamientos_aplicados" OWNER TO "postgres";


COMMENT ON COLUMN "public"."tratamientos_aplicados"."justificacion_no_planificada" IS 'Motivo clínico opcional para una ejecución sin item_plan_id.';



CREATE OR REPLACE VIEW "public"."resumen_actividad_plan" AS
 WITH "realizado" AS (
         SELECT "ta"."item_plan_id",
            "sum"("ta"."cantidad_realizada") AS "cantidad_realizada_total",
            "sum"(("ta"."precio_aplicado" * "ta"."cantidad_realizada")) AS "monto_realizado"
           FROM "public"."tratamientos_aplicados" "ta"
          WHERE (("ta"."deleted_at" IS NULL) AND (COALESCE("ta"."estado", 'aplicado'::"text") <> 'indicado'::"text"))
          GROUP BY "ta"."item_plan_id"
        ), "facturado" AS (
         SELECT "ta"."item_plan_id",
            "sum"(("ic"."precio_unitario" * ("ic"."cantidad")::numeric)) AS "monto_facturado",
            "array_agg"(DISTINCT "ic"."cuenta_id") AS "cuentas_involucradas"
           FROM ("public"."items_cuenta" "ic"
             JOIN "public"."tratamientos_aplicados" "ta" ON (("ta"."id" = "ic"."tratamiento_aplicado_id")))
          WHERE (("ic"."deleted_at" IS NULL) AND ("ta"."deleted_at" IS NULL))
          GROUP BY "ta"."item_plan_id"
        ), "pagos_por_cuenta" AS (
         SELECT "c"."id" AS "cuenta_id",
            "c"."monto_total",
            COALESCE("sum"("p_1"."monto"), (0)::numeric) AS "total_pagado_cuenta"
           FROM ("public"."cuentas" "c"
             LEFT JOIN "public"."pagos" "p_1" ON ((("p_1"."cuenta_id" = "c"."id") AND ("p_1"."deleted_at" IS NULL) AND ("p_1"."estado" = 'completado'::"public"."estado_pago"))))
          WHERE ("c"."deleted_at" IS NULL)
          GROUP BY "c"."id", "c"."monto_total"
        ), "pagado" AS (
         SELECT "ta"."item_plan_id",
            "sum"(
                CASE
                    WHEN ("ppc"."monto_total" > (0)::numeric) THEN ((("ic"."precio_unitario" * ("ic"."cantidad")::numeric) / "ppc"."monto_total") * "ppc"."total_pagado_cuenta")
                    ELSE (0)::numeric
                END) AS "monto_pagado_prorrateado"
           FROM (("public"."items_cuenta" "ic"
             JOIN "public"."tratamientos_aplicados" "ta" ON (("ta"."id" = "ic"."tratamiento_aplicado_id")))
             JOIN "pagos_por_cuenta" "ppc" ON (("ppc"."cuenta_id" = "ic"."cuenta_id")))
          WHERE (("ic"."deleted_at" IS NULL) AND ("ta"."deleted_at" IS NULL))
          GROUP BY "ta"."item_plan_id"
        )
 SELECT "ipt"."id" AS "item_plan_id",
    "ipt"."plan_id",
    "pt"."paciente_id",
    "ipt"."tratamiento_id",
    "t"."nombre" AS "tratamiento_nombre",
    "ipt"."tipo_ejecucion",
    "ipt"."sesiones_planificadas",
    "ipt"."estado",
    "ipt"."precio_estimado" AS "monto_presupuestado",
    COALESCE("r"."cantidad_realizada_total", (0)::numeric) AS "cantidad_realizada",
    COALESCE("r"."monto_realizado", (0)::numeric) AS "monto_realizado",
    COALESCE("f"."monto_facturado", (0)::numeric) AS "monto_facturado",
    COALESCE("p"."monto_pagado_prorrateado", (0)::numeric) AS "monto_pagado",
    GREATEST(("ipt"."precio_estimado" - COALESCE("f"."monto_facturado", (0)::numeric)), (0)::numeric) AS "monto_pendiente"
   FROM ((((("public"."items_plan_tratamiento" "ipt"
     JOIN "public"."planes_tratamiento" "pt" ON (("pt"."id" = "ipt"."plan_id")))
     LEFT JOIN "public"."tratamientos" "t" ON (("t"."id" = "ipt"."tratamiento_id")))
     LEFT JOIN "realizado" "r" ON (("r"."item_plan_id" = "ipt"."id")))
     LEFT JOIN "facturado" "f" ON (("f"."item_plan_id" = "ipt"."id")))
     LEFT JOIN "pagado" "p" ON (("p"."item_plan_id" = "ipt"."id")))
  WHERE ("ipt"."deleted_at" IS NULL);


ALTER VIEW "public"."resumen_actividad_plan" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."resumen_actividades_cita" AS
 SELECT "cip"."cita_id",
    "ipt"."id" AS "item_plan_id",
    "ipt"."plan_id",
    "ipt"."tratamiento_id",
    "t"."nombre" AS "tratamiento_nombre",
    "d"."fdi_code" AS "fdi_diente",
    "ipt"."superficie",
    "ipt"."estado",
    "ipt"."precio_estimado",
    "ipt"."orden"
   FROM (((("public"."citas_items_plan" "cip"
     JOIN "public"."items_plan_tratamiento" "ipt" ON (("ipt"."id" = "cip"."item_plan_id")))
     JOIN "public"."planes_tratamiento" "pt" ON (("pt"."id" = "ipt"."plan_id")))
     LEFT JOIN "public"."tratamientos" "t" ON (("t"."id" = "ipt"."tratamiento_id")))
     LEFT JOIN "public"."dientes" "d" ON (("d"."id" = "ipt"."diente_id")))
  WHERE (("ipt"."deleted_at" IS NULL) AND ("pt"."deleted_at" IS NULL) AND ("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));


ALTER VIEW "public"."resumen_actividades_cita" OWNER TO "postgres";


COMMENT ON VIEW "public"."resumen_actividades_cita" IS 'SD-146. Resumen mínimo de las actividades planificadas de cada cita, legible por el asistente que agenda. No expone diagnóstico ni notas clínicas.';



CREATE SEQUENCE IF NOT EXISTS "public"."secuencia_codigo_receta"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."secuencia_codigo_receta" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."signos_vitales_consulta" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "consulta_id" "uuid" NOT NULL,
    "codigo" "text" NOT NULL,
    "valor" numeric NOT NULL,
    "unidad" "text" NOT NULL,
    "medido_en" timestamp with time zone DEFAULT "now"() NOT NULL,
    "medido_por" "uuid",
    "origen" "text" DEFAULT 'medido'::"text" NOT NULL,
    "observacion" "text",
    "estado_validacion" "text" DEFAULT 'valido'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    CONSTRAINT "signos_vitales_estado_check" CHECK (("estado_validacion" = ANY (ARRAY['valido'::"text", 'confirmado_por_doctor'::"text", 'descartado'::"text"]))),
    CONSTRAINT "signos_vitales_origen_check" CHECK (("origen" = ANY (ARRAY['medido'::"text", 'referido'::"text", 'dispositivo'::"text"])))
);


ALTER TABLE "public"."signos_vitales_consulta" OWNER TO "postgres";


COMMENT ON TABLE "public"."signos_vitales_consulta" IS 'HFX-CLIN-003. Una medición por fila: valor, unidad, momento, actor, origen y estado de validación.';



CREATE TABLE IF NOT EXISTS "public"."superficies" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "diente_id" "uuid" NOT NULL,
    "tipo_superficie" "public"."tipo_superficie" NOT NULL,
    "diagnostico_aplicado_id" "uuid",
    "tratamientos_ids" "uuid"[] DEFAULT '{}'::"uuid"[],
    "created_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."superficies" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."suplidores" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nombre" "text" NOT NULL,
    "tipo_suplidor" "public"."tipo_suplidor" NOT NULL,
    "summary" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."suplidores" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."suplidores_contactos" (
    "suplidor_id" "uuid" NOT NULL,
    "contacto_id" "uuid" NOT NULL,
    "etiqueta" "text"
);


ALTER TABLE "public"."suplidores_contactos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."usuarios" (
    "id" "uuid" NOT NULL,
    "username" "text" NOT NULL,
    "password_hash" "text",
    "last_login" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."usuarios" OWNER TO "postgres";


COMMENT ON COLUMN "public"."usuarios"."password_hash" IS 'Hash Bcrypt o Argon2 de la contraseña. No almacenar texto claro.';



ALTER TABLE ONLY "public"."auditoria_log" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."auditoria_log_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."doctor_paciente" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."doctor_paciente_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."admins"
    ADD CONSTRAINT "admin_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."alertas_clinicas"
    ADD CONSTRAINT "alertas_clinicas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."asistentes"
    ADD CONSTRAINT "asistentes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."auditoria_clinica"
    ADD CONSTRAINT "auditoria_clinica_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."auditoria_correcciones_clinicas"
    ADD CONSTRAINT "auditoria_correcciones_clinicas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."auditoria_log"
    ADD CONSTRAINT "auditoria_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."auditoria_operaciones_admin"
    ADD CONSTRAINT "auditoria_operaciones_admin_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."auditoria_reglas_clinicas"
    ADD CONSTRAINT "auditoria_reglas_clinicas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajas_diarias"
    ADD CONSTRAINT "caja_diaria_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajas"
    ADD CONSTRAINT "cajas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."catalogo_signos_vitales"
    ADD CONSTRAINT "catalogo_signos_vitales_pkey" PRIMARY KEY ("codigo");



ALTER TABLE ONLY "public"."citas_items_plan"
    ADD CONSTRAINT "citas_items_plan_pkey" PRIMARY KEY ("cita_id", "item_plan_id");



ALTER TABLE ONLY "public"."citas"
    ADD CONSTRAINT "citas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."citas"
    ADD CONSTRAINT "citas_sin_solape" EXCLUDE USING "gist" ("doctor_id" WITH =, "tstzrange"("fecha_hora", "fin", '[)'::"text") WITH &&) WHERE ((("deleted_at" IS NULL) AND (COALESCE("es_emergencia", false) = false) AND ("estado" <> ALL (ARRAY['cancelada'::"public"."estado_cita", 'completada'::"public"."estado_cita", 'no_asistio'::"public"."estado_cita", 'no_asistida'::"public"."estado_cita"]))));



COMMENT ON CONSTRAINT "citas_sin_solape" ON "public"."citas" IS 'HFX-CLIN-004. Un doctor no puede tener dos citas vivas cuyos intervalos se crucen. Las citas consecutivas no se cruzan: el rango es semiabierto. Las emergencias quedan fuera a propósito.';



ALTER TABLE ONLY "public"."compras"
    ADD CONSTRAINT "compras_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."condiciones_consulta"
    ADD CONSTRAINT "condiciones_consulta_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."condiciones"
    ADD CONSTRAINT "condiciones_nombre_key" UNIQUE ("nombre");



ALTER TABLE ONLY "public"."condiciones"
    ADD CONSTRAINT "condiciones_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."consentimientos_plan"
    ADD CONSTRAINT "consentimientos_plan_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."consultas"
    ADD CONSTRAINT "consultas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."consumibles_compras"
    ADD CONSTRAINT "consumible_compra_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."consumibles"
    ADD CONSTRAINT "consumibles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."consumos_consulta"
    ADD CONSTRAINT "consumos_consulta_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."contactos"
    ADD CONSTRAINT "contactos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."contraindicaciones"
    ADD CONSTRAINT "contraindicaciones_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cuentas"
    ADD CONSTRAINT "cuentas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cuotas"
    ADD CONSTRAINT "cuotas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."diagnosticos"
    ADD CONSTRAINT "diagnosis_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."diagnosticos_aplicados"
    ADD CONSTRAINT "diagnosticos_aplicados_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."dientes"
    ADD CONSTRAINT "dientes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."doctor_asistentes"
    ADD CONSTRAINT "doctor_asistentes_pkey" PRIMARY KEY ("doctor_id", "asistente_id");



ALTER TABLE ONLY "public"."doctor_paciente"
    ADD CONSTRAINT "doctor_paciente_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."doctores"
    ADD CONSTRAINT "doctores_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."documentos_clinicos"
    ADD CONSTRAINT "documentos_clinicos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."equipos_mantenimientos"
    ADD CONSTRAINT "equipos_mantenimiento_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."equipos"
    ADD CONSTRAINT "equipos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."evaluaciones_clinicas"
    ADD CONSTRAINT "evaluaciones_clinicas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."items_cuenta"
    ADD CONSTRAINT "item_cuentas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."items_plan_tratamiento"
    ADD CONSTRAINT "items_plan_tratamiento_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."items_receta"
    ADD CONSTRAINT "items_receta_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."medicinas"
    ADD CONSTRAINT "medicinas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."movimientos_caja"
    ADD CONSTRAINT "movimientos_caja_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."movimientos_stock_consumible"
    ADD CONSTRAINT "movimientos_stock_consumible_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."odontogramas"
    ADD CONSTRAINT "odontogramas_consulta_id_key" UNIQUE ("consulta_id");



ALTER TABLE ONLY "public"."odontogramas"
    ADD CONSTRAINT "odontogramas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ordenes_medicas"
    ADD CONSTRAINT "ordenes_medicas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pacientes"
    ADD CONSTRAINT "pacientes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."pagos"
    ADD CONSTRAINT "pagos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."persona_contactos"
    ADD CONSTRAINT "persona_contactos_persona_id_contacto_id_key" UNIQUE ("persona_id", "contacto_id");



ALTER TABLE ONLY "public"."persona_contactos"
    ADD CONSTRAINT "persona_contactos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."personas"
    ADD CONSTRAINT "personas_cedula_key" UNIQUE ("cedula");



ALTER TABLE ONLY "public"."personas"
    ADD CONSTRAINT "personas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."planes_tratamiento"
    ADD CONSTRAINT "planes_tratamiento_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."procedimientos"
    ADD CONSTRAINT "procedimientos_nombre_key" UNIQUE ("nombre");



ALTER TABLE ONLY "public"."procedimientos"
    ADD CONSTRAINT "procedimientos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."recetas"
    ADD CONSTRAINT "recetas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."record_condicion"
    ADD CONSTRAINT "record_afliccion_pkey" PRIMARY KEY ("record_id", "condicion_id");



ALTER TABLE ONLY "public"."records"
    ADD CONSTRAINT "records_paciente_id_key" UNIQUE ("paciente_id");



ALTER TABLE ONLY "public"."records"
    ADD CONSTRAINT "records_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."reglas_clinicas"
    ADD CONSTRAINT "reglas_clinicas_codigo_version_uk" UNIQUE ("codigo", "version");



ALTER TABLE ONLY "public"."reglas_clinicas"
    ADD CONSTRAINT "reglas_clinicas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."signos_vitales_consulta"
    ADD CONSTRAINT "signos_vitales_consulta_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."superficies"
    ADD CONSTRAINT "superficies_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."suplidores_contactos"
    ADD CONSTRAINT "suplidor_contacto_pkey" PRIMARY KEY ("suplidor_id", "contacto_id");



ALTER TABLE ONLY "public"."suplidores"
    ADD CONSTRAINT "suplidores_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tratamientos_aplicados"
    ADD CONSTRAINT "tratamientos_aplicados_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tratamientos"
    ADD CONSTRAINT "tratamientos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajas_diarias"
    ADD CONSTRAINT "unica_caja_por_dia" UNIQUE ("fecha");



ALTER TABLE ONLY "public"."usuarios"
    ADD CONSTRAINT "usuarios_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."usuarios"
    ADD CONSTRAINT "usuarios_username_key" UNIQUE ("username");



CREATE INDEX "alertas_clinicas_consulta_idx" ON "public"."alertas_clinicas" USING "btree" ("consulta_id", "created_at" DESC);



CREATE UNIQUE INDEX "alertas_clinicas_vigente_uk" ON "public"."alertas_clinicas" USING "btree" ("consulta_id", "regla_codigo", "regla_version") WHERE ("estado" <> 'obsoleta'::"text");



CREATE INDEX "auditoria_clinica_cita_idx" ON "public"."auditoria_clinica" USING "btree" ("cita_id", "created_at");



CREATE INDEX "auditoria_clinica_consulta_cronologico_idx" ON "public"."auditoria_clinica" USING "btree" ("consulta_id", "created_at");



CREATE INDEX "auditoria_clinica_consulta_idx" ON "public"."auditoria_clinica" USING "btree" ("consulta_id", "created_at" DESC);



CREATE INDEX "auditoria_reglas_clinicas_codigo_idx" ON "public"."auditoria_reglas_clinicas" USING "btree" ("codigo", "created_at" DESC);



CREATE UNIQUE INDEX "cajas_una_abierta_idx" ON "public"."cajas" USING "btree" ("cerrada") WHERE ("cerrada" = false);



CREATE INDEX "condiciones_consulta_consulta_idx" ON "public"."condiciones_consulta" USING "btree" ("consulta_id") WHERE ("deleted_at" IS NULL);



CREATE UNIQUE INDEX "condiciones_consulta_vigente_uk" ON "public"."condiciones_consulta" USING "btree" ("consulta_id", "condicion_id") WHERE ("deleted_at" IS NULL);



CREATE INDEX "consentimientos_plan_plan_idx" ON "public"."consentimientos_plan" USING "btree" ("plan_id", "fecha" DESC);



CREATE UNIQUE INDEX "consultas_cita_vigente_uk" ON "public"."consultas" USING "btree" ("cita_id") WHERE (("cita_id" IS NOT NULL) AND ("deleted_at" IS NULL) AND ("finalizada" IS NOT TRUE));



CREATE UNIQUE INDEX "consumibles_nombre_activo_unico_idx" ON "public"."consumibles" USING "btree" ("lower"("btrim"("nombre"))) WHERE "activo";



CREATE INDEX "consumos_consulta_consulta_idx" ON "public"."consumos_consulta" USING "btree" ("consulta_id") WHERE ("deleted_at" IS NULL);



CREATE UNIQUE INDEX "consumos_consulta_vigente_uk" ON "public"."consumos_consulta" USING "btree" ("consulta_id", "consumible_id") WHERE ("deleted_at" IS NULL);



CREATE UNIQUE INDEX "cuentas_consulta_vigente_uk" ON "public"."cuentas" USING "btree" ("consulta_id") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_afliccion_record" ON "public"."record_condicion" USING "btree" ("record_id");



CREATE INDEX "idx_auditoria_entidad" ON "public"."auditoria_log" USING "btree" ("entidad", "entidad_id");



CREATE INDEX "idx_auditoria_fecha" ON "public"."auditoria_log" USING "btree" ("fecha");



CREATE INDEX "idx_auditoria_usuario" ON "public"."auditoria_log" USING "btree" ("usuario_id");



CREATE INDEX "idx_citas_items_plan_item" ON "public"."citas_items_plan" USING "btree" ("item_plan_id");



CREATE INDEX "idx_compra_suplidor" ON "public"."consumibles_compras" USING "btree" ("suplidor_id");



CREATE INDEX "idx_consultas_paciente_id" ON "public"."consultas" USING "btree" ("paciente_id");



CREATE INDEX "idx_contra_tratamiento" ON "public"."contraindicaciones" USING "btree" ("tratamiento_id");



CREATE INDEX "idx_contraindicaciones_medicina_id" ON "public"."contraindicaciones" USING "btree" ("medicina_id");



CREATE INDEX "idx_cuotas_cuenta_vencimiento" ON "public"."cuotas" USING "btree" ("cuenta_id", "fecha_vencimiento") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_diagnosticos_aplicados_consulta_id" ON "public"."diagnosticos_aplicados" USING "btree" ("consulta_id");



CREATE INDEX "idx_diagnosticos_aplicados_diente_id" ON "public"."diagnosticos_aplicados" USING "btree" ("diente_id");



CREATE INDEX "idx_diagnosticos_aplicados_evaluacion" ON "public"."diagnosticos_aplicados" USING "btree" ("evaluacion_id") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_doctor_paciente_activo" ON "public"."doctor_paciente" USING "btree" ("paciente_id", "doctor_id") WHERE ("activo" = true);



CREATE INDEX "idx_documentos_consulta" ON "public"."documentos_clinicos" USING "btree" ("consulta_id");



CREATE INDEX "idx_evaluaciones_clinicas_paciente" ON "public"."evaluaciones_clinicas" USING "btree" ("paciente_id", "fecha" DESC) WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_items_plan_diagnostico" ON "public"."items_plan_tratamiento" USING "btree" ("diagnostico_aplicado_id") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_items_plan_diente" ON "public"."items_plan_tratamiento" USING "btree" ("diente_id") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_items_plan_estado" ON "public"."items_plan_tratamiento" USING "btree" ("estado") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_items_plan_plan" ON "public"."items_plan_tratamiento" USING "btree" ("plan_id", "orden") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_items_receta_receta_id" ON "public"."items_receta" USING "btree" ("receta_id");



CREATE INDEX "idx_pagos_cuota_id" ON "public"."pagos" USING "btree" ("cuota_id") WHERE (("cuota_id" IS NOT NULL) AND ("deleted_at" IS NULL));



CREATE INDEX "idx_planes_tratamiento_evaluacion" ON "public"."planes_tratamiento" USING "btree" ("evaluacion_id") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_planes_tratamiento_paciente" ON "public"."planes_tratamiento" USING "btree" ("paciente_id", "fecha_propuesta" DESC) WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_recetas_consulta" ON "public"."recetas" USING "btree" ("consulta_id");



CREATE INDEX "idx_recetas_consulta_id" ON "public"."recetas" USING "btree" ("consulta_id");



CREATE INDEX "idx_recetas_paciente" ON "public"."recetas" USING "btree" ("paciente_id") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_recetas_paciente_id" ON "public"."recetas" USING "btree" ("paciente_id");



CREATE INDEX "idx_suplidor_contacto_ref" ON "public"."suplidores_contactos" USING "btree" ("suplidor_id");



CREATE INDEX "idx_tratamientos_aplicados_consulta_id" ON "public"."tratamientos_aplicados" USING "btree" ("consulta_id");



CREATE INDEX "idx_tratamientos_aplicados_diente_id" ON "public"."tratamientos_aplicados" USING "btree" ("diente_id");



CREATE INDEX "idx_tratamientos_aplicados_estado" ON "public"."tratamientos_aplicados" USING "btree" ("consulta_id", "estado") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_tratamientos_aplicados_item_plan" ON "public"."tratamientos_aplicados" USING "btree" ("item_plan_id") WHERE ("deleted_at" IS NULL);



CREATE INDEX "movimientos_caja_fecha_idx" ON "public"."movimientos_caja" USING "btree" ("caja_diaria_id", "fecha" DESC) WHERE ("deleted_at" IS NULL);



CREATE INDEX "movimientos_stock_consulta_idx" ON "public"."movimientos_stock_consumible" USING "btree" ("consulta_id") WHERE ("consulta_id" IS NOT NULL);



CREATE INDEX "movimientos_stock_consumible_consumible_fecha_idx" ON "public"."movimientos_stock_consumible" USING "btree" ("consumible_id", "created_at" DESC);



CREATE UNIQUE INDEX "movimientos_stock_consumo_clinico_uk" ON "public"."movimientos_stock_consumible" USING "btree" ("consulta_id", "consumible_id") WHERE ("consulta_id" IS NOT NULL);



CREATE UNIQUE INDEX "personas_cedula_normalizada_uk" ON "public"."personas" USING "btree" ("public"."hfx_clin_004_normalizar_cedula"("cedula")) WHERE (("deleted_at" IS NULL) AND ("public"."hfx_clin_004_normalizar_cedula"("cedula") IS NOT NULL));



CREATE INDEX "reglas_clinicas_vigentes_idx" ON "public"."reglas_clinicas" USING "btree" ("categoria", "estado") WHERE ("estado" = 'aprobada'::"text");



CREATE INDEX "signos_vitales_consulta_idx" ON "public"."signos_vitales_consulta" USING "btree" ("consulta_id") WHERE ("deleted_at" IS NULL);



CREATE UNIQUE INDEX "signos_vitales_consulta_vigente_uk" ON "public"."signos_vitales_consulta" USING "btree" ("consulta_id", "codigo") WHERE ("deleted_at" IS NULL);



CREATE UNIQUE INDEX "uq_doctor_paciente_activo" ON "public"."doctor_paciente" USING "btree" ("doctor_id", "paciente_id") WHERE ("activo" = true);



CREATE UNIQUE INDEX "uq_evaluaciones_clinicas_consulta" ON "public"."evaluaciones_clinicas" USING "btree" ("consulta_id") WHERE (("consulta_id" IS NOT NULL) AND ("deleted_at" IS NULL));



CREATE OR REPLACE TRIGGER "hfx_clin_005_auditar_alerta" AFTER INSERT ON "public"."alertas_clinicas" FOR EACH ROW EXECUTE FUNCTION "public"."hfx_clin_005_auditar_alerta"();



CREATE OR REPLACE TRIGGER "hfx_clin_005_auditar_cita" AFTER INSERT OR UPDATE ON "public"."citas" FOR EACH ROW EXECUTE FUNCTION "public"."hfx_clin_005_auditar_cita"();



CREATE OR REPLACE TRIGGER "hfx_clin_005_auditar_consentimiento" AFTER INSERT ON "public"."consentimientos_plan" FOR EACH ROW EXECUTE FUNCTION "public"."hfx_clin_005_auditar_consentimiento"();



CREATE OR REPLACE TRIGGER "hfx_clin_005_auditar_consulta" AFTER UPDATE ON "public"."consultas" FOR EACH ROW EXECUTE FUNCTION "public"."hfx_clin_005_auditar_consulta"();



CREATE OR REPLACE TRIGGER "hfx_clin_005_auditar_correccion" AFTER INSERT ON "public"."auditoria_correcciones_clinicas" FOR EACH ROW EXECUTE FUNCTION "public"."hfx_clin_005_auditar_correccion"();



CREATE OR REPLACE TRIGGER "hfx_clin_005_auditar_diagnostico" AFTER INSERT OR UPDATE ON "public"."diagnosticos_aplicados" FOR EACH ROW EXECUTE FUNCTION "public"."hfx_clin_005_auditar_diagnostico"();



CREATE OR REPLACE TRIGGER "hfx_clin_005_auditar_plan" AFTER INSERT OR UPDATE ON "public"."planes_tratamiento" FOR EACH ROW EXECUTE FUNCTION "public"."hfx_clin_005_auditar_plan"();



CREATE OR REPLACE TRIGGER "hfx_clin_005_auditar_receta" AFTER INSERT OR UPDATE ON "public"."recetas" FOR EACH ROW EXECUTE FUNCTION "public"."hfx_clin_005_auditar_receta"();



CREATE OR REPLACE TRIGGER "hfx_clin_005_auditar_tratamiento" AFTER INSERT OR UPDATE ON "public"."tratamientos_aplicados" FOR EACH ROW EXECUTE FUNCTION "public"."hfx_clin_005_auditar_tratamiento"();



CREATE OR REPLACE TRIGGER "pagos_registrar_ingreso_caja" AFTER INSERT ON "public"."pagos" FOR EACH ROW EXECUTE FUNCTION "public"."registrar_pago_en_caja"();



CREATE OR REPLACE TRIGGER "tr_actualizar_stock_al_recibir" AFTER UPDATE ON "public"."compras" FOR EACH ROW EXECUTE FUNCTION "public"."actualizar_stock_por_compra"();



CREATE OR REPLACE TRIGGER "tr_bloquear_cancelacion_con_consulta_abierta" BEFORE UPDATE OF "estado" ON "public"."citas" FOR EACH ROW EXECUTE FUNCTION "public"."bloquear_cancelacion_con_consulta_abierta"();



CREATE OR REPLACE TRIGGER "tr_cita_cancelada_log" AFTER UPDATE OF "estado" ON "public"."citas" FOR EACH ROW EXECUTE FUNCTION "public"."manejar_cita_cancelada"();



CREATE OR REPLACE TRIGGER "tr_limpiar_superficie_on_diagnosis_delete" AFTER DELETE ON "public"."diagnosticos_aplicados" FOR EACH ROW EXECUTE FUNCTION "public"."limpiar_diagnosticos_superficie"();



CREATE OR REPLACE TRIGGER "tr_paciente_inactivo_cancela_citas" AFTER UPDATE OF "estatus" ON "public"."personas" FOR EACH ROW EXECUTE FUNCTION "public"."cancelar_citas_paciente_inactivo"();



CREATE OR REPLACE TRIGGER "tr_realinear_consulta_al_reprogramar_cita" AFTER UPDATE OF "fecha_hora" ON "public"."citas" FOR EACH ROW EXECUTE FUNCTION "public"."realinear_consulta_al_reprogramar_cita"();



CREATE OR REPLACE TRIGGER "tr_update_doctores_timestamp" BEFORE UPDATE ON "public"."doctores" FOR EACH ROW EXECUTE FUNCTION "public"."update_timestamp"();



CREATE OR REPLACE TRIGGER "tr_update_pacientes_timestamp" BEFORE UPDATE ON "public"."pacientes" FOR EACH ROW EXECUTE FUNCTION "public"."update_timestamp"();



CREATE OR REPLACE TRIGGER "tr_update_personas_timestamp" BEFORE UPDATE ON "public"."personas" FOR EACH ROW EXECUTE FUNCTION "public"."update_timestamp"();



CREATE OR REPLACE TRIGGER "tr_validar_doctor_persona" BEFORE INSERT OR UPDATE ON "public"."doctores" FOR EACH ROW EXECUTE FUNCTION "public"."validar_doctor_activo"();



CREATE OR REPLACE TRIGGER "tr_validar_edad_persona" BEFORE INSERT OR UPDATE ON "public"."personas" FOR EACH ROW EXECUTE FUNCTION "public"."validar_fecha_nacimiento"();



CREATE OR REPLACE TRIGGER "tr_validar_exceso_pago" BEFORE INSERT OR UPDATE OF "monto", "estado" ON "public"."pagos" FOR EACH ROW EXECUTE FUNCTION "public"."validar_monto_pago"();



CREATE OR REPLACE TRIGGER "tr_validar_limite_cuotas" BEFORE INSERT OR UPDATE ON "public"."cuotas" FOR EACH ROW EXECUTE FUNCTION "public"."validar_monto_cuotas"();



CREATE OR REPLACE TRIGGER "tr_validar_pago_caja_abierta" BEFORE INSERT ON "public"."movimientos_caja" FOR EACH ROW EXECUTE FUNCTION "public"."validar_caja_abierta"();



CREATE OR REPLACE TRIGGER "trg_aplicar_movimiento_stock" BEFORE INSERT ON "public"."movimientos_stock_consumible" FOR EACH ROW EXECUTE FUNCTION "public"."fn_aplicar_movimiento_stock"();



CREATE OR REPLACE TRIGGER "trg_auditoria_caja_diaria" AFTER INSERT OR DELETE OR UPDATE ON "public"."cajas_diarias" FOR EACH ROW EXECUTE FUNCTION "public"."fn_auditoria_log"();



CREATE OR REPLACE TRIGGER "trg_auditoria_cita" AFTER INSERT OR DELETE OR UPDATE ON "public"."citas" FOR EACH ROW EXECUTE FUNCTION "public"."fn_auditoria_log"();



CREATE OR REPLACE TRIGGER "trg_auditoria_compra" AFTER INSERT OR DELETE OR UPDATE ON "public"."compras" FOR EACH ROW EXECUTE FUNCTION "public"."fn_auditoria_log"();



CREATE OR REPLACE TRIGGER "trg_auditoria_consulta" AFTER INSERT OR DELETE OR UPDATE ON "public"."consultas" FOR EACH ROW EXECUTE FUNCTION "public"."fn_auditoria_log"();



CREATE OR REPLACE TRIGGER "trg_auditoria_cuenta" AFTER INSERT OR DELETE OR UPDATE ON "public"."cuentas" FOR EACH ROW EXECUTE FUNCTION "public"."fn_auditoria_log"();



CREATE OR REPLACE TRIGGER "trg_auditoria_pago" AFTER INSERT OR DELETE OR UPDATE ON "public"."pagos" FOR EACH ROW EXECUTE FUNCTION "public"."fn_auditoria_log"();



CREATE OR REPLACE TRIGGER "trg_autoasignar_doctor_paciente" AFTER INSERT ON "public"."consultas" FOR EACH ROW EXECUTE FUNCTION "public"."fn_autoasignar_doctor_paciente"();



CREATE OR REPLACE TRIGGER "trg_cascade_deleted_at_doctor" AFTER UPDATE OF "deleted_at" ON "public"."doctores" FOR EACH ROW EXECUTE FUNCTION "public"."fn_cascade_deleted_at_doctor"();



CREATE OR REPLACE TRIGGER "trg_cascade_deleted_at_usuario" AFTER UPDATE OF "deleted_at" ON "public"."usuarios" FOR EACH ROW EXECUTE FUNCTION "public"."fn_cascade_deleted_at_usuario"();



CREATE OR REPLACE TRIGGER "trg_citas_fin" BEFORE INSERT OR UPDATE OF "fecha_hora", "duracion_minutos" ON "public"."citas" FOR EACH ROW EXECUTE FUNCTION "public"."hfx_clin_004_calcular_fin_cita"();



CREATE OR REPLACE TRIGGER "trg_citas_transicion" BEFORE UPDATE OF "estado" ON "public"."citas" FOR EACH ROW EXECUTE FUNCTION "public"."hfx_clin_004_validar_transicion_cita"();



CREATE OR REPLACE TRIGGER "trg_coherencia_ejecucion" BEFORE INSERT OR UPDATE ON "public"."tratamientos_aplicados" FOR EACH ROW EXECUTE FUNCTION "public"."hfx_clin_003_coherencia_ejecucion"();



CREATE OR REPLACE TRIGGER "trg_exigir_consentimiento_plan" BEFORE UPDATE OF "estado" ON "public"."planes_tratamiento" FOR EACH ROW EXECUTE FUNCTION "public"."hfx_clin_003_exigir_consentimiento"();



CREATE OR REPLACE TRIGGER "trg_generar_codigo_receta" BEFORE INSERT ON "public"."recetas" FOR EACH ROW EXECUTE FUNCTION "public"."generar_codigo_receta"();



CREATE OR REPLACE TRIGGER "trg_hfx_qa_103_transicion_estado_cita" BEFORE UPDATE OF "estado" ON "public"."citas" FOR EACH ROW EXECUTE FUNCTION "public"."hfx_qa_103_transicion_estado_cita"();



CREATE OR REPLACE TRIGGER "trg_item_plan_ejecutable" BEFORE INSERT OR UPDATE OF "item_plan_id" ON "public"."tratamientos_aplicados" FOR EACH ROW EXECUTE FUNCTION "public"."verificar_item_plan_ejecutable"();



CREATE OR REPLACE TRIGGER "trg_marcar_item_plan_ejecutado" AFTER INSERT OR UPDATE OF "estado", "item_plan_id", "deleted_at" ON "public"."tratamientos_aplicados" FOR EACH ROW EXECUTE FUNCTION "public"."marcar_item_plan_ejecutado"();



CREATE OR REPLACE TRIGGER "trg_proteger_receta_emitida" BEFORE DELETE OR UPDATE ON "public"."recetas" FOR EACH ROW EXECUTE FUNCTION "public"."hfx_clin_002_proteger_receta_emitida"();



CREATE OR REPLACE TRIGGER "trg_sync_disponibilidad_doctor" AFTER INSERT OR DELETE OR UPDATE ON "public"."citas" FOR EACH ROW EXECUTE FUNCTION "public"."sync_disponibilidad_doctor"();



CREATE OR REPLACE TRIGGER "trg_validar_alcance_diagnostico" BEFORE INSERT OR UPDATE OF "diagnosis_id", "diente_id", "superficie" ON "public"."diagnosticos_aplicados" FOR EACH ROW WHEN (("new"."deleted_at" IS NULL)) EXECUTE FUNCTION "public"."hfx_clin_003_validar_alcance"();



CREATE OR REPLACE TRIGGER "trg_validar_alcance_tratamiento" BEFORE INSERT OR UPDATE OF "tratamiento_id", "diente_id", "superficie" ON "public"."tratamientos_aplicados" FOR EACH ROW WHEN (("new"."deleted_at" IS NULL)) EXECUTE FUNCTION "public"."hfx_clin_003_validar_alcance"();



CREATE OR REPLACE TRIGGER "trg_validar_cita_item_plan" BEFORE INSERT OR UPDATE ON "public"."citas_items_plan" FOR EACH ROW EXECUTE FUNCTION "public"."validar_cita_item_plan"();



CREATE OR REPLACE TRIGGER "trg_validar_signo_vital" BEFORE INSERT OR UPDATE ON "public"."signos_vitales_consulta" FOR EACH ROW EXECUTE FUNCTION "public"."hfx_clin_003_validar_signo_vital"();



CREATE OR REPLACE TRIGGER "trg_versionar_plan" AFTER INSERT OR DELETE OR UPDATE ON "public"."items_plan_tratamiento" FOR EACH ROW EXECUTE FUNCTION "public"."hfx_clin_003_versionar_plan"();



CREATE OR REPLACE TRIGGER "update_dientes_modtime" BEFORE UPDATE ON "public"."dientes" FOR EACH ROW EXECUTE FUNCTION "public"."update_modified_column"();



ALTER TABLE ONLY "public"."admins"
    ADD CONSTRAINT "admins_id_doctores_fkey" FOREIGN KEY ("id") REFERENCES "public"."doctores"("id") ON UPDATE CASCADE ON DELETE CASCADE;



COMMENT ON CONSTRAINT "admins_id_doctores_fkey" ON "public"."admins" IS 'HFX-CLIN-000: un administrador es un doctor con capacidades añadidas. Sin esta FK el login por PostgREST no puede resolver su perfil.';



ALTER TABLE ONLY "public"."alertas_clinicas"
    ADD CONSTRAINT "alertas_clinicas_consulta_id_fkey" FOREIGN KEY ("consulta_id") REFERENCES "public"."consultas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."alertas_clinicas"
    ADD CONSTRAINT "alertas_clinicas_regla_id_fkey" FOREIGN KEY ("regla_id") REFERENCES "public"."reglas_clinicas"("id");



ALTER TABLE ONLY "public"."alertas_clinicas"
    ADD CONSTRAINT "alertas_clinicas_resuelta_por_fkey" FOREIGN KEY ("resuelta_por") REFERENCES "public"."usuarios"("id");



ALTER TABLE ONLY "public"."asistentes"
    ADD CONSTRAINT "asistentes_id_fkey" FOREIGN KEY ("id") REFERENCES "public"."usuarios"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."auditoria_clinica"
    ADD CONSTRAINT "auditoria_clinica_cita_id_fkey" FOREIGN KEY ("cita_id") REFERENCES "public"."citas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."auditoria_clinica"
    ADD CONSTRAINT "auditoria_clinica_consulta_id_fkey" FOREIGN KEY ("consulta_id") REFERENCES "public"."consultas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."auditoria_correcciones_clinicas"
    ADD CONSTRAINT "auditoria_correcciones_clinicas_autor_original_id_fkey" FOREIGN KEY ("autor_original_id") REFERENCES "public"."doctores"("id");



ALTER TABLE ONLY "public"."auditoria_correcciones_clinicas"
    ADD CONSTRAINT "auditoria_correcciones_clinicas_consulta_id_fkey" FOREIGN KEY ("consulta_id") REFERENCES "public"."consultas"("id");



ALTER TABLE ONLY "public"."auditoria_correcciones_clinicas"
    ADD CONSTRAINT "auditoria_correcciones_clinicas_corregido_por_fkey" FOREIGN KEY ("corregido_por") REFERENCES "public"."admins"("id");



ALTER TABLE ONLY "public"."auditoria_log"
    ADD CONSTRAINT "auditoria_log_usuario_id_fkey" FOREIGN KEY ("usuario_id") REFERENCES "public"."usuarios"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."auditoria_operaciones_admin"
    ADD CONSTRAINT "auditoria_operaciones_admin_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "public"."admins"("id");



ALTER TABLE ONLY "public"."auditoria_reglas_clinicas"
    ADD CONSTRAINT "auditoria_reglas_clinicas_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "public"."usuarios"("id");



ALTER TABLE ONLY "public"."auditoria_reglas_clinicas"
    ADD CONSTRAINT "auditoria_reglas_clinicas_regla_id_fkey" FOREIGN KEY ("regla_id") REFERENCES "public"."reglas_clinicas"("id");



ALTER TABLE ONLY "public"."cajas_diarias"
    ADD CONSTRAINT "caja_diaria_abierta_por_fkey" FOREIGN KEY ("abierta_por") REFERENCES "public"."usuarios"("id");



ALTER TABLE ONLY "public"."cajas_diarias"
    ADD CONSTRAINT "caja_diaria_cerrada_por_fkey" FOREIGN KEY ("cerrada_por") REFERENCES "public"."usuarios"("id");



ALTER TABLE ONLY "public"."cajas"
    ADD CONSTRAINT "cajas_abierta_por_fkey" FOREIGN KEY ("abierta_por") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."cajas"
    ADD CONSTRAINT "cajas_cerrada_por_fkey" FOREIGN KEY ("cerrada_por") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."citas"
    ADD CONSTRAINT "citas_doctor_id_fkey" FOREIGN KEY ("doctor_id") REFERENCES "public"."doctores"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."citas_items_plan"
    ADD CONSTRAINT "citas_items_plan_cita_id_fkey" FOREIGN KEY ("cita_id") REFERENCES "public"."citas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."citas_items_plan"
    ADD CONSTRAINT "citas_items_plan_item_plan_id_fkey" FOREIGN KEY ("item_plan_id") REFERENCES "public"."items_plan_tratamiento"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."citas"
    ADD CONSTRAINT "citas_persona_id_fkey" FOREIGN KEY ("persona_id") REFERENCES "public"."personas"("id") ON UPDATE CASCADE;



ALTER TABLE ONLY "public"."condiciones_consulta"
    ADD CONSTRAINT "condiciones_consulta_condicion_id_fkey" FOREIGN KEY ("condicion_id") REFERENCES "public"."condiciones"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."condiciones_consulta"
    ADD CONSTRAINT "condiciones_consulta_confirmada_por_fkey" FOREIGN KEY ("confirmada_por") REFERENCES "public"."usuarios"("id");



ALTER TABLE ONLY "public"."condiciones_consulta"
    ADD CONSTRAINT "condiciones_consulta_consulta_id_fkey" FOREIGN KEY ("consulta_id") REFERENCES "public"."consultas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."consentimientos_plan"
    ADD CONSTRAINT "consentimientos_plan_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "public"."planes_tratamiento"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."consentimientos_plan"
    ADD CONSTRAINT "consentimientos_plan_registrado_por_fkey" FOREIGN KEY ("registrado_por") REFERENCES "public"."usuarios"("id");



ALTER TABLE ONLY "public"."consultas"
    ADD CONSTRAINT "consultas_cerrada_por_fkey" FOREIGN KEY ("cerrada_por") REFERENCES "public"."doctores"("id");



ALTER TABLE ONLY "public"."consultas"
    ADD CONSTRAINT "consultas_cita_id_fkey" FOREIGN KEY ("cita_id") REFERENCES "public"."citas"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."consultas"
    ADD CONSTRAINT "consultas_doctor_id_fkey" FOREIGN KEY ("doctor_id") REFERENCES "public"."doctores"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."consultas"
    ADD CONSTRAINT "consultas_paciente_id_fkey" FOREIGN KEY ("paciente_id") REFERENCES "public"."pacientes"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."consumibles_compras"
    ADD CONSTRAINT "consumible_compra_compra_id_fkey" FOREIGN KEY ("compra_id") REFERENCES "public"."compras"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."consumibles_compras"
    ADD CONSTRAINT "consumible_compra_consumible_id_fkey" FOREIGN KEY ("consumible_id") REFERENCES "public"."consumibles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."consumibles_compras"
    ADD CONSTRAINT "consumible_compra_suplidor_id_fkey" FOREIGN KEY ("suplidor_id") REFERENCES "public"."suplidores"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."consumibles"
    ADD CONSTRAINT "consumibles_suplidor_id_fkey" FOREIGN KEY ("suplidor_id") REFERENCES "public"."suplidores"("id");



ALTER TABLE ONLY "public"."consumos_consulta"
    ADD CONSTRAINT "consumos_consulta_consulta_id_fkey" FOREIGN KEY ("consulta_id") REFERENCES "public"."consultas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."consumos_consulta"
    ADD CONSTRAINT "consumos_consulta_consumible_id_fkey" FOREIGN KEY ("consumible_id") REFERENCES "public"."consumibles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."contraindicaciones"
    ADD CONSTRAINT "contraindicaciones_condicion_id_fkey" FOREIGN KEY ("condicion_id") REFERENCES "public"."condiciones"("id");



ALTER TABLE ONLY "public"."contraindicaciones"
    ADD CONSTRAINT "contraindicaciones_medicina_id_fkey" FOREIGN KEY ("medicina_id") REFERENCES "public"."medicinas"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."contraindicaciones"
    ADD CONSTRAINT "contraindicaciones_procedimiento_id_fkey" FOREIGN KEY ("procedimiento_id") REFERENCES "public"."procedimientos"("id");



ALTER TABLE ONLY "public"."contraindicaciones"
    ADD CONSTRAINT "contraindicaciones_tratamiento_id_fkey" FOREIGN KEY ("tratamiento_id") REFERENCES "public"."tratamientos"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cuentas"
    ADD CONSTRAINT "cuentas_consulta_id_fkey" FOREIGN KEY ("consulta_id") REFERENCES "public"."consultas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cuentas"
    ADD CONSTRAINT "cuentas_paciente_id_fkey" FOREIGN KEY ("paciente_id") REFERENCES "public"."personas"("id") ON UPDATE CASCADE;



ALTER TABLE ONLY "public"."cuotas"
    ADD CONSTRAINT "cuotas_cuenta_id_fkey" FOREIGN KEY ("cuenta_id") REFERENCES "public"."cuentas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."diagnosticos_aplicados"
    ADD CONSTRAINT "diagnosticos_aplicados_consulta_id_fkey" FOREIGN KEY ("consulta_id") REFERENCES "public"."consultas"("id");



ALTER TABLE ONLY "public"."diagnosticos_aplicados"
    ADD CONSTRAINT "diagnosticos_aplicados_diagnosis_id_fkey" FOREIGN KEY ("diagnosis_id") REFERENCES "public"."diagnosticos"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."diagnosticos_aplicados"
    ADD CONSTRAINT "diagnosticos_aplicados_diente_id_fkey" FOREIGN KEY ("diente_id") REFERENCES "public"."dientes"("id");



ALTER TABLE ONLY "public"."diagnosticos_aplicados"
    ADD CONSTRAINT "diagnosticos_aplicados_evaluacion_id_fkey" FOREIGN KEY ("evaluacion_id") REFERENCES "public"."evaluaciones_clinicas"("id");



ALTER TABLE ONLY "public"."dientes"
    ADD CONSTRAINT "dientes_diagnostico_principal_id_fkey" FOREIGN KEY ("diagnostico_principal_id") REFERENCES "public"."diagnosticos_aplicados"("id");



ALTER TABLE ONLY "public"."dientes"
    ADD CONSTRAINT "dientes_odontograma_id_fkey" FOREIGN KEY ("odontograma_id") REFERENCES "public"."odontogramas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."doctor_asistentes"
    ADD CONSTRAINT "doctor_asistentes_asistente_id_fkey" FOREIGN KEY ("asistente_id") REFERENCES "public"."asistentes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."doctor_asistentes"
    ADD CONSTRAINT "doctor_asistentes_doctor_id_fkey" FOREIGN KEY ("doctor_id") REFERENCES "public"."doctores"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."doctor_paciente"
    ADD CONSTRAINT "doctor_paciente_asignado_por_fkey" FOREIGN KEY ("asignado_por") REFERENCES "public"."usuarios"("id");



ALTER TABLE ONLY "public"."doctor_paciente"
    ADD CONSTRAINT "doctor_paciente_doctor_id_fkey" FOREIGN KEY ("doctor_id") REFERENCES "public"."doctores"("id");



ALTER TABLE ONLY "public"."doctor_paciente"
    ADD CONSTRAINT "doctor_paciente_paciente_id_fkey" FOREIGN KEY ("paciente_id") REFERENCES "public"."pacientes"("id");



ALTER TABLE ONLY "public"."doctores"
    ADD CONSTRAINT "doctores_id_fkey" FOREIGN KEY ("id") REFERENCES "public"."usuarios"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."documentos_clinicos"
    ADD CONSTRAINT "documentos_clinicos_consulta_id_fkey" FOREIGN KEY ("consulta_id") REFERENCES "public"."consultas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."documentos_clinicos"
    ADD CONSTRAINT "documentos_clinicos_paciente_id_fkey" FOREIGN KEY ("paciente_id") REFERENCES "public"."pacientes"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."equipos_mantenimientos"
    ADD CONSTRAINT "equipos_mantenimiento_consumible_id_fkey" FOREIGN KEY ("consumible_id") REFERENCES "public"."consumibles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."equipos_mantenimientos"
    ADD CONSTRAINT "equipos_mantenimiento_equipo_id_fkey" FOREIGN KEY ("equipo_id") REFERENCES "public"."equipos"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."equipos_mantenimientos"
    ADD CONSTRAINT "equipos_mantenimiento_suplidor_id_fkey" FOREIGN KEY ("suplidor_id") REFERENCES "public"."suplidores"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."evaluaciones_clinicas"
    ADD CONSTRAINT "evaluaciones_clinicas_consulta_id_fkey" FOREIGN KEY ("consulta_id") REFERENCES "public"."consultas"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."evaluaciones_clinicas"
    ADD CONSTRAINT "evaluaciones_clinicas_doctor_id_fkey" FOREIGN KEY ("doctor_id") REFERENCES "public"."doctores"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."evaluaciones_clinicas"
    ADD CONSTRAINT "evaluaciones_clinicas_paciente_id_fkey" FOREIGN KEY ("paciente_id") REFERENCES "public"."pacientes"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."consumibles_compras"
    ADD CONSTRAINT "fk_consumibles_compras_compra" FOREIGN KEY ("compra_id") REFERENCES "public"."compras"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."contraindicaciones"
    ADD CONSTRAINT "fk_contraindicaciones_medicina" FOREIGN KEY ("medicina_id") REFERENCES "public"."medicinas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."items_cuenta"
    ADD CONSTRAINT "item_cuentas_cuenta_id_fkey" FOREIGN KEY ("cuenta_id") REFERENCES "public"."cuentas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."items_cuenta"
    ADD CONSTRAINT "items_cuenta_tratamiento_aplicado_id_fkey" FOREIGN KEY ("tratamiento_aplicado_id") REFERENCES "public"."tratamientos_aplicados"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."items_plan_tratamiento"
    ADD CONSTRAINT "items_plan_tratamiento_diagnostico_aplicado_id_fkey" FOREIGN KEY ("diagnostico_aplicado_id") REFERENCES "public"."diagnosticos_aplicados"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."items_plan_tratamiento"
    ADD CONSTRAINT "items_plan_tratamiento_diente_id_fkey" FOREIGN KEY ("diente_id") REFERENCES "public"."dientes"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."items_plan_tratamiento"
    ADD CONSTRAINT "items_plan_tratamiento_doctor_propone_id_fkey" FOREIGN KEY ("doctor_propone_id") REFERENCES "public"."doctores"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."items_plan_tratamiento"
    ADD CONSTRAINT "items_plan_tratamiento_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "public"."planes_tratamiento"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."items_plan_tratamiento"
    ADD CONSTRAINT "items_plan_tratamiento_tratamiento_id_fkey" FOREIGN KEY ("tratamiento_id") REFERENCES "public"."tratamientos"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."items_receta"
    ADD CONSTRAINT "items_receta_receta_id_fkey" FOREIGN KEY ("receta_id") REFERENCES "public"."recetas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."movimientos_caja"
    ADD CONSTRAINT "movimientos_caja_caja_diaria_id_fkey" FOREIGN KEY ("caja_diaria_id") REFERENCES "public"."cajas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."movimientos_stock_consumible"
    ADD CONSTRAINT "movimientos_stock_consumible_consulta_id_fkey" FOREIGN KEY ("consulta_id") REFERENCES "public"."consultas"("id");



ALTER TABLE ONLY "public"."movimientos_stock_consumible"
    ADD CONSTRAINT "movimientos_stock_consumible_consumible_id_fkey" FOREIGN KEY ("consumible_id") REFERENCES "public"."consumibles"("id");



ALTER TABLE ONLY "public"."movimientos_stock_consumible"
    ADD CONSTRAINT "movimientos_stock_consumible_creado_por_fkey" FOREIGN KEY ("creado_por") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."odontogramas"
    ADD CONSTRAINT "odontogramas_consulta_id_fkey" FOREIGN KEY ("consulta_id") REFERENCES "public"."consultas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ordenes_medicas"
    ADD CONSTRAINT "ordenes_medicas_consulta_id_fkey" FOREIGN KEY ("consulta_id") REFERENCES "public"."consultas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ordenes_medicas"
    ADD CONSTRAINT "ordenes_medicas_procedimiento_id_fkey" FOREIGN KEY ("procedimiento_id") REFERENCES "public"."procedimientos"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."pacientes"
    ADD CONSTRAINT "pacientes_id_fkey" FOREIGN KEY ("id") REFERENCES "public"."personas"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pagos"
    ADD CONSTRAINT "pagos_cuenta_id_fkey" FOREIGN KEY ("cuenta_id") REFERENCES "public"."cuentas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."pagos"
    ADD CONSTRAINT "pagos_cuota_id_fkey" FOREIGN KEY ("cuota_id") REFERENCES "public"."cuotas"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."persona_contactos"
    ADD CONSTRAINT "persona_contactos_contacto_id_fkey" FOREIGN KEY ("contacto_id") REFERENCES "public"."contactos"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."persona_contactos"
    ADD CONSTRAINT "persona_contactos_persona_id_fkey" FOREIGN KEY ("persona_id") REFERENCES "public"."personas"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."planes_tratamiento"
    ADD CONSTRAINT "planes_tratamiento_consulta_origen_id_fkey" FOREIGN KEY ("consulta_origen_id") REFERENCES "public"."consultas"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."planes_tratamiento"
    ADD CONSTRAINT "planes_tratamiento_doctor_id_fkey" FOREIGN KEY ("doctor_id") REFERENCES "public"."doctores"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."planes_tratamiento"
    ADD CONSTRAINT "planes_tratamiento_evaluacion_id_fkey" FOREIGN KEY ("evaluacion_id") REFERENCES "public"."evaluaciones_clinicas"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."planes_tratamiento"
    ADD CONSTRAINT "planes_tratamiento_paciente_id_fkey" FOREIGN KEY ("paciente_id") REFERENCES "public"."pacientes"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."recetas"
    ADD CONSTRAINT "recetas_consulta_id_fkey" FOREIGN KEY ("consulta_id") REFERENCES "public"."consultas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recetas"
    ADD CONSTRAINT "recetas_doctor_id_fkey" FOREIGN KEY ("doctor_id") REFERENCES "public"."doctores"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."recetas"
    ADD CONSTRAINT "recetas_medicina_id_fkey" FOREIGN KEY ("medicina_id") REFERENCES "public"."medicinas"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."recetas"
    ADD CONSTRAINT "recetas_paciente_id_fkey" FOREIGN KEY ("paciente_id") REFERENCES "public"."personas"("id") ON UPDATE CASCADE;



ALTER TABLE ONLY "public"."recetas"
    ADD CONSTRAINT "recetas_receta_reemplazada_id_fkey" FOREIGN KEY ("receta_reemplazada_id") REFERENCES "public"."recetas"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."record_condicion"
    ADD CONSTRAINT "record_afliccion_condicion_id_fkey" FOREIGN KEY ("condicion_id") REFERENCES "public"."condiciones"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."record_condicion"
    ADD CONSTRAINT "record_afliccion_record_id_fkey" FOREIGN KEY ("record_id") REFERENCES "public"."records"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."records"
    ADD CONSTRAINT "records_paciente_id_fkey" FOREIGN KEY ("paciente_id") REFERENCES "public"."pacientes"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reglas_clinicas"
    ADD CONSTRAINT "reglas_clinicas_aprobada_por_fkey" FOREIGN KEY ("aprobada_por") REFERENCES "public"."usuarios"("id");



ALTER TABLE ONLY "public"."signos_vitales_consulta"
    ADD CONSTRAINT "signos_vitales_consulta_codigo_fkey" FOREIGN KEY ("codigo") REFERENCES "public"."catalogo_signos_vitales"("codigo");



ALTER TABLE ONLY "public"."signos_vitales_consulta"
    ADD CONSTRAINT "signos_vitales_consulta_consulta_id_fkey" FOREIGN KEY ("consulta_id") REFERENCES "public"."consultas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."signos_vitales_consulta"
    ADD CONSTRAINT "signos_vitales_consulta_medido_por_fkey" FOREIGN KEY ("medido_por") REFERENCES "public"."usuarios"("id");



ALTER TABLE ONLY "public"."superficies"
    ADD CONSTRAINT "superficies_diagnostico_aplicado_id_fkey" FOREIGN KEY ("diagnostico_aplicado_id") REFERENCES "public"."diagnosticos_aplicados"("id");



ALTER TABLE ONLY "public"."superficies"
    ADD CONSTRAINT "superficies_diente_id_fkey" FOREIGN KEY ("diente_id") REFERENCES "public"."dientes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."suplidores_contactos"
    ADD CONSTRAINT "suplidor_contacto_contacto_id_fkey" FOREIGN KEY ("contacto_id") REFERENCES "public"."contactos"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."suplidores_contactos"
    ADD CONSTRAINT "suplidor_contacto_suplidor_id_fkey" FOREIGN KEY ("suplidor_id") REFERENCES "public"."suplidores"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tratamientos_aplicados"
    ADD CONSTRAINT "tratamientos_aplicados_consulta_id_fkey" FOREIGN KEY ("consulta_id") REFERENCES "public"."consultas"("id");



ALTER TABLE ONLY "public"."tratamientos_aplicados"
    ADD CONSTRAINT "tratamientos_aplicados_diente_id_fkey" FOREIGN KEY ("diente_id") REFERENCES "public"."dientes"("id");



ALTER TABLE ONLY "public"."tratamientos_aplicados"
    ADD CONSTRAINT "tratamientos_aplicados_doctor_ejecuta_id_fkey" FOREIGN KEY ("doctor_ejecuta_id") REFERENCES "public"."doctores"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."tratamientos_aplicados"
    ADD CONSTRAINT "tratamientos_aplicados_item_plan_id_fkey" FOREIGN KEY ("item_plan_id") REFERENCES "public"."items_plan_tratamiento"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."tratamientos_aplicados"
    ADD CONSTRAINT "tratamientos_aplicados_tratamiento_id_fkey" FOREIGN KEY ("tratamiento_id") REFERENCES "public"."tratamientos"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."tratamientos_aplicados"
    ADD CONSTRAINT "tratamientos_aplicados_tratamiento_padre_id_fkey" FOREIGN KEY ("tratamiento_padre_id") REFERENCES "public"."tratamientos_aplicados"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."usuarios"
    ADD CONSTRAINT "usuarios_id_fkey" FOREIGN KEY ("id") REFERENCES "public"."personas"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE "public"."admins" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "admins_delete" ON "public"."admins" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "admins_insert" ON "public"."admins" FOR INSERT TO "authenticated" WITH CHECK ("public"."es_admin"());



CREATE POLICY "admins_select" ON "public"."admins" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR ("id" = "auth"."uid"())));



CREATE POLICY "admins_update" ON "public"."admins" FOR UPDATE TO "authenticated" USING ("public"."es_admin"()) WITH CHECK ("public"."es_admin"());



ALTER TABLE "public"."alertas_clinicas" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "alertas_clinicas_select" ON "public"."alertas_clinicas" FOR SELECT TO "authenticated" USING ("public"."puede_ver_consulta"("consulta_id"));



ALTER TABLE "public"."asistentes" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "asistentes_delete" ON "public"."asistentes" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "asistentes_insert" ON "public"."asistentes" FOR INSERT TO "authenticated" WITH CHECK ("public"."es_admin"());



CREATE POLICY "asistentes_select" ON "public"."asistentes" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "asistentes_update" ON "public"."asistentes" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR ("id" = "auth"."uid"()))) WITH CHECK (("public"."es_admin"() OR ("id" = "auth"."uid"())));



ALTER TABLE "public"."auditoria_clinica" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "auditoria_clinica_select" ON "public"."auditoria_clinica" FOR SELECT TO "authenticated" USING (((("consulta_id" IS NOT NULL) AND "public"."puede_ver_consulta"("consulta_id")) OR (("cita_id" IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM "public"."citas" "c"
  WHERE (("c"."id" = "auditoria_clinica"."cita_id") AND ("public"."es_admin"() OR "public"."es_asistente"() OR ("public"."es_doctor"() AND ("c"."doctor_id" = "auth"."uid"())))))))));



ALTER TABLE "public"."auditoria_correcciones_clinicas" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "auditoria_correcciones_select_admin" ON "public"."auditoria_correcciones_clinicas" FOR SELECT TO "authenticated" USING ("public"."es_admin"());



ALTER TABLE "public"."auditoria_log" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."auditoria_operaciones_admin" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "auditoria_operaciones_select_admin" ON "public"."auditoria_operaciones_admin" FOR SELECT TO "authenticated" USING ("public"."es_admin"());



ALTER TABLE "public"."auditoria_reglas_clinicas" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "auditoria_reglas_clinicas_select" ON "public"."auditoria_reglas_clinicas" FOR SELECT TO "authenticated" USING ("public"."es_doctor"());



CREATE POLICY "authenticated_manage_cajas" ON "public"."cajas" TO "authenticated" USING (((EXISTS ( SELECT 1
   FROM "public"."admins"
  WHERE ("admins"."id" = "auth"."uid"()))) OR (EXISTS ( SELECT 1
   FROM "public"."asistentes"
  WHERE ("asistentes"."id" = "auth"."uid"()))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM "public"."admins"
  WHERE ("admins"."id" = "auth"."uid"()))) OR (EXISTS ( SELECT 1
   FROM "public"."asistentes"
  WHERE ("asistentes"."id" = "auth"."uid"())))));



CREATE POLICY "authenticated_manage_movimientos_caja" ON "public"."movimientos_caja" TO "authenticated" USING (((EXISTS ( SELECT 1
   FROM "public"."admins"
  WHERE ("admins"."id" = "auth"."uid"()))) OR (EXISTS ( SELECT 1
   FROM "public"."asistentes"
  WHERE ("asistentes"."id" = "auth"."uid"()))))) WITH CHECK (((EXISTS ( SELECT 1
   FROM "public"."admins"
  WHERE ("admins"."id" = "auth"."uid"()))) OR (EXISTS ( SELECT 1
   FROM "public"."asistentes"
  WHERE ("asistentes"."id" = "auth"."uid"())))));



CREATE POLICY "authenticated_read_movimientos_stock_consumible" ON "public"."movimientos_stock_consumible" FOR SELECT TO "authenticated" USING (true);



ALTER TABLE "public"."cajas" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cajas_diarias" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "cajas_diarias_delete" ON "public"."cajas_diarias" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "cajas_diarias_insert" ON "public"."cajas_diarias" FOR INSERT TO "authenticated" WITH CHECK ("public"."es_admin"());



CREATE POLICY "cajas_diarias_select" ON "public"."cajas_diarias" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "cajas_diarias_update" ON "public"."cajas_diarias" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_asistente"())) WITH CHECK (("public"."es_admin"() OR "public"."es_asistente"()));



ALTER TABLE "public"."catalogo_signos_vitales" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "catalogo_signos_vitales_select" ON "public"."catalogo_signos_vitales" FOR SELECT TO "authenticated" USING (true);



ALTER TABLE "public"."citas" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "citas_delete" ON "public"."citas" FOR DELETE USING (("public"."es_admin"() OR ("public"."es_doctor"() AND ("doctor_id" = "auth"."uid"())) OR ("public"."es_asistente"() AND "public"."asiste_a_doctor"("doctor_id"))));



CREATE POLICY "citas_insert" ON "public"."citas" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_asistente"() OR ("public"."es_doctor"() AND ("doctor_id" = "auth"."uid"()))));



ALTER TABLE "public"."citas_items_plan" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "citas_items_plan_delete" ON "public"."citas_items_plan" FOR DELETE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_asistente"()));



CREATE POLICY "citas_items_plan_insert" ON "public"."citas_items_plan" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_asistente"()));



CREATE POLICY "citas_items_plan_select" ON "public"."citas_items_plan" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."citas" "c"
  WHERE (("c"."id" = "citas_items_plan"."cita_id") AND ("public"."es_admin"() OR "public"."es_asistente"() OR ("public"."es_doctor"() AND ("c"."doctor_id" = "auth"."uid"())))))));



CREATE POLICY "citas_select" ON "public"."citas" FOR SELECT USING (("public"."es_admin"() OR ("public"."es_doctor"() AND ("doctor_id" = "auth"."uid"())) OR ("public"."es_asistente"() AND "public"."asiste_a_doctor"("doctor_id"))));



CREATE POLICY "citas_update" ON "public"."citas" FOR UPDATE USING (("public"."es_admin"() OR ("public"."es_doctor"() AND ("doctor_id" = "auth"."uid"())) OR ("public"."es_asistente"() AND "public"."asiste_a_doctor"("doctor_id")))) WITH CHECK (("public"."es_admin"() OR ("public"."es_doctor"() AND ("doctor_id" = "auth"."uid"())) OR ("public"."es_asistente"() AND "public"."asiste_a_doctor"("doctor_id"))));



ALTER TABLE "public"."compras" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "compras_delete" ON "public"."compras" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "compras_insert" ON "public"."compras" FOR INSERT TO "authenticated" WITH CHECK ("public"."es_admin"());



CREATE POLICY "compras_select" ON "public"."compras" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "compras_update" ON "public"."compras" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_asistente"())) WITH CHECK (("public"."es_admin"() OR "public"."es_asistente"()));



ALTER TABLE "public"."condiciones" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."condiciones_consulta" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "condiciones_consulta_select" ON "public"."condiciones_consulta" FOR SELECT TO "authenticated" USING ("public"."puede_ver_consulta"("consulta_id"));



CREATE POLICY "condiciones_delete" ON "public"."condiciones" FOR DELETE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "condiciones_insert" ON "public"."condiciones" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "condiciones_select" ON "public"."condiciones" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "condiciones_update" ON "public"."condiciones" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"())) WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



ALTER TABLE "public"."consentimientos_plan" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "consentimientos_plan_select" ON "public"."consentimientos_plan" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "consulta_insert" ON "public"."consultas" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_doctor"() AND ("doctor_id" = "auth"."uid"())));



CREATE POLICY "consulta_select" ON "public"."consultas" FOR SELECT USING (("public"."es_admin"() OR "public"."es_doctor"()));



COMMENT ON POLICY "consulta_select" ON "public"."consultas" IS 'TEMPORAL (QA 1-ago-2026): cualquier doctor lee cualquier consulta. Revertir a (es_admin() OR doctor_id = auth.uid()) cuando se entregue el modelo definitivo de alcance clínico.';



CREATE POLICY "consulta_update" ON "public"."consultas" FOR UPDATE TO "authenticated" USING ("public"."puede_editar_consulta_propia"("id")) WITH CHECK (("doctor_id" = "auth"."uid"()));



ALTER TABLE "public"."consultas" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."consumibles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."consumibles_compras" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "consumibles_compras_delete" ON "public"."consumibles_compras" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "consumibles_compras_insert" ON "public"."consumibles_compras" FOR INSERT TO "authenticated" WITH CHECK ("public"."es_admin"());



CREATE POLICY "consumibles_compras_select" ON "public"."consumibles_compras" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "consumibles_compras_update" ON "public"."consumibles_compras" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_asistente"())) WITH CHECK (("public"."es_admin"() OR "public"."es_asistente"()));



CREATE POLICY "consumibles_delete" ON "public"."consumibles" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "consumibles_insert" ON "public"."consumibles" FOR INSERT TO "authenticated" WITH CHECK ("public"."es_admin"());



CREATE POLICY "consumibles_select" ON "public"."consumibles" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "consumibles_update" ON "public"."consumibles" FOR UPDATE USING (("public"."es_admin"() OR "public"."es_asistente"() OR "public"."es_doctor"())) WITH CHECK (("public"."es_admin"() OR "public"."es_asistente"() OR "public"."es_doctor"()));



ALTER TABLE "public"."consumos_consulta" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "consumos_consulta_select" ON "public"."consumos_consulta" FOR SELECT TO "authenticated" USING ("public"."puede_ver_consulta"("consulta_id"));



ALTER TABLE "public"."contactos" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "contactos_delete" ON "public"."contactos" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "contactos_insert" ON "public"."contactos" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "contactos_select" ON "public"."contactos" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "contactos_update" ON "public"."contactos" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"())) WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



ALTER TABLE "public"."contraindicaciones" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "contraindicaciones_delete" ON "public"."contraindicaciones" FOR DELETE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "contraindicaciones_insert" ON "public"."contraindicaciones" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "contraindicaciones_select" ON "public"."contraindicaciones" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "contraindicaciones_update" ON "public"."contraindicaciones" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"())) WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "cuenta_create" ON "public"."cuentas" FOR INSERT WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "cuenta_select" ON "public"."cuentas" FOR SELECT USING (((("paciente_id" IS NOT NULL) AND "public"."puede_ver_paciente"("paciente_id")) OR "public"."puede_ver_consulta"("consulta_id")));



CREATE POLICY "cuenta_update" ON "public"."cuentas" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



ALTER TABLE "public"."cuentas" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cuotas" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "cuotas_delete" ON "public"."cuotas" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "cuotas_insert" ON "public"."cuotas" FOR INSERT TO "authenticated" WITH CHECK ("public"."es_admin"());



CREATE POLICY "cuotas_select" ON "public"."cuotas" FOR SELECT USING ("public"."puede_ver_cuenta"("cuenta_id"));



CREATE POLICY "cuotas_update" ON "public"."cuotas" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_asistente"())) WITH CHECK (("public"."es_admin"() OR "public"."es_asistente"()));



ALTER TABLE "public"."diagnosticos" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."diagnosticos_aplicados" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "diagnosticos_aplicados_delete" ON "public"."diagnosticos_aplicados" FOR DELETE TO "authenticated" USING ("public"."puede_editar_consulta_propia"("consulta_id"));



CREATE POLICY "diagnosticos_aplicados_insert" ON "public"."diagnosticos_aplicados" FOR INSERT TO "authenticated" WITH CHECK ("public"."puede_editar_consulta_propia"("consulta_id"));



CREATE POLICY "diagnosticos_aplicados_select" ON "public"."diagnosticos_aplicados" FOR SELECT TO "authenticated" USING ("public"."puede_ver_consulta"("consulta_id"));



CREATE POLICY "diagnosticos_aplicados_update" ON "public"."diagnosticos_aplicados" FOR UPDATE TO "authenticated" USING ("public"."puede_editar_consulta_propia"("consulta_id")) WITH CHECK ("public"."puede_editar_consulta_propia"("consulta_id"));



CREATE POLICY "diagnosticos_delete" ON "public"."diagnosticos" FOR DELETE USING ("public"."es_admin"());



CREATE POLICY "diagnosticos_insert" ON "public"."diagnosticos" FOR INSERT WITH CHECK ("public"."es_admin"());



CREATE POLICY "diagnosticos_select" ON "public"."diagnosticos" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "diagnosticos_update" ON "public"."diagnosticos" FOR UPDATE USING ("public"."es_admin"()) WITH CHECK ("public"."es_admin"());



ALTER TABLE "public"."dientes" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "dientes_delete" ON "public"."dientes" FOR DELETE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "dientes_insert" ON "public"."dientes" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "dientes_select" ON "public"."dientes" FOR SELECT USING ("public"."puede_ver_odontograma"("odontograma_id"));



CREATE POLICY "dientes_update" ON "public"."dientes" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"())) WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



ALTER TABLE "public"."doctor_asistentes" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "doctor_asistentes_delete" ON "public"."doctor_asistentes" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "doctor_asistentes_insert" ON "public"."doctor_asistentes" FOR INSERT TO "authenticated" WITH CHECK ("public"."es_admin"());



CREATE POLICY "doctor_asistentes_select" ON "public"."doctor_asistentes" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR ("doctor_id" = "auth"."uid"()) OR ("asistente_id" = "auth"."uid"())));



CREATE POLICY "doctor_asistentes_update" ON "public"."doctor_asistentes" FOR UPDATE TO "authenticated" USING ("public"."es_admin"()) WITH CHECK ("public"."es_admin"());



ALTER TABLE "public"."doctor_paciente" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "doctor_paciente_delete" ON "public"."doctor_paciente" FOR DELETE USING ("public"."es_admin"());



CREATE POLICY "doctor_paciente_insert" ON "public"."doctor_paciente" FOR INSERT WITH CHECK (("public"."es_admin"() OR "public"."es_asistente"()));



CREATE POLICY "doctor_paciente_select" ON "public"."doctor_paciente" FOR SELECT USING (("public"."es_admin"() OR "public"."es_asistente"() OR ("doctor_id" = "auth"."uid"())));



CREATE POLICY "doctor_paciente_update" ON "public"."doctor_paciente" FOR UPDATE USING (("public"."es_admin"() OR "public"."es_asistente"())) WITH CHECK (("public"."es_admin"() OR "public"."es_asistente"()));



ALTER TABLE "public"."doctores" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "doctores_delete" ON "public"."doctores" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "doctores_insert" ON "public"."doctores" FOR INSERT TO "authenticated" WITH CHECK ("public"."es_admin"());



CREATE POLICY "doctores_select" ON "public"."doctores" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "doctores_update" ON "public"."doctores" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR ("id" = "auth"."uid"()))) WITH CHECK (("public"."es_admin"() OR ("id" = "auth"."uid"())));



ALTER TABLE "public"."documentos_clinicos" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "documentos_clinicos_delete" ON "public"."documentos_clinicos" FOR DELETE TO "authenticated" USING ("public"."puede_editar_consulta_propia"("consulta_id"));



CREATE POLICY "documentos_clinicos_insert" ON "public"."documentos_clinicos" FOR INSERT TO "authenticated" WITH CHECK ("public"."puede_editar_consulta_propia"("consulta_id"));



CREATE POLICY "documentos_clinicos_select" ON "public"."documentos_clinicos" FOR SELECT TO "authenticated" USING ("public"."puede_ver_consulta"("consulta_id"));



CREATE POLICY "documentos_clinicos_update" ON "public"."documentos_clinicos" FOR UPDATE TO "authenticated" USING ("public"."puede_editar_consulta_propia"("consulta_id")) WITH CHECK ("public"."puede_editar_consulta_propia"("consulta_id"));



ALTER TABLE "public"."equipos" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "equipos_delete" ON "public"."equipos" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "equipos_insert" ON "public"."equipos" FOR INSERT TO "authenticated" WITH CHECK ("public"."es_admin"());



ALTER TABLE "public"."equipos_mantenimientos" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "equipos_mantenimientos_delete" ON "public"."equipos_mantenimientos" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "equipos_mantenimientos_insert" ON "public"."equipos_mantenimientos" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_asistente"()));



CREATE POLICY "equipos_mantenimientos_select" ON "public"."equipos_mantenimientos" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "equipos_mantenimientos_update" ON "public"."equipos_mantenimientos" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_asistente"())) WITH CHECK (("public"."es_admin"() OR "public"."es_asistente"()));



CREATE POLICY "equipos_select" ON "public"."equipos" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "equipos_update" ON "public"."equipos" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_asistente"())) WITH CHECK (("public"."es_admin"() OR "public"."es_asistente"()));



ALTER TABLE "public"."evaluaciones_clinicas" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "evaluaciones_clinicas_delete" ON "public"."evaluaciones_clinicas" FOR DELETE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "evaluaciones_clinicas_insert" ON "public"."evaluaciones_clinicas" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "evaluaciones_clinicas_select" ON "public"."evaluaciones_clinicas" FOR SELECT USING ("public"."puede_ver_paciente"("paciente_id"));



CREATE POLICY "evaluaciones_clinicas_update" ON "public"."evaluaciones_clinicas" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"())) WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



ALTER TABLE "public"."items_cuenta" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "items_cuenta_delete" ON "public"."items_cuenta" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "items_cuenta_insert" ON "public"."items_cuenta" FOR INSERT TO "authenticated" WITH CHECK ("public"."es_admin"());



CREATE POLICY "items_cuenta_select" ON "public"."items_cuenta" FOR SELECT USING ("public"."puede_ver_cuenta"("cuenta_id"));



CREATE POLICY "items_cuenta_update" ON "public"."items_cuenta" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_asistente"())) WITH CHECK (("public"."es_admin"() OR "public"."es_asistente"()));



ALTER TABLE "public"."items_plan_tratamiento" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "items_plan_tratamiento_delete" ON "public"."items_plan_tratamiento" FOR DELETE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "items_plan_tratamiento_insert" ON "public"."items_plan_tratamiento" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "items_plan_tratamiento_select" ON "public"."items_plan_tratamiento" FOR SELECT USING ("public"."puede_ver_plan"("plan_id"));



CREATE POLICY "items_plan_tratamiento_update" ON "public"."items_plan_tratamiento" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"())) WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



ALTER TABLE "public"."items_receta" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."medicinas" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "medicinas_delete" ON "public"."medicinas" FOR DELETE USING ("public"."es_admin"());



CREATE POLICY "medicinas_insert" ON "public"."medicinas" FOR INSERT WITH CHECK ("public"."es_admin"());



CREATE POLICY "medicinas_select" ON "public"."medicinas" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "medicinas_update" ON "public"."medicinas" FOR UPDATE USING ("public"."es_admin"()) WITH CHECK ("public"."es_admin"());



ALTER TABLE "public"."movimientos_caja" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."movimientos_stock_consumible" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "odontograma_insert" ON "public"."odontogramas" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "odontograma_select" ON "public"."odontogramas" FOR SELECT USING ("public"."puede_ver_consulta"("consulta_id"));



CREATE POLICY "odontograma_update" ON "public"."odontogramas" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



ALTER TABLE "public"."odontogramas" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ordenes_medicas" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "ordenes_medicas_delete" ON "public"."ordenes_medicas" FOR DELETE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "ordenes_medicas_insert" ON "public"."ordenes_medicas" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "ordenes_medicas_select" ON "public"."ordenes_medicas" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "ordenes_medicas_update" ON "public"."ordenes_medicas" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"())) WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "paciente_delete" ON "public"."pacientes" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



ALTER TABLE "public"."pacientes" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "pacientes_insert" ON "public"."pacientes" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "pacientes_select" ON "public"."pacientes" FOR SELECT USING ("public"."puede_ver_paciente"("id"));



CREATE POLICY "pacientes_update" ON "public"."pacientes" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "pago_delete" ON "public"."pagos" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "pago_insert" ON "public"."pagos" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_asistente"()));



CREATE POLICY "pago_select" ON "public"."pagos" FOR SELECT USING ("public"."puede_ver_cuenta"("cuenta_id"));



CREATE POLICY "pago_update" ON "public"."pagos" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_asistente"()));



ALTER TABLE "public"."pagos" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."persona_contactos" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "persona_contactos_delete" ON "public"."persona_contactos" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "persona_contactos_insert" ON "public"."persona_contactos" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "persona_contactos_select" ON "public"."persona_contactos" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "persona_contactos_update" ON "public"."persona_contactos" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"())) WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "persona_delete" ON "public"."personas" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "persona_insert" ON "public"."personas" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "persona_select" ON "public"."personas" FOR SELECT USING ((("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()) AND ((NOT (EXISTS ( SELECT 1
   FROM "public"."pacientes" "p"
  WHERE ("p"."id" = "personas"."id")))) OR "public"."puede_ver_paciente"("id"))));



CREATE POLICY "persona_update" ON "public"."personas" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



ALTER TABLE "public"."personas" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."planes_tratamiento" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "planes_tratamiento_delete" ON "public"."planes_tratamiento" FOR DELETE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "planes_tratamiento_insert" ON "public"."planes_tratamiento" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "planes_tratamiento_select" ON "public"."planes_tratamiento" FOR SELECT USING ("public"."puede_ver_paciente"("paciente_id"));



CREATE POLICY "planes_tratamiento_update" ON "public"."planes_tratamiento" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"())) WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



ALTER TABLE "public"."procedimientos" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "procedimientos_delete" ON "public"."procedimientos" FOR DELETE USING ("public"."es_admin"());



CREATE POLICY "procedimientos_insert" ON "public"."procedimientos" FOR INSERT WITH CHECK ("public"."es_admin"());



CREATE POLICY "procedimientos_select" ON "public"."procedimientos" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "procedimientos_update" ON "public"."procedimientos" FOR UPDATE USING ("public"."es_admin"()) WITH CHECK ("public"."es_admin"());



ALTER TABLE "public"."recetas" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "recetas_delete" ON "public"."recetas" FOR DELETE TO "authenticated" USING ("public"."puede_editar_consulta_propia"("consulta_id"));



CREATE POLICY "recetas_insert" ON "public"."recetas" FOR INSERT TO "authenticated" WITH CHECK (("public"."puede_editar_consulta_propia"("consulta_id") AND (NOT ("doctor_id" IS DISTINCT FROM "auth"."uid"()))));



CREATE POLICY "recetas_select" ON "public"."recetas" FOR SELECT TO "authenticated" USING ("public"."puede_ver_consulta"("consulta_id"));



CREATE POLICY "recetas_update" ON "public"."recetas" FOR UPDATE TO "authenticated" USING ("public"."puede_editar_consulta_propia"("consulta_id")) WITH CHECK (("public"."puede_editar_consulta_propia"("consulta_id") AND (NOT ("doctor_id" IS DISTINCT FROM "auth"."uid"()))));



ALTER TABLE "public"."record_condicion" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "record_condicion_delete" ON "public"."record_condicion" FOR DELETE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "record_condicion_insert" ON "public"."record_condicion" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "record_condicion_select" ON "public"."record_condicion" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."records" "r"
  WHERE (("r"."id" = "record_condicion"."record_id") AND "public"."puede_ver_paciente"("r"."paciente_id")))));



CREATE POLICY "record_condicion_update" ON "public"."record_condicion" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"())) WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "record_delete" ON "public"."records" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "record_insert" ON "public"."records" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "record_select" ON "public"."records" FOR SELECT USING ("public"."puede_ver_paciente"("paciente_id"));



CREATE POLICY "record_update" ON "public"."records" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



ALTER TABLE "public"."records" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."reglas_clinicas" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "reglas_clinicas_select" ON "public"."reglas_clinicas" FOR SELECT TO "authenticated" USING (true);



ALTER TABLE "public"."signos_vitales_consulta" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "signos_vitales_consulta_select" ON "public"."signos_vitales_consulta" FOR SELECT TO "authenticated" USING ("public"."puede_ver_consulta"("consulta_id"));



ALTER TABLE "public"."superficies" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "superficies_delete" ON "public"."superficies" FOR DELETE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "superficies_insert" ON "public"."superficies" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "superficies_select" ON "public"."superficies" FOR SELECT USING ("public"."puede_ver_diente"("diente_id"));



CREATE POLICY "superficies_update" ON "public"."superficies" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"())) WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



ALTER TABLE "public"."suplidores" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."suplidores_contactos" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "suplidores_contactos_delete" ON "public"."suplidores_contactos" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "suplidores_contactos_insert" ON "public"."suplidores_contactos" FOR INSERT TO "authenticated" WITH CHECK ("public"."es_admin"());



CREATE POLICY "suplidores_contactos_select" ON "public"."suplidores_contactos" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "suplidores_contactos_update" ON "public"."suplidores_contactos" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_asistente"())) WITH CHECK (("public"."es_admin"() OR "public"."es_asistente"()));



CREATE POLICY "suplidores_delete" ON "public"."suplidores" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "suplidores_insert" ON "public"."suplidores" FOR INSERT TO "authenticated" WITH CHECK ("public"."es_admin"());



CREATE POLICY "suplidores_select" ON "public"."suplidores" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "suplidores_update" ON "public"."suplidores" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_asistente"())) WITH CHECK (("public"."es_admin"() OR "public"."es_asistente"()));



ALTER TABLE "public"."tratamientos" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tratamientos_aplicados" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "tratamientos_aplicados_delete" ON "public"."tratamientos_aplicados" FOR DELETE TO "authenticated" USING ("public"."puede_editar_consulta_propia"("consulta_id"));



CREATE POLICY "tratamientos_aplicados_insert" ON "public"."tratamientos_aplicados" FOR INSERT TO "authenticated" WITH CHECK (("public"."puede_editar_consulta_propia"("consulta_id") AND (NOT ("doctor_ejecuta_id" IS DISTINCT FROM "auth"."uid"()))));



CREATE POLICY "tratamientos_aplicados_select" ON "public"."tratamientos_aplicados" FOR SELECT TO "authenticated" USING ("public"."puede_ver_consulta"("consulta_id"));



CREATE POLICY "tratamientos_aplicados_update" ON "public"."tratamientos_aplicados" FOR UPDATE TO "authenticated" USING ("public"."puede_editar_consulta_propia"("consulta_id")) WITH CHECK (("public"."puede_editar_consulta_propia"("consulta_id") AND (NOT ("doctor_ejecuta_id" IS DISTINCT FROM "auth"."uid"()))));



CREATE POLICY "tratamientos_delete" ON "public"."tratamientos" FOR DELETE USING ("public"."es_admin"());



CREATE POLICY "tratamientos_insert" ON "public"."tratamientos" FOR INSERT WITH CHECK ("public"."es_admin"());



CREATE POLICY "tratamientos_select" ON "public"."tratamientos" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "tratamientos_update" ON "public"."tratamientos" FOR UPDATE USING ("public"."es_admin"()) WITH CHECK ("public"."es_admin"());



ALTER TABLE "public"."usuarios" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "usuarios_delete" ON "public"."usuarios" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "usuarios_insert" ON "public"."usuarios" FOR INSERT TO "authenticated" WITH CHECK ("public"."es_admin"());



CREATE POLICY "usuarios_select" ON "public"."usuarios" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR ("id" = "auth"."uid"())));



CREATE POLICY "usuarios_update" ON "public"."usuarios" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR ("id" = "auth"."uid"()))) WITH CHECK (("public"."es_admin"() OR ("id" = "auth"."uid"())));





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."movimientos_caja";






GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."gbtreekey16_in"("cstring") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbtreekey16_in"("cstring") TO "anon";
GRANT ALL ON FUNCTION "public"."gbtreekey16_in"("cstring") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbtreekey16_in"("cstring") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbtreekey16_out"("public"."gbtreekey16") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbtreekey16_out"("public"."gbtreekey16") TO "anon";
GRANT ALL ON FUNCTION "public"."gbtreekey16_out"("public"."gbtreekey16") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbtreekey16_out"("public"."gbtreekey16") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbtreekey2_in"("cstring") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbtreekey2_in"("cstring") TO "anon";
GRANT ALL ON FUNCTION "public"."gbtreekey2_in"("cstring") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbtreekey2_in"("cstring") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbtreekey2_out"("public"."gbtreekey2") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbtreekey2_out"("public"."gbtreekey2") TO "anon";
GRANT ALL ON FUNCTION "public"."gbtreekey2_out"("public"."gbtreekey2") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbtreekey2_out"("public"."gbtreekey2") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbtreekey32_in"("cstring") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbtreekey32_in"("cstring") TO "anon";
GRANT ALL ON FUNCTION "public"."gbtreekey32_in"("cstring") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbtreekey32_in"("cstring") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbtreekey32_out"("public"."gbtreekey32") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbtreekey32_out"("public"."gbtreekey32") TO "anon";
GRANT ALL ON FUNCTION "public"."gbtreekey32_out"("public"."gbtreekey32") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbtreekey32_out"("public"."gbtreekey32") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbtreekey4_in"("cstring") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbtreekey4_in"("cstring") TO "anon";
GRANT ALL ON FUNCTION "public"."gbtreekey4_in"("cstring") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbtreekey4_in"("cstring") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbtreekey4_out"("public"."gbtreekey4") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbtreekey4_out"("public"."gbtreekey4") TO "anon";
GRANT ALL ON FUNCTION "public"."gbtreekey4_out"("public"."gbtreekey4") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbtreekey4_out"("public"."gbtreekey4") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbtreekey8_in"("cstring") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbtreekey8_in"("cstring") TO "anon";
GRANT ALL ON FUNCTION "public"."gbtreekey8_in"("cstring") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbtreekey8_in"("cstring") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbtreekey8_out"("public"."gbtreekey8") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbtreekey8_out"("public"."gbtreekey8") TO "anon";
GRANT ALL ON FUNCTION "public"."gbtreekey8_out"("public"."gbtreekey8") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbtreekey8_out"("public"."gbtreekey8") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbtreekey_var_in"("cstring") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbtreekey_var_in"("cstring") TO "anon";
GRANT ALL ON FUNCTION "public"."gbtreekey_var_in"("cstring") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbtreekey_var_in"("cstring") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbtreekey_var_out"("public"."gbtreekey_var") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbtreekey_var_out"("public"."gbtreekey_var") TO "anon";
GRANT ALL ON FUNCTION "public"."gbtreekey_var_out"("public"."gbtreekey_var") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbtreekey_var_out"("public"."gbtreekey_var") TO "service_role";































































































































































REVOKE ALL ON FUNCTION "public"."actualizar_paciente"("p_paciente_id" "uuid", "p_version" integer, "p_payload" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."actualizar_paciente"("p_paciente_id" "uuid", "p_version" integer, "p_payload" "jsonb") TO "service_role";
GRANT ALL ON FUNCTION "public"."actualizar_paciente"("p_paciente_id" "uuid", "p_version" integer, "p_payload" "jsonb") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."actualizar_stock_por_compra"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."actualizar_stock_por_compra"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."ajustar_stock_consumible"("p_consumible_id" "uuid", "p_nuevo_stock" integer, "p_motivo" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."ajustar_stock_consumible"("p_consumible_id" "uuid", "p_nuevo_stock" integer, "p_motivo" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."ajustar_stock_consumible"("p_consumible_id" "uuid", "p_nuevo_stock" integer, "p_motivo" "text") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."asiste_a_doctor"("p_doctor_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."asiste_a_doctor"("p_doctor_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."asiste_a_doctor"("p_doctor_id" "uuid") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."bloquear_cancelacion_con_consulta_abierta"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."bloquear_cancelacion_con_consulta_abierta"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."cancelar_citas_paciente_inactivo"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."cancelar_citas_paciente_inactivo"() TO "service_role";



GRANT ALL ON FUNCTION "public"."cash_dist"("money", "money") TO "postgres";
GRANT ALL ON FUNCTION "public"."cash_dist"("money", "money") TO "anon";
GRANT ALL ON FUNCTION "public"."cash_dist"("money", "money") TO "authenticated";
GRANT ALL ON FUNCTION "public"."cash_dist"("money", "money") TO "service_role";



REVOKE ALL ON FUNCTION "public"."cerrar_consulta"("p_consulta_id" "uuid", "p_version" integer, "p_payload" "jsonb", "p_idempotencia_key" "text", "p_metodo_pago" "text", "p_nota" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."cerrar_consulta"("p_consulta_id" "uuid", "p_version" integer, "p_payload" "jsonb", "p_idempotencia_key" "text", "p_metodo_pago" "text", "p_nota" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."cerrar_consulta"("p_consulta_id" "uuid", "p_version" integer, "p_payload" "jsonb", "p_idempotencia_key" "text", "p_metodo_pago" "text", "p_nota" "text") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."corregir_consulta_ajena"("p_consulta_id" "uuid", "p_cambios" "jsonb", "p_motivo" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."corregir_consulta_ajena"("p_consulta_id" "uuid", "p_cambios" "jsonb", "p_motivo" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."corregir_consulta_ajena"("p_consulta_id" "uuid", "p_cambios" "jsonb", "p_motivo" "text") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."crear_consulta_completa"("p_paciente_id" "uuid", "p_doctor_id" "uuid", "p_cita_id" "uuid", "p_fecha" timestamp with time zone, "p_motivo_consulta" "text", "p_temp_condiciones" "jsonb", "p_dientes" "jsonb", "p_documentos" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."crear_consulta_completa"("p_paciente_id" "uuid", "p_doctor_id" "uuid", "p_cita_id" "uuid", "p_fecha" timestamp with time zone, "p_motivo_consulta" "text", "p_temp_condiciones" "jsonb", "p_dientes" "jsonb", "p_documentos" "jsonb") TO "service_role";
GRANT ALL ON FUNCTION "public"."crear_consulta_completa"("p_paciente_id" "uuid", "p_doctor_id" "uuid", "p_cita_id" "uuid", "p_fecha" timestamp with time zone, "p_motivo_consulta" "text", "p_temp_condiciones" "jsonb", "p_dientes" "jsonb", "p_documentos" "jsonb") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."crear_consulta_completa"("p_paciente_id" "uuid", "p_doctor_id" "uuid", "p_cita_id" "uuid", "p_fecha" timestamp with time zone, "p_motivo_consulta" "text", "p_temp_condiciones" "jsonb", "p_dientes" "jsonb", "p_documentos" "jsonb", "p_tipo_atencion" "public"."tipo_atencion_clinica") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."crear_consulta_completa"("p_paciente_id" "uuid", "p_doctor_id" "uuid", "p_cita_id" "uuid", "p_fecha" timestamp with time zone, "p_motivo_consulta" "text", "p_temp_condiciones" "jsonb", "p_dientes" "jsonb", "p_documentos" "jsonb", "p_tipo_atencion" "public"."tipo_atencion_clinica") TO "authenticated";
GRANT ALL ON FUNCTION "public"."crear_consulta_completa"("p_paciente_id" "uuid", "p_doctor_id" "uuid", "p_cita_id" "uuid", "p_fecha" timestamp with time zone, "p_motivo_consulta" "text", "p_temp_condiciones" "jsonb", "p_dientes" "jsonb", "p_documentos" "jsonb", "p_tipo_atencion" "public"."tipo_atencion_clinica") TO "service_role";



GRANT ALL ON FUNCTION "public"."date_dist"("date", "date") TO "postgres";
GRANT ALL ON FUNCTION "public"."date_dist"("date", "date") TO "anon";
GRANT ALL ON FUNCTION "public"."date_dist"("date", "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."date_dist"("date", "date") TO "service_role";



REVOKE ALL ON FUNCTION "public"."debe_ocultar_contacto_paciente"("p_persona_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."debe_ocultar_contacto_paciente"("p_persona_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."debe_ocultar_contacto_paciente"("p_persona_id" "uuid") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."es_admin"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."es_admin"() TO "service_role";
GRANT ALL ON FUNCTION "public"."es_admin"() TO "authenticated";



REVOKE ALL ON FUNCTION "public"."es_asistente"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."es_asistente"() TO "service_role";
GRANT ALL ON FUNCTION "public"."es_asistente"() TO "authenticated";



REVOKE ALL ON FUNCTION "public"."es_contexto_interno"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."es_contexto_interno"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."es_doctor"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."es_doctor"() TO "service_role";
GRANT ALL ON FUNCTION "public"."es_doctor"() TO "authenticated";



REVOKE ALL ON FUNCTION "public"."es_doctor_no_admin"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."es_doctor_no_admin"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."finalizar_consulta"("p_consulta_id" "uuid", "p_metodo_pago" "text", "p_nota" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."finalizar_consulta"("p_consulta_id" "uuid", "p_metodo_pago" "text", "p_nota" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."finalizar_consulta"("p_consulta_id" "uuid", "p_metodo_pago" "text", "p_nota" "text") TO "authenticated";



GRANT ALL ON FUNCTION "public"."float4_dist"(real, real) TO "postgres";
GRANT ALL ON FUNCTION "public"."float4_dist"(real, real) TO "anon";
GRANT ALL ON FUNCTION "public"."float4_dist"(real, real) TO "authenticated";
GRANT ALL ON FUNCTION "public"."float4_dist"(real, real) TO "service_role";



GRANT ALL ON FUNCTION "public"."float8_dist"(double precision, double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."float8_dist"(double precision, double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."float8_dist"(double precision, double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."float8_dist"(double precision, double precision) TO "service_role";



REVOKE ALL ON FUNCTION "public"."fn_aplicar_movimiento_stock"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."fn_aplicar_movimiento_stock"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."fn_auditoria_log"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."fn_auditoria_log"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."fn_autoasignar_doctor_paciente"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."fn_autoasignar_doctor_paciente"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."fn_cascade_deleted_at_doctor"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."fn_cascade_deleted_at_doctor"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."fn_cascade_deleted_at_usuario"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."fn_cascade_deleted_at_usuario"() TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_bit_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_bit_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_bit_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_bit_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_bit_consistent"("internal", bit, smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_bit_consistent"("internal", bit, smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_bit_consistent"("internal", bit, smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_bit_consistent"("internal", bit, smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_bit_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_bit_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_bit_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_bit_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_bit_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_bit_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_bit_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_bit_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_bit_same"("public"."gbtreekey_var", "public"."gbtreekey_var", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_bit_same"("public"."gbtreekey_var", "public"."gbtreekey_var", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_bit_same"("public"."gbtreekey_var", "public"."gbtreekey_var", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_bit_same"("public"."gbtreekey_var", "public"."gbtreekey_var", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_bit_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_bit_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_bit_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_bit_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_bool_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_bool_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_bool_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_bool_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_bool_consistent"("internal", boolean, smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_bool_consistent"("internal", boolean, smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_bool_consistent"("internal", boolean, smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_bool_consistent"("internal", boolean, smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_bool_fetch"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_bool_fetch"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_bool_fetch"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_bool_fetch"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_bool_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_bool_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_bool_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_bool_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_bool_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_bool_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_bool_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_bool_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_bool_same"("public"."gbtreekey2", "public"."gbtreekey2", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_bool_same"("public"."gbtreekey2", "public"."gbtreekey2", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_bool_same"("public"."gbtreekey2", "public"."gbtreekey2", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_bool_same"("public"."gbtreekey2", "public"."gbtreekey2", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_bool_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_bool_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_bool_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_bool_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_bpchar_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_bpchar_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_bpchar_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_bpchar_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_bpchar_consistent"("internal", character, smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_bpchar_consistent"("internal", character, smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_bpchar_consistent"("internal", character, smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_bpchar_consistent"("internal", character, smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_bytea_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_bytea_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_bytea_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_bytea_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_bytea_consistent"("internal", "bytea", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_bytea_consistent"("internal", "bytea", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_bytea_consistent"("internal", "bytea", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_bytea_consistent"("internal", "bytea", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_bytea_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_bytea_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_bytea_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_bytea_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_bytea_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_bytea_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_bytea_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_bytea_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_bytea_same"("public"."gbtreekey_var", "public"."gbtreekey_var", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_bytea_same"("public"."gbtreekey_var", "public"."gbtreekey_var", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_bytea_same"("public"."gbtreekey_var", "public"."gbtreekey_var", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_bytea_same"("public"."gbtreekey_var", "public"."gbtreekey_var", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_bytea_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_bytea_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_bytea_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_bytea_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_cash_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_cash_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_cash_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_cash_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_cash_consistent"("internal", "money", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_cash_consistent"("internal", "money", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_cash_consistent"("internal", "money", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_cash_consistent"("internal", "money", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_cash_distance"("internal", "money", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_cash_distance"("internal", "money", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_cash_distance"("internal", "money", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_cash_distance"("internal", "money", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_cash_fetch"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_cash_fetch"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_cash_fetch"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_cash_fetch"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_cash_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_cash_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_cash_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_cash_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_cash_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_cash_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_cash_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_cash_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_cash_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_cash_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_cash_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_cash_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_cash_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_cash_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_cash_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_cash_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_date_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_date_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_date_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_date_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_date_consistent"("internal", "date", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_date_consistent"("internal", "date", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_date_consistent"("internal", "date", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_date_consistent"("internal", "date", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_date_distance"("internal", "date", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_date_distance"("internal", "date", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_date_distance"("internal", "date", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_date_distance"("internal", "date", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_date_fetch"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_date_fetch"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_date_fetch"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_date_fetch"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_date_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_date_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_date_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_date_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_date_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_date_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_date_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_date_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_date_same"("public"."gbtreekey8", "public"."gbtreekey8", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_date_same"("public"."gbtreekey8", "public"."gbtreekey8", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_date_same"("public"."gbtreekey8", "public"."gbtreekey8", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_date_same"("public"."gbtreekey8", "public"."gbtreekey8", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_date_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_date_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_date_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_date_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_decompress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_decompress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_decompress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_decompress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_enum_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_enum_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_enum_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_enum_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_enum_consistent"("internal", "anyenum", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_enum_consistent"("internal", "anyenum", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_enum_consistent"("internal", "anyenum", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_enum_consistent"("internal", "anyenum", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_enum_fetch"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_enum_fetch"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_enum_fetch"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_enum_fetch"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_enum_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_enum_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_enum_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_enum_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_enum_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_enum_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_enum_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_enum_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_enum_same"("public"."gbtreekey8", "public"."gbtreekey8", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_enum_same"("public"."gbtreekey8", "public"."gbtreekey8", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_enum_same"("public"."gbtreekey8", "public"."gbtreekey8", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_enum_same"("public"."gbtreekey8", "public"."gbtreekey8", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_enum_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_enum_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_enum_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_enum_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_float4_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_float4_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_float4_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_float4_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_float4_consistent"("internal", real, smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_float4_consistent"("internal", real, smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_float4_consistent"("internal", real, smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_float4_consistent"("internal", real, smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_float4_distance"("internal", real, smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_float4_distance"("internal", real, smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_float4_distance"("internal", real, smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_float4_distance"("internal", real, smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_float4_fetch"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_float4_fetch"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_float4_fetch"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_float4_fetch"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_float4_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_float4_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_float4_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_float4_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_float4_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_float4_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_float4_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_float4_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_float4_same"("public"."gbtreekey8", "public"."gbtreekey8", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_float4_same"("public"."gbtreekey8", "public"."gbtreekey8", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_float4_same"("public"."gbtreekey8", "public"."gbtreekey8", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_float4_same"("public"."gbtreekey8", "public"."gbtreekey8", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_float4_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_float4_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_float4_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_float4_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_float8_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_float8_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_float8_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_float8_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_float8_consistent"("internal", double precision, smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_float8_consistent"("internal", double precision, smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_float8_consistent"("internal", double precision, smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_float8_consistent"("internal", double precision, smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_float8_distance"("internal", double precision, smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_float8_distance"("internal", double precision, smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_float8_distance"("internal", double precision, smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_float8_distance"("internal", double precision, smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_float8_fetch"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_float8_fetch"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_float8_fetch"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_float8_fetch"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_float8_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_float8_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_float8_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_float8_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_float8_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_float8_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_float8_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_float8_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_float8_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_float8_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_float8_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_float8_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_float8_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_float8_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_float8_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_float8_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_inet_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_inet_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_inet_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_inet_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_inet_consistent"("internal", "inet", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_inet_consistent"("internal", "inet", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_inet_consistent"("internal", "inet", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_inet_consistent"("internal", "inet", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_inet_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_inet_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_inet_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_inet_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_inet_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_inet_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_inet_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_inet_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_inet_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_inet_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_inet_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_inet_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_inet_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_inet_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_inet_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_inet_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_int2_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_int2_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_int2_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_int2_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_int2_consistent"("internal", smallint, smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_int2_consistent"("internal", smallint, smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_int2_consistent"("internal", smallint, smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_int2_consistent"("internal", smallint, smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_int2_distance"("internal", smallint, smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_int2_distance"("internal", smallint, smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_int2_distance"("internal", smallint, smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_int2_distance"("internal", smallint, smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_int2_fetch"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_int2_fetch"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_int2_fetch"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_int2_fetch"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_int2_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_int2_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_int2_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_int2_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_int2_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_int2_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_int2_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_int2_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_int2_same"("public"."gbtreekey4", "public"."gbtreekey4", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_int2_same"("public"."gbtreekey4", "public"."gbtreekey4", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_int2_same"("public"."gbtreekey4", "public"."gbtreekey4", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_int2_same"("public"."gbtreekey4", "public"."gbtreekey4", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_int2_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_int2_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_int2_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_int2_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_int4_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_int4_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_int4_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_int4_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_int4_consistent"("internal", integer, smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_int4_consistent"("internal", integer, smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_int4_consistent"("internal", integer, smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_int4_consistent"("internal", integer, smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_int4_distance"("internal", integer, smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_int4_distance"("internal", integer, smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_int4_distance"("internal", integer, smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_int4_distance"("internal", integer, smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_int4_fetch"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_int4_fetch"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_int4_fetch"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_int4_fetch"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_int4_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_int4_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_int4_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_int4_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_int4_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_int4_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_int4_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_int4_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_int4_same"("public"."gbtreekey8", "public"."gbtreekey8", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_int4_same"("public"."gbtreekey8", "public"."gbtreekey8", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_int4_same"("public"."gbtreekey8", "public"."gbtreekey8", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_int4_same"("public"."gbtreekey8", "public"."gbtreekey8", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_int4_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_int4_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_int4_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_int4_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_int8_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_int8_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_int8_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_int8_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_int8_consistent"("internal", bigint, smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_int8_consistent"("internal", bigint, smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_int8_consistent"("internal", bigint, smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_int8_consistent"("internal", bigint, smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_int8_distance"("internal", bigint, smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_int8_distance"("internal", bigint, smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_int8_distance"("internal", bigint, smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_int8_distance"("internal", bigint, smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_int8_fetch"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_int8_fetch"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_int8_fetch"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_int8_fetch"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_int8_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_int8_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_int8_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_int8_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_int8_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_int8_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_int8_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_int8_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_int8_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_int8_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_int8_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_int8_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_int8_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_int8_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_int8_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_int8_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_intv_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_intv_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_intv_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_intv_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_intv_consistent"("internal", interval, smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_intv_consistent"("internal", interval, smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_intv_consistent"("internal", interval, smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_intv_consistent"("internal", interval, smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_intv_decompress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_intv_decompress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_intv_decompress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_intv_decompress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_intv_distance"("internal", interval, smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_intv_distance"("internal", interval, smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_intv_distance"("internal", interval, smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_intv_distance"("internal", interval, smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_intv_fetch"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_intv_fetch"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_intv_fetch"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_intv_fetch"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_intv_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_intv_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_intv_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_intv_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_intv_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_intv_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_intv_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_intv_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_intv_same"("public"."gbtreekey32", "public"."gbtreekey32", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_intv_same"("public"."gbtreekey32", "public"."gbtreekey32", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_intv_same"("public"."gbtreekey32", "public"."gbtreekey32", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_intv_same"("public"."gbtreekey32", "public"."gbtreekey32", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_intv_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_intv_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_intv_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_intv_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_macad8_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_macad8_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_macad8_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_macad8_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_macad8_consistent"("internal", "macaddr8", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_macad8_consistent"("internal", "macaddr8", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_macad8_consistent"("internal", "macaddr8", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_macad8_consistent"("internal", "macaddr8", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_macad8_fetch"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_macad8_fetch"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_macad8_fetch"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_macad8_fetch"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_macad8_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_macad8_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_macad8_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_macad8_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_macad8_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_macad8_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_macad8_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_macad8_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_macad8_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_macad8_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_macad8_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_macad8_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_macad8_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_macad8_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_macad8_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_macad8_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_macad_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_macad_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_macad_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_macad_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_macad_consistent"("internal", "macaddr", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_macad_consistent"("internal", "macaddr", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_macad_consistent"("internal", "macaddr", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_macad_consistent"("internal", "macaddr", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_macad_fetch"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_macad_fetch"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_macad_fetch"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_macad_fetch"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_macad_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_macad_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_macad_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_macad_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_macad_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_macad_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_macad_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_macad_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_macad_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_macad_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_macad_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_macad_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_macad_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_macad_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_macad_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_macad_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_numeric_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_numeric_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_numeric_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_numeric_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_numeric_consistent"("internal", numeric, smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_numeric_consistent"("internal", numeric, smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_numeric_consistent"("internal", numeric, smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_numeric_consistent"("internal", numeric, smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_numeric_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_numeric_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_numeric_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_numeric_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_numeric_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_numeric_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_numeric_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_numeric_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_numeric_same"("public"."gbtreekey_var", "public"."gbtreekey_var", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_numeric_same"("public"."gbtreekey_var", "public"."gbtreekey_var", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_numeric_same"("public"."gbtreekey_var", "public"."gbtreekey_var", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_numeric_same"("public"."gbtreekey_var", "public"."gbtreekey_var", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_numeric_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_numeric_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_numeric_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_numeric_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_oid_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_oid_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_oid_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_oid_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_oid_consistent"("internal", "oid", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_oid_consistent"("internal", "oid", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_oid_consistent"("internal", "oid", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_oid_consistent"("internal", "oid", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_oid_distance"("internal", "oid", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_oid_distance"("internal", "oid", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_oid_distance"("internal", "oid", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_oid_distance"("internal", "oid", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_oid_fetch"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_oid_fetch"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_oid_fetch"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_oid_fetch"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_oid_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_oid_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_oid_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_oid_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_oid_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_oid_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_oid_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_oid_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_oid_same"("public"."gbtreekey8", "public"."gbtreekey8", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_oid_same"("public"."gbtreekey8", "public"."gbtreekey8", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_oid_same"("public"."gbtreekey8", "public"."gbtreekey8", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_oid_same"("public"."gbtreekey8", "public"."gbtreekey8", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_oid_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_oid_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_oid_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_oid_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_text_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_text_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_text_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_text_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_text_consistent"("internal", "text", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_text_consistent"("internal", "text", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_text_consistent"("internal", "text", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_text_consistent"("internal", "text", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_text_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_text_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_text_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_text_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_text_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_text_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_text_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_text_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_text_same"("public"."gbtreekey_var", "public"."gbtreekey_var", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_text_same"("public"."gbtreekey_var", "public"."gbtreekey_var", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_text_same"("public"."gbtreekey_var", "public"."gbtreekey_var", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_text_same"("public"."gbtreekey_var", "public"."gbtreekey_var", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_text_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_text_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_text_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_text_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_time_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_time_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_time_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_time_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_time_consistent"("internal", time without time zone, smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_time_consistent"("internal", time without time zone, smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_time_consistent"("internal", time without time zone, smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_time_consistent"("internal", time without time zone, smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_time_distance"("internal", time without time zone, smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_time_distance"("internal", time without time zone, smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_time_distance"("internal", time without time zone, smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_time_distance"("internal", time without time zone, smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_time_fetch"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_time_fetch"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_time_fetch"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_time_fetch"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_time_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_time_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_time_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_time_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_time_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_time_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_time_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_time_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_time_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_time_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_time_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_time_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_time_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_time_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_time_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_time_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_timetz_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_timetz_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_timetz_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_timetz_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_timetz_consistent"("internal", time with time zone, smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_timetz_consistent"("internal", time with time zone, smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_timetz_consistent"("internal", time with time zone, smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_timetz_consistent"("internal", time with time zone, smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_ts_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_ts_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_ts_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_ts_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_ts_consistent"("internal", timestamp without time zone, smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_ts_consistent"("internal", timestamp without time zone, smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_ts_consistent"("internal", timestamp without time zone, smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_ts_consistent"("internal", timestamp without time zone, smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_ts_distance"("internal", timestamp without time zone, smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_ts_distance"("internal", timestamp without time zone, smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_ts_distance"("internal", timestamp without time zone, smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_ts_distance"("internal", timestamp without time zone, smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_ts_fetch"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_ts_fetch"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_ts_fetch"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_ts_fetch"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_ts_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_ts_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_ts_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_ts_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_ts_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_ts_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_ts_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_ts_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_ts_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_ts_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_ts_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_ts_same"("public"."gbtreekey16", "public"."gbtreekey16", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_ts_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_ts_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_ts_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_ts_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_tstz_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_tstz_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_tstz_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_tstz_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_tstz_consistent"("internal", timestamp with time zone, smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_tstz_consistent"("internal", timestamp with time zone, smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_tstz_consistent"("internal", timestamp with time zone, smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_tstz_consistent"("internal", timestamp with time zone, smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_tstz_distance"("internal", timestamp with time zone, smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_tstz_distance"("internal", timestamp with time zone, smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_tstz_distance"("internal", timestamp with time zone, smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_tstz_distance"("internal", timestamp with time zone, smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_uuid_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_uuid_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_uuid_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_uuid_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_uuid_consistent"("internal", "uuid", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_uuid_consistent"("internal", "uuid", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_uuid_consistent"("internal", "uuid", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_uuid_consistent"("internal", "uuid", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_uuid_fetch"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_uuid_fetch"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_uuid_fetch"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_uuid_fetch"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_uuid_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_uuid_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_uuid_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_uuid_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_uuid_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_uuid_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_uuid_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_uuid_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_uuid_same"("public"."gbtreekey32", "public"."gbtreekey32", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_uuid_same"("public"."gbtreekey32", "public"."gbtreekey32", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_uuid_same"("public"."gbtreekey32", "public"."gbtreekey32", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_uuid_same"("public"."gbtreekey32", "public"."gbtreekey32", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_uuid_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_uuid_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_uuid_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_uuid_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_var_decompress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_var_decompress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_var_decompress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_var_decompress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gbt_var_fetch"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gbt_var_fetch"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gbt_var_fetch"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gbt_var_fetch"("internal") TO "service_role";



REVOKE ALL ON FUNCTION "public"."generar_codigo_receta"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."generar_codigo_receta"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."generar_plan_cuotas"("p_cuenta_id" "uuid", "p_cuotas" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."generar_plan_cuotas"("p_cuenta_id" "uuid", "p_cuotas" "jsonb") TO "service_role";
GRANT ALL ON FUNCTION "public"."generar_plan_cuotas"("p_cuenta_id" "uuid", "p_cuotas" "jsonb") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."get_active_doctors"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_active_doctors"() TO "service_role";
GRANT ALL ON FUNCTION "public"."get_active_doctors"() TO "authenticated";



REVOKE ALL ON FUNCTION "public"."guardar_borrador_consulta"("p_consulta_id" "uuid", "p_version" integer, "p_payload" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."guardar_borrador_consulta"("p_consulta_id" "uuid", "p_version" integer, "p_payload" "jsonb") TO "service_role";
GRANT ALL ON FUNCTION "public"."guardar_borrador_consulta"("p_consulta_id" "uuid", "p_version" integer, "p_payload" "jsonb") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."handle_new_user"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_base_ajustar_stock_consumible"("p_consumible_id" "uuid", "p_nuevo_stock" integer, "p_motivo" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_base_ajustar_stock_consumible"("p_consumible_id" "uuid", "p_nuevo_stock" integer, "p_motivo" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_base_crear_consulta_completa"("p_paciente_id" "uuid", "p_doctor_id" "uuid", "p_cita_id" "uuid", "p_fecha" timestamp with time zone, "p_motivo_consulta" "text", "p_temp_condiciones" "jsonb", "p_dientes" "jsonb", "p_documentos" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_base_crear_consulta_completa"("p_paciente_id" "uuid", "p_doctor_id" "uuid", "p_cita_id" "uuid", "p_fecha" timestamp with time zone, "p_motivo_consulta" "text", "p_temp_condiciones" "jsonb", "p_dientes" "jsonb", "p_documentos" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_base_finalizar_consulta"("p_consulta_id" "uuid", "p_metodo_pago" "text", "p_nota" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_base_finalizar_consulta"("p_consulta_id" "uuid", "p_metodo_pago" "text", "p_nota" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_base_generar_plan_cuotas"("p_cuenta_id" "uuid", "p_cuotas" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_base_generar_plan_cuotas"("p_cuenta_id" "uuid", "p_cuotas" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_base_marcar_cuotas_vencidas"("p_cuenta_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_base_marcar_cuotas_vencidas"("p_cuenta_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_base_recibir_compra"("p_compra_id" "uuid", "p_usuario_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_base_recibir_compra"("p_compra_id" "uuid", "p_usuario_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_base_registrar_mantenimiento_equipo"("p_equipo_id" "uuid", "p_suplidor_id" "uuid", "p_costo" numeric, "p_fecha_mantenimiento" timestamp with time zone, "p_descripcion" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_base_registrar_mantenimiento_equipo"("p_equipo_id" "uuid", "p_suplidor_id" "uuid", "p_costo" numeric, "p_fecha_mantenimiento" timestamp with time zone, "p_descripcion" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_base_registrar_pago"("p_cuenta_id" "uuid", "p_monto" numeric, "p_metodo_pago" "text", "p_cuota_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_base_registrar_pago"("p_cuenta_id" "uuid", "p_monto" numeric, "p_metodo_pago" "text", "p_cuota_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_clin_002_actor_clinico"("p_consulta_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_clin_002_actor_clinico"("p_consulta_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_clin_002_aplicar_borrador"("p_consulta_id" "uuid", "p_actor_id" "uuid", "p_payload" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_clin_002_aplicar_borrador"("p_consulta_id" "uuid", "p_actor_id" "uuid", "p_payload" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_clin_002_proteger_receta_emitida"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_clin_002_proteger_receta_emitida"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_clin_002_resultado_cierre"("p_consulta_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_clin_002_resultado_cierre"("p_consulta_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_clin_003_aplicar_extras"("p_consulta_id" "uuid", "p_actor_id" "uuid", "p_payload" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_clin_003_aplicar_extras"("p_consulta_id" "uuid", "p_actor_id" "uuid", "p_payload" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_clin_003_barreras_de_cierre"("p_consulta_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_clin_003_barreras_de_cierre"("p_consulta_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_clin_003_coherencia_ejecucion"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_clin_003_coherencia_ejecucion"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_clin_003_conflictos_receta"("p_consulta_id" "uuid", "p_items" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_clin_003_conflictos_receta"("p_consulta_id" "uuid", "p_items" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_clin_003_edad_paciente"("p_paciente_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_clin_003_edad_paciente"("p_paciente_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_clin_003_evaluar_alertas"("p_consulta_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_clin_003_evaluar_alertas"("p_consulta_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_clin_003_exigir_consentimiento"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_clin_003_exigir_consentimiento"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_clin_003_incorporar_condiciones"("p_consulta_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_clin_003_incorporar_condiciones"("p_consulta_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_clin_003_regla_aplica_edad"("p_parametros" "jsonb", "p_edad" numeric) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_clin_003_regla_aplica_edad"("p_parametros" "jsonb", "p_edad" numeric) TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_clin_003_validar_alcance"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_clin_003_validar_alcance"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_clin_003_validar_receta"("p_consulta_id" "uuid", "p_items" "jsonb", "p_estricto" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_clin_003_validar_receta"("p_consulta_id" "uuid", "p_items" "jsonb", "p_estricto" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_clin_003_validar_signo_vital"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_clin_003_validar_signo_vital"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_clin_003_versionar_plan"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_clin_003_versionar_plan"() TO "service_role";



GRANT ALL ON FUNCTION "public"."hfx_clin_004_calcular_fin_cita"() TO "service_role";



GRANT ALL ON FUNCTION "public"."hfx_clin_004_estado_cita_canonico"("p_estado" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."hfx_clin_004_estado_cita_canonico"("p_estado" "text") TO "authenticated";



GRANT ALL ON FUNCTION "public"."hfx_clin_004_normalizar_cedula"("p_cedula" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."hfx_clin_004_normalizar_cedula"("p_cedula" "text") TO "authenticated";



GRANT ALL ON FUNCTION "public"."hfx_clin_004_normalizar_email"("p_email" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."hfx_clin_004_normalizar_email"("p_email" "text") TO "authenticated";



GRANT ALL ON FUNCTION "public"."hfx_clin_004_normalizar_telefono"("p_telefono" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."hfx_clin_004_normalizar_telefono"("p_telefono" "text") TO "authenticated";



GRANT ALL ON FUNCTION "public"."hfx_clin_004_sincronizar_contactos"("p_persona_id" "uuid", "p_contactos" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."hfx_clin_004_validar_transicion_cita"() TO "service_role";



GRANT ALL ON FUNCTION "public"."hfx_clin_005_auditar_alerta"() TO "service_role";



GRANT ALL ON FUNCTION "public"."hfx_clin_005_auditar_cita"() TO "service_role";



GRANT ALL ON FUNCTION "public"."hfx_clin_005_auditar_consentimiento"() TO "service_role";



GRANT ALL ON FUNCTION "public"."hfx_clin_005_auditar_consulta"() TO "service_role";



GRANT ALL ON FUNCTION "public"."hfx_clin_005_auditar_correccion"() TO "service_role";



GRANT ALL ON FUNCTION "public"."hfx_clin_005_auditar_diagnostico"() TO "service_role";



GRANT ALL ON FUNCTION "public"."hfx_clin_005_auditar_plan"() TO "service_role";



GRANT ALL ON FUNCTION "public"."hfx_clin_005_auditar_receta"() TO "service_role";



GRANT ALL ON FUNCTION "public"."hfx_clin_005_auditar_tratamiento"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_clin_005_registrar_evento"("p_evento" "text", "p_consulta_id" "uuid", "p_cita_id" "uuid", "p_metadata" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_clin_005_registrar_evento"("p_evento" "text", "p_consulta_id" "uuid", "p_cita_id" "uuid", "p_metadata" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."hfx_clin_006_validar_parametros_regla"("p_tipo" "text", "p_parametros" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."hfx_clin_006_validar_signos_de_regla"("p_tipo" "text", "p_parametros" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_clin_008_completar_odontograma"("p_odontograma_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_clin_008_completar_odontograma"("p_odontograma_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."hfx_clin_008_denticion_fdi"() TO "service_role";



GRANT ALL ON FUNCTION "public"."hfx_clin_008_superficies_de"("p_fdi" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."hfx_qa_103_transicion_estado_cita"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."hfx_qa_108_normalizar_alcance_historico"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."hfx_qa_108_normalizar_alcance_historico"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."iniciar_consulta_de_cita"("p_cita_id" "uuid", "p_dientes" "jsonb", "p_documentos" "jsonb", "p_temp_condiciones" "jsonb", "p_motivo_consulta" "text", "p_tipo_atencion" "public"."tipo_atencion_clinica") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."iniciar_consulta_de_cita"("p_cita_id" "uuid", "p_dientes" "jsonb", "p_documentos" "jsonb", "p_temp_condiciones" "jsonb", "p_motivo_consulta" "text", "p_tipo_atencion" "public"."tipo_atencion_clinica") TO "service_role";
GRANT ALL ON FUNCTION "public"."iniciar_consulta_de_cita"("p_cita_id" "uuid", "p_dientes" "jsonb", "p_documentos" "jsonb", "p_temp_condiciones" "jsonb", "p_motivo_consulta" "text", "p_tipo_atencion" "public"."tipo_atencion_clinica") TO "authenticated";



GRANT ALL ON FUNCTION "public"."int2_dist"(smallint, smallint) TO "postgres";
GRANT ALL ON FUNCTION "public"."int2_dist"(smallint, smallint) TO "anon";
GRANT ALL ON FUNCTION "public"."int2_dist"(smallint, smallint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."int2_dist"(smallint, smallint) TO "service_role";



GRANT ALL ON FUNCTION "public"."int4_dist"(integer, integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."int4_dist"(integer, integer) TO "anon";
GRANT ALL ON FUNCTION "public"."int4_dist"(integer, integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."int4_dist"(integer, integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."int8_dist"(bigint, bigint) TO "postgres";
GRANT ALL ON FUNCTION "public"."int8_dist"(bigint, bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."int8_dist"(bigint, bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."int8_dist"(bigint, bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."interval_dist"(interval, interval) TO "postgres";
GRANT ALL ON FUNCTION "public"."interval_dist"(interval, interval) TO "anon";
GRANT ALL ON FUNCTION "public"."interval_dist"(interval, interval) TO "authenticated";
GRANT ALL ON FUNCTION "public"."interval_dist"(interval, interval) TO "service_role";



REVOKE ALL ON FUNCTION "public"."limpiar_diagnosticos_superficie"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."limpiar_diagnosticos_superficie"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."linea_tiempo_consulta"("p_consulta_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."linea_tiempo_consulta"("p_consulta_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."linea_tiempo_consulta"("p_consulta_id" "uuid") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."manejar_cita_cancelada"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."manejar_cita_cancelada"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."marcar_cuotas_vencidas"("p_cuenta_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."marcar_cuotas_vencidas"("p_cuenta_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."marcar_cuotas_vencidas"("p_cuenta_id" "uuid") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."marcar_item_plan_ejecutado"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."marcar_item_plan_ejecutado"() TO "service_role";



GRANT ALL ON FUNCTION "public"."oid_dist"("oid", "oid") TO "postgres";
GRANT ALL ON FUNCTION "public"."oid_dist"("oid", "oid") TO "anon";
GRANT ALL ON FUNCTION "public"."oid_dist"("oid", "oid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."oid_dist"("oid", "oid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."perfil_actual"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."perfil_actual"() TO "service_role";
GRANT ALL ON FUNCTION "public"."perfil_actual"() TO "authenticated";



REVOKE ALL ON FUNCTION "public"."publicar_regla_clinica"("p_codigo" "text", "p_parametros" "jsonb", "p_severidad" "text", "p_accion" "text", "p_nota" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."publicar_regla_clinica"("p_codigo" "text", "p_parametros" "jsonb", "p_severidad" "text", "p_accion" "text", "p_nota" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."publicar_regla_clinica"("p_codigo" "text", "p_parametros" "jsonb", "p_severidad" "text", "p_accion" "text", "p_nota" "text") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."puede_cambiar_estado_cita"("p_doctor_id" "uuid", "p_destino" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."puede_cambiar_estado_cita"("p_doctor_id" "uuid", "p_destino" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."puede_cambiar_estado_cita"("p_doctor_id" "uuid", "p_destino" "text") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."puede_editar_consulta_propia"("p_consulta_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."puede_editar_consulta_propia"("p_consulta_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."puede_editar_consulta_propia"("p_consulta_id" "uuid") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."puede_ver_consulta"("p_consulta_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."puede_ver_consulta"("p_consulta_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."puede_ver_consulta"("p_consulta_id" "uuid") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."puede_ver_cuenta"("p_cuenta_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."puede_ver_cuenta"("p_cuenta_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."puede_ver_cuenta"("p_cuenta_id" "uuid") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."puede_ver_diente"("p_diente_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."puede_ver_diente"("p_diente_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."puede_ver_diente"("p_diente_id" "uuid") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."puede_ver_evaluacion"("p_evaluacion_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."puede_ver_evaluacion"("p_evaluacion_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."puede_ver_evaluacion"("p_evaluacion_id" "uuid") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."puede_ver_odontograma"("p_odontograma_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."puede_ver_odontograma"("p_odontograma_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."puede_ver_odontograma"("p_odontograma_id" "uuid") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."puede_ver_paciente"("p_paciente_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."puede_ver_paciente"("p_paciente_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."puede_ver_paciente"("p_paciente_id" "uuid") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."puede_ver_plan"("p_plan_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."puede_ver_plan"("p_plan_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."puede_ver_plan"("p_plan_id" "uuid") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."puede_ver_receta"("p_receta_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."puede_ver_receta"("p_receta_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."puede_ver_receta"("p_receta_id" "uuid") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."realinear_consulta_al_reprogramar_cita"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."realinear_consulta_al_reprogramar_cita"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."recibir_compra"("p_compra_id" "uuid", "p_usuario_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."recibir_compra"("p_compra_id" "uuid", "p_usuario_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."recibir_compra"("p_compra_id" "uuid", "p_usuario_id" "uuid") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."registrar_cita_emergencia"("p_paciente_id" "uuid", "p_doctor_id" "uuid", "p_motivo" "text", "p_duracion_minutos" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."registrar_cita_emergencia"("p_paciente_id" "uuid", "p_doctor_id" "uuid", "p_motivo" "text", "p_duracion_minutos" integer) TO "service_role";
GRANT ALL ON FUNCTION "public"."registrar_cita_emergencia"("p_paciente_id" "uuid", "p_doctor_id" "uuid", "p_motivo" "text", "p_duracion_minutos" integer) TO "authenticated";



REVOKE ALL ON FUNCTION "public"."registrar_consentimiento_plan"("p_plan_id" "uuid", "p_decision" "text", "p_persona" "text", "p_metodo" "text", "p_relacion" "text", "p_motivo" "text", "p_items" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."registrar_consentimiento_plan"("p_plan_id" "uuid", "p_decision" "text", "p_persona" "text", "p_metodo" "text", "p_relacion" "text", "p_motivo" "text", "p_items" "jsonb") TO "service_role";
GRANT ALL ON FUNCTION "public"."registrar_consentimiento_plan"("p_plan_id" "uuid", "p_decision" "text", "p_persona" "text", "p_metodo" "text", "p_relacion" "text", "p_motivo" "text", "p_items" "jsonb") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."registrar_llegada_cita"("p_cita_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."registrar_llegada_cita"("p_cita_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."registrar_llegada_cita"("p_cita_id" "uuid") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."registrar_mantenimiento_equipo"("p_equipo_id" "uuid", "p_suplidor_id" "uuid", "p_costo" numeric, "p_fecha_mantenimiento" timestamp with time zone, "p_descripcion" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."registrar_mantenimiento_equipo"("p_equipo_id" "uuid", "p_suplidor_id" "uuid", "p_costo" numeric, "p_fecha_mantenimiento" timestamp with time zone, "p_descripcion" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."registrar_mantenimiento_equipo"("p_equipo_id" "uuid", "p_suplidor_id" "uuid", "p_costo" numeric, "p_fecha_mantenimiento" timestamp with time zone, "p_descripcion" "text") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."registrar_paciente"("p_payload" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."registrar_paciente"("p_payload" "jsonb") TO "service_role";
GRANT ALL ON FUNCTION "public"."registrar_paciente"("p_payload" "jsonb") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."registrar_pago"("p_cuenta_id" "uuid", "p_monto" numeric, "p_metodo_pago" "text", "p_cuota_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."registrar_pago"("p_cuenta_id" "uuid", "p_monto" numeric, "p_metodo_pago" "text", "p_cuota_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."registrar_pago"("p_cuenta_id" "uuid", "p_monto" numeric, "p_metodo_pago" "text", "p_cuota_id" "uuid") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."registrar_pago_en_caja"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."registrar_pago_en_caja"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."reglas_clinicas_vigentes"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."reglas_clinicas_vigentes"() TO "service_role";
GRANT ALL ON FUNCTION "public"."reglas_clinicas_vigentes"() TO "authenticated";



REVOKE ALL ON FUNCTION "public"."resolver_alerta_clinica"("p_alerta_id" "uuid", "p_estado" "text", "p_justificacion" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."resolver_alerta_clinica"("p_alerta_id" "uuid", "p_estado" "text", "p_justificacion" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."resolver_alerta_clinica"("p_alerta_id" "uuid", "p_estado" "text", "p_justificacion" "text") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."retirar_regla_clinica"("p_codigo" "text", "p_motivo" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."retirar_regla_clinica"("p_codigo" "text", "p_motivo" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."retirar_regla_clinica"("p_codigo" "text", "p_motivo" "text") TO "authenticated";



REVOKE ALL ON FUNCTION "public"."sync_disponibilidad_doctor"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."sync_disponibilidad_doctor"() TO "service_role";



GRANT ALL ON FUNCTION "public"."time_dist"(time without time zone, time without time zone) TO "postgres";
GRANT ALL ON FUNCTION "public"."time_dist"(time without time zone, time without time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."time_dist"(time without time zone, time without time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."time_dist"(time without time zone, time without time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."ts_dist"(timestamp without time zone, timestamp without time zone) TO "postgres";
GRANT ALL ON FUNCTION "public"."ts_dist"(timestamp without time zone, timestamp without time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."ts_dist"(timestamp without time zone, timestamp without time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."ts_dist"(timestamp without time zone, timestamp without time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."tstz_dist"(timestamp with time zone, timestamp with time zone) TO "postgres";
GRANT ALL ON FUNCTION "public"."tstz_dist"(timestamp with time zone, timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."tstz_dist"(timestamp with time zone, timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."tstz_dist"(timestamp with time zone, timestamp with time zone) TO "service_role";



REVOKE ALL ON FUNCTION "public"."update_modified_column"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."update_modified_column"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."update_timestamp"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."update_timestamp"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."validar_caja_abierta"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."validar_caja_abierta"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."validar_cita_item_plan"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."validar_cita_item_plan"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."validar_doctor_activo"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."validar_doctor_activo"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."validar_fecha_nacimiento"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."validar_fecha_nacimiento"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."validar_monto_cuotas"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."validar_monto_cuotas"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."validar_monto_pago"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."validar_monto_pago"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."verificar_item_plan_ejecutable"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."verificar_item_plan_ejecutable"() TO "service_role";


















GRANT ALL ON TABLE "public"."dientes" TO "authenticated";
GRANT ALL ON TABLE "public"."dientes" TO "service_role";



GRANT ALL ON TABLE "public"."items_plan_tratamiento" TO "authenticated";
GRANT ALL ON TABLE "public"."items_plan_tratamiento" TO "service_role";



GRANT ALL ON TABLE "public"."planes_tratamiento" TO "authenticated";
GRANT ALL ON TABLE "public"."planes_tratamiento" TO "service_role";



GRANT ALL ON TABLE "public"."tratamientos" TO "authenticated";
GRANT ALL ON TABLE "public"."tratamientos" TO "service_role";



GRANT ALL ON TABLE "public"."actividades_agendables_paciente" TO "authenticated";
GRANT ALL ON TABLE "public"."actividades_agendables_paciente" TO "service_role";



GRANT ALL ON TABLE "public"."admins" TO "authenticated";
GRANT ALL ON TABLE "public"."admins" TO "service_role";



GRANT ALL ON TABLE "public"."alertas_clinicas" TO "authenticated";
GRANT ALL ON TABLE "public"."alertas_clinicas" TO "service_role";



GRANT ALL ON TABLE "public"."asistentes" TO "authenticated";
GRANT ALL ON TABLE "public"."asistentes" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."auditoria_clinica" TO "authenticated";
GRANT ALL ON TABLE "public"."auditoria_clinica" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."auditoria_correcciones_clinicas" TO "authenticated";
GRANT ALL ON TABLE "public"."auditoria_correcciones_clinicas" TO "service_role";



GRANT ALL ON TABLE "public"."auditoria_log" TO "service_role";



GRANT ALL ON SEQUENCE "public"."auditoria_log_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."auditoria_log_id_seq" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."auditoria_operaciones_admin" TO "authenticated";
GRANT ALL ON TABLE "public"."auditoria_operaciones_admin" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."auditoria_reglas_clinicas" TO "authenticated";
GRANT ALL ON TABLE "public"."auditoria_reglas_clinicas" TO "service_role";



GRANT ALL ON TABLE "public"."cajas" TO "authenticated";
GRANT ALL ON TABLE "public"."cajas" TO "service_role";



GRANT ALL ON TABLE "public"."cajas_diarias" TO "authenticated";
GRANT ALL ON TABLE "public"."cajas_diarias" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,MAINTAIN ON TABLE "public"."catalogo_signos_vitales" TO "authenticated";
GRANT ALL ON TABLE "public"."catalogo_signos_vitales" TO "service_role";



GRANT ALL ON TABLE "public"."citas" TO "authenticated";
GRANT ALL ON TABLE "public"."citas" TO "service_role";



GRANT ALL ON TABLE "public"."citas_items_plan" TO "authenticated";
GRANT ALL ON TABLE "public"."citas_items_plan" TO "service_role";



GRANT ALL ON TABLE "public"."compras" TO "authenticated";
GRANT ALL ON TABLE "public"."compras" TO "service_role";



GRANT ALL ON TABLE "public"."condiciones" TO "authenticated";
GRANT ALL ON TABLE "public"."condiciones" TO "service_role";



GRANT ALL ON TABLE "public"."condiciones_consulta" TO "authenticated";
GRANT ALL ON TABLE "public"."condiciones_consulta" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."consultas" TO "authenticated";
GRANT ALL ON TABLE "public"."consultas" TO "service_role";



GRANT UPDATE("fecha") ON TABLE "public"."consultas" TO "authenticated";



GRANT UPDATE("motivo_consulta") ON TABLE "public"."consultas" TO "authenticated";



GRANT UPDATE("temp_condiciones") ON TABLE "public"."consultas" TO "authenticated";



GRANT UPDATE("deleted_at") ON TABLE "public"."consultas" TO "authenticated";



GRANT UPDATE("updated_at") ON TABLE "public"."consultas" TO "authenticated";



GRANT UPDATE("notas") ON TABLE "public"."consultas" TO "authenticated";



GRANT UPDATE("signos_vitales") ON TABLE "public"."consultas" TO "authenticated";



GRANT UPDATE("tipo_atencion") ON TABLE "public"."consultas" TO "authenticated";



GRANT ALL ON TABLE "public"."record_condicion" TO "authenticated";
GRANT ALL ON TABLE "public"."record_condicion" TO "service_role";



GRANT ALL ON TABLE "public"."records" TO "authenticated";
GRANT ALL ON TABLE "public"."records" TO "service_role";



GRANT ALL ON TABLE "public"."condiciones_activas_paciente" TO "authenticated";
GRANT ALL ON TABLE "public"."condiciones_activas_paciente" TO "service_role";



GRANT ALL ON TABLE "public"."consentimientos_plan" TO "authenticated";
GRANT ALL ON TABLE "public"."consentimientos_plan" TO "service_role";



GRANT ALL ON TABLE "public"."consulta_resumen" TO "authenticated";
GRANT ALL ON TABLE "public"."consulta_resumen" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."consumibles" TO "authenticated";
GRANT ALL ON TABLE "public"."consumibles" TO "service_role";



GRANT UPDATE("nombre") ON TABLE "public"."consumibles" TO "authenticated";



GRANT UPDATE("descripcion") ON TABLE "public"."consumibles" TO "authenticated";



GRANT UPDATE("stock_minimo") ON TABLE "public"."consumibles" TO "authenticated";



GRANT UPDATE("deleted_at") ON TABLE "public"."consumibles" TO "authenticated";



GRANT UPDATE("updated_at") ON TABLE "public"."consumibles" TO "authenticated";



GRANT UPDATE("precio") ON TABLE "public"."consumibles" TO "authenticated";



GRANT UPDATE("suplidor_id") ON TABLE "public"."consumibles" TO "authenticated";



GRANT UPDATE("activo") ON TABLE "public"."consumibles" TO "authenticated";



GRANT ALL ON TABLE "public"."consumibles_compras" TO "authenticated";
GRANT ALL ON TABLE "public"."consumibles_compras" TO "service_role";



GRANT ALL ON TABLE "public"."consumos_consulta" TO "authenticated";
GRANT ALL ON TABLE "public"."consumos_consulta" TO "service_role";



GRANT ALL ON TABLE "public"."contactos" TO "authenticated";
GRANT ALL ON TABLE "public"."contactos" TO "service_role";



GRANT ALL ON TABLE "public"."contraindicaciones" TO "authenticated";
GRANT ALL ON TABLE "public"."contraindicaciones" TO "service_role";



GRANT ALL ON TABLE "public"."cuentas" TO "authenticated";
GRANT ALL ON TABLE "public"."cuentas" TO "service_role";



GRANT ALL ON TABLE "public"."cuotas" TO "authenticated";
GRANT ALL ON TABLE "public"."cuotas" TO "service_role";



GRANT ALL ON TABLE "public"."diagnosticos" TO "authenticated";
GRANT ALL ON TABLE "public"."diagnosticos" TO "service_role";



GRANT ALL ON TABLE "public"."diagnosticos_aplicados" TO "authenticated";
GRANT ALL ON TABLE "public"."diagnosticos_aplicados" TO "service_role";



GRANT ALL ON TABLE "public"."pacientes" TO "authenticated";
GRANT ALL ON TABLE "public"."pacientes" TO "service_role";



GRANT ALL ON TABLE "public"."personas" TO "authenticated";
GRANT ALL ON TABLE "public"."personas" TO "service_role";



GRANT ALL ON TABLE "public"."directorio_pacientes" TO "authenticated";
GRANT ALL ON TABLE "public"."directorio_pacientes" TO "service_role";



GRANT ALL ON TABLE "public"."doctor_asistentes" TO "authenticated";
GRANT ALL ON TABLE "public"."doctor_asistentes" TO "service_role";



GRANT ALL ON TABLE "public"."doctor_paciente" TO "authenticated";
GRANT ALL ON TABLE "public"."doctor_paciente" TO "service_role";



GRANT ALL ON SEQUENCE "public"."doctor_paciente_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."doctor_paciente_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."doctores" TO "authenticated";
GRANT ALL ON TABLE "public"."doctores" TO "service_role";



GRANT ALL ON TABLE "public"."documentos_clinicos" TO "authenticated";
GRANT ALL ON TABLE "public"."documentos_clinicos" TO "service_role";



GRANT ALL ON TABLE "public"."equipos" TO "authenticated";
GRANT ALL ON TABLE "public"."equipos" TO "service_role";



GRANT ALL ON TABLE "public"."equipos_mantenimientos" TO "authenticated";
GRANT ALL ON TABLE "public"."equipos_mantenimientos" TO "service_role";



GRANT ALL ON TABLE "public"."evaluaciones_clinicas" TO "authenticated";
GRANT ALL ON TABLE "public"."evaluaciones_clinicas" TO "service_role";



GRANT ALL ON TABLE "public"."items_cuenta" TO "authenticated";
GRANT ALL ON TABLE "public"."items_cuenta" TO "service_role";



GRANT ALL ON TABLE "public"."items_receta" TO "service_role";



GRANT ALL ON TABLE "public"."medicinas" TO "authenticated";
GRANT ALL ON TABLE "public"."medicinas" TO "service_role";



GRANT ALL ON TABLE "public"."movimientos_caja" TO "authenticated";
GRANT ALL ON TABLE "public"."movimientos_caja" TO "service_role";



GRANT SELECT,TRIGGER,MAINTAIN ON TABLE "public"."movimientos_stock_consumible" TO "authenticated";
GRANT ALL ON TABLE "public"."movimientos_stock_consumible" TO "service_role";



GRANT ALL ON TABLE "public"."odontogramas" TO "authenticated";
GRANT ALL ON TABLE "public"."odontogramas" TO "service_role";



GRANT ALL ON TABLE "public"."ordenes_medicas" TO "authenticated";
GRANT ALL ON TABLE "public"."ordenes_medicas" TO "service_role";



GRANT ALL ON TABLE "public"."pagos" TO "authenticated";
GRANT ALL ON TABLE "public"."pagos" TO "service_role";



GRANT ALL ON TABLE "public"."persona_contactos" TO "authenticated";
GRANT ALL ON TABLE "public"."persona_contactos" TO "service_role";



GRANT ALL ON TABLE "public"."procedimientos" TO "authenticated";
GRANT ALL ON TABLE "public"."procedimientos" TO "service_role";



GRANT ALL ON TABLE "public"."recetas" TO "authenticated";
GRANT ALL ON TABLE "public"."recetas" TO "service_role";



GRANT ALL ON TABLE "public"."reglas_clinicas" TO "authenticated";
GRANT ALL ON TABLE "public"."reglas_clinicas" TO "service_role";



GRANT ALL ON TABLE "public"."tratamientos_aplicados" TO "authenticated";
GRANT ALL ON TABLE "public"."tratamientos_aplicados" TO "service_role";



GRANT ALL ON TABLE "public"."resumen_actividad_plan" TO "authenticated";
GRANT ALL ON TABLE "public"."resumen_actividad_plan" TO "service_role";



GRANT ALL ON TABLE "public"."resumen_actividades_cita" TO "authenticated";
GRANT ALL ON TABLE "public"."resumen_actividades_cita" TO "service_role";



GRANT ALL ON SEQUENCE "public"."secuencia_codigo_receta" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."secuencia_codigo_receta" TO "service_role";



GRANT ALL ON TABLE "public"."signos_vitales_consulta" TO "authenticated";
GRANT ALL ON TABLE "public"."signos_vitales_consulta" TO "service_role";



GRANT ALL ON TABLE "public"."superficies" TO "authenticated";
GRANT ALL ON TABLE "public"."superficies" TO "service_role";



GRANT ALL ON TABLE "public"."suplidores" TO "authenticated";
GRANT ALL ON TABLE "public"."suplidores" TO "service_role";



GRANT ALL ON TABLE "public"."suplidores_contactos" TO "authenticated";
GRANT ALL ON TABLE "public"."suplidores_contactos" TO "service_role";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "public"."usuarios" TO "authenticated";
GRANT ALL ON TABLE "public"."usuarios" TO "service_role";



GRANT SELECT("id") ON TABLE "public"."usuarios" TO "authenticated";



GRANT SELECT("username") ON TABLE "public"."usuarios" TO "authenticated";



GRANT SELECT("last_login") ON TABLE "public"."usuarios" TO "authenticated";



GRANT SELECT("created_at") ON TABLE "public"."usuarios" TO "authenticated";



GRANT SELECT("deleted_at") ON TABLE "public"."usuarios" TO "authenticated";



GRANT SELECT("updated_at") ON TABLE "public"."usuarios" TO "authenticated";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































