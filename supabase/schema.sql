


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


COMMENT ON SCHEMA "public" IS 'standard public schema';



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

  select stock_actual
    into v_stock_anterior
    from public.consumibles
   where id = p_consumible_id
     and activo = true
   for update;

  if not found then
    raise exception 'No se encontró un consumible activo para ajustar.' using errcode = 'P0002';
  end if;

  update public.consumibles
     set stock_actual = p_nuevo_stock,
         estado = case
           when p_nuevo_stock <= 0 then 'agotado'
           when p_nuevo_stock <= stock_minimo then 'bajoStock'
           else 'disponible'
         end,
         updated_at = now()
   where id = p_consumible_id;

  insert into public.movimientos_stock_consumible (
    consumible_id, stock_anterior, stock_nuevo, diferencia, motivo, creado_por
  ) values (
    p_consumible_id,
    v_stock_anterior,
    p_nuevo_stock,
    p_nuevo_stock - v_stock_anterior,
    p_motivo,
    auth.uid()
  );
end;
$$;


ALTER FUNCTION "public"."ajustar_stock_consumible"("p_consumible_id" "uuid", "p_nuevo_stock" integer, "p_motivo" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cancelar_citas_paciente_inactivo"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Validamos el cambio a inactivo
    IF (NEW.estatus = 'inactivo') THEN
        UPDATE public.citas 
        SET estado = 'cancelada' 
        WHERE paciente_id = NEW.id 
          AND fecha_hora > now() 
          AND estado = 'pendiente';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."cancelar_citas_paciente_inactivo"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."crear_consulta_completa"("p_paciente_id" "uuid", "p_doctor_id" "uuid", "p_cita_id" "uuid", "p_fecha" timestamp with time zone, "p_motivo_consulta" "text", "p_temp_condiciones" "jsonb", "p_dientes" "jsonb", "p_documentos" "jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
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

  -- 3. Dientes + superficies
  for v_diente in select * from jsonb_array_elements(p_dientes)
  loop
    insert into dientes (
      odontograma_id, fdi_code, created_at, updated_at
    )
    values (
      v_odontograma_id, (v_diente ->> 'fdi_code')::int, now(), now()
    )
    returning id into v_diente_id;

    for v_superficie in select * from jsonb_array_elements(v_diente -> 'superficies')
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


ALTER FUNCTION "public"."crear_consulta_completa"("p_paciente_id" "uuid", "p_doctor_id" "uuid", "p_cita_id" "uuid", "p_fecha" timestamp with time zone, "p_motivo_consulta" "text", "p_temp_condiciones" "jsonb", "p_dientes" "jsonb", "p_documentos" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."es_admin"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
    SELECT EXISTS (
        SELECT 1
        FROM admins
        WHERE id = auth.uid()
    );
$$;


ALTER FUNCTION "public"."es_admin"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."es_asistente"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
    SELECT EXISTS (
        SELECT 1
        FROM asistentes
        WHERE id = auth.uid()
    );
$$;


ALTER FUNCTION "public"."es_asistente"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."es_doctor"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
    SELECT EXISTS (
        SELECT 1
        FROM doctores
        WHERE id = auth.uid()
    );
$$;


ALTER FUNCTION "public"."es_doctor"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."finalizar_consulta"("p_consulta_id" "uuid", "p_metodo_pago" "text" DEFAULT 'contado'::"text", "p_nota" "text" DEFAULT NULL::"text") RETURNS "uuid"
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

  if v_cita_id is not null then
    update citas set estado = 'completada'::estado_cita, updated_at = now()
    where id = v_cita_id;
  end if;

  return v_cuenta_id;
end;
$$;


ALTER FUNCTION "public"."finalizar_consulta"("p_consulta_id" "uuid", "p_metodo_pago" "text", "p_nota" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_aplicar_movimiento_stock"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_stock_actual INT;
  v_stock_nuevo INT;
BEGIN
  SELECT stock_actual INTO v_stock_actual
  FROM consumibles
  WHERE id = NEW.consumible_id
  FOR UPDATE; -- bloquea la fila mientras se calcula, evita carrera con otro movimiento simultáneo

  IF v_stock_actual IS NULL THEN
    RAISE EXCEPTION 'Consumible % no existe', NEW.consumible_id;
  END IF;

  v_stock_nuevo := GREATEST(v_stock_actual + NEW.diferencia, 0);

  NEW.stock_anterior := v_stock_actual;
  NEW.stock_nuevo := v_stock_nuevo;

  UPDATE consumibles
  SET stock_actual = v_stock_nuevo, updated_at = NOW()
  WHERE id = NEW.consumible_id;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."fn_aplicar_movimiento_stock"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generar_plan_cuotas"("p_cuenta_id" "uuid", "p_cuotas" "jsonb") RETURNS "void"
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


ALTER FUNCTION "public"."generar_plan_cuotas"("p_cuenta_id" "uuid", "p_cuotas" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_persona_id uuid;
  v_contacto_id uuid;
  v_meta jsonb := new.raw_user_meta_data;
  v_rol text := v_meta ->> 'rol';
  v_telefono text := v_meta ->> 'telefono';
begin
  if v_rol is null or v_rol not in ('doctor', 'admin', 'asistente') then
    raise exception 'El rol proporcionado ("%") es inválido o no fue enviado en la metadata.', coalesce(v_rol, 'NULL');
  end if;

  insert into public.personas (
    nombre, 
    apellido, 
    fecha_nacimiento, 
    cedula, 
    estatus
  ) values (
    v_meta ->> 'nombre',
    v_meta ->> 'apellido',
    nullif(v_meta ->> 'fecha_nacimiento', '')::date,
    v_meta ->> 'cedula',
    coalesce(v_meta ->> 'estatus', 'activo')::estatus_persona
  )
  returning id into v_persona_id;

  if v_telefono is not null and v_telefono != '' then
    insert into public.contactos (numero_telefono)
    values (v_telefono)
    returning id into v_contacto_id;

    insert into public.persona_contactos (
      persona_id, 
      tipo_contacto, 
      contacto_id,
      es_principal
    ) values (
      v_persona_id,
      'telefono',
      v_contacto_id,
      true
    );
  end if;

  insert into public.usuarios (id, username)
  values (v_persona_id, v_meta ->> 'username');

  if v_rol = 'doctor' then
    insert into public.doctores (id, especialidad, esta_disponible)
    values (v_persona_id, coalesce(v_meta ->> 'especialidad', 'General'), true);
    
  elsif v_rol = 'admin' then
    insert into public.admins (id, departamento)
    values (v_persona_id, coalesce(v_meta ->> 'departamento', 'Administración'));
    
  elsif v_rol = 'asistente' then
    insert into public.asistentes (id, turno)
    values (v_persona_id, coalesce(v_meta ->> 'turno', 'Matutino'));
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


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


ALTER FUNCTION "public"."marcar_cuotas_vencidas"("p_cuenta_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."recibir_compra"("p_compra_id" "uuid", "p_usuario_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_caja_id UUID;
  v_monto_total NUMERIC(12, 2);
  v_estado_compra TEXT;
  v_item RECORD;
BEGIN
  -- 1. Verificar estado de la compra
  SELECT estado::text INTO v_estado_compra
  FROM compras
  WHERE id = p_compra_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'La compra especificada no existe.';
  END IF;

  IF v_estado_compra IN ('recibido', 'recibida') THEN
    RAISE EXCEPTION 'Esta compra ya fue recibida anteriormente.';
  END IF;

  -- 2. Calcular el monto total de la compra
  SELECT COALESCE(SUM(cantidad * precio_unitario), 0)
  INTO v_monto_total
  FROM consumibles_compras
  WHERE compra_id = p_compra_id;

  -- 3. Obtener la caja activa (cerrada = false)
  SELECT id INTO v_caja_id
  FROM cajas
  WHERE cerrada = false
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_caja_id IS NULL THEN
    RAISE EXCEPTION 'No hay ninguna caja abierta actualmente.';
  END IF;

  -- 4. Marcar compra como recibida
  UPDATE compras
  SET 
    estado = 'recibido'::estado_compra,
    updated_at = NOW()
  WHERE id = p_compra_id;

  -- 5. Incrementar stock en consumibles
  FOR v_item IN 
    SELECT consumible_id, cantidad 
    FROM consumibles_compras 
    WHERE compra_id = p_compra_id
  LOOP
    UPDATE consumibles
    SET 
      stock_actual = stock_actual + v_item.cantidad,
      updated_at = NOW()
    WHERE id = v_item.consumible_id;
  END LOOP;

  -- 6. Insertar movimiento de egreso
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

    -- 7. Actualizar explícitamente la columna monto_esperado en la tabla cajas
    UPDATE cajas
    SET 
      monto_esperado = COALESCE(monto_esperado, 0) - v_monto_total,
      updated_at = NOW()
    WHERE id = v_caja_id;
  END IF;

END;
$$;


ALTER FUNCTION "public"."recibir_compra"("p_compra_id" "uuid", "p_usuario_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."registrar_pago"("p_cuenta_id" "uuid", "p_monto" numeric, "p_metodo_pago" "text", "p_cuota_id" "uuid" DEFAULT NULL::"uuid") RETURNS "uuid"
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


CREATE OR REPLACE FUNCTION "public"."validar_disponibilidad_doctor_simple"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    is_doctor_available boolean;
BEGIN
    -- 1. Buscamos el valor de 'esta_disponible' (bool) en la tabla doctores
    SELECT esta_disponible INTO is_doctor_available 
    FROM doctores 
    WHERE id = NEW.doctor_id;

    -- 2. Si el bool es false, bloqueamos la cita
    IF is_doctor_available = false THEN
        RAISE EXCEPTION 'El doctor ha marcado su estado como NO DISPONIBLE.';
    END IF;

    -- 3. La parte de las citas solapadas sigue igual (esto busca en la tabla citas)
    IF EXISTS (
        SELECT 1 FROM citas 
        WHERE doctor_id = NEW.doctor_id 
        AND fecha_hora = NEW.fecha_hora 
        AND estado NOT IN ('candelada', 'no_asistida') -- Estos son los estados de la CITA, no del doctor
        AND id != NEW.id
    ) THEN
        RAISE EXCEPTION 'Ya existe una cita ocupando este horario para este doctor.';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."validar_disponibilidad_doctor_simple"() OWNER TO "postgres";


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


CREATE TABLE IF NOT EXISTS "public"."admins" (
    "id" "uuid" NOT NULL,
    "departamento" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone
);


ALTER TABLE "public"."admins" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."asistentes" (
    "id" "uuid" NOT NULL,
    "turno" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone
);


ALTER TABLE "public"."asistentes" OWNER TO "postgres";


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


CREATE TABLE IF NOT EXISTS "public"."citas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "persona_id" "uuid" NOT NULL,
    "doctor_id" "uuid" NOT NULL,
    "fecha_hora" timestamp with time zone NOT NULL,
    "es_emergencia" boolean DEFAULT false,
    "estado" "public"."estado_cita" DEFAULT 'programada'::"public"."estado_cita",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "duracion_minutos" bigint,
    "updated_at" timestamp with time zone
);


ALTER TABLE "public"."citas" OWNER TO "postgres";


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
    "finalizada" boolean DEFAULT false
);


ALTER TABLE "public"."consultas" OWNER TO "postgres";


COMMENT ON COLUMN "public"."consultas"."finalizada" IS 'Has the consult ended?';



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



CREATE TABLE IF NOT EXISTS "public"."doctor_asistentes" (
    "doctor_id" "uuid" NOT NULL,
    "asistente_id" "uuid" NOT NULL
);


ALTER TABLE "public"."doctor_asistentes" OWNER TO "postgres";


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
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."items_cuenta" OWNER TO "postgres";


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
    CONSTRAINT "items_plan_fechas_coherentes" CHECK (((("estado" <> 'rechazado'::"public"."estado_item_plan") OR ("fecha_rechazo" IS NOT NULL)) AND (("estado" <> 'completado'::"public"."estado_item_plan") OR ("fecha_completado" IS NOT NULL)))),
    CONSTRAINT "items_plan_precio_no_negativo" CHECK (("precio_estimado" >= (0)::numeric))
);


ALTER TABLE "public"."items_plan_tratamiento" OWNER TO "postgres";


COMMENT ON TABLE "public"."items_plan_tratamiento" IS 'Actividad planificada sobre un diente/superficie. Su estado es la decisión clínica y del paciente; no genera cargo hasta ejecutarse.';



CREATE TABLE IF NOT EXISTS "public"."medicinas" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "nombre" "text" NOT NULL,
    "efectos_secundarios" "public"."efecto_secundario"[],
    "created_at" timestamp with time zone DEFAULT "now"(),
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone
);


ALTER TABLE "public"."medicinas" OWNER TO "postgres";


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
    CONSTRAINT "movimientos_stock_consumible_diferencia_check" CHECK (("diferencia" = ("stock_nuevo" - "stock_anterior"))),
    CONSTRAINT "movimientos_stock_consumible_motivo_check" CHECK (("motivo" = ANY (ARRAY['merma'::"text", 'correccion'::"text", 'usoInterno'::"text"]))),
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
    "altura" numeric(5,2)
);


ALTER TABLE "public"."pacientes" OWNER TO "postgres";


COMMENT ON COLUMN "public"."pacientes"."peso" IS 'Peso base del paciente en kg o lbs';



COMMENT ON COLUMN "public"."pacientes"."altura" IS 'Altura del paciente en cm';



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
    "deleted_at" timestamp with time zone
);


ALTER TABLE "public"."planes_tratamiento" OWNER TO "postgres";


COMMENT ON TABLE "public"."planes_tratamiento" IS 'Lo que se decide tratar. Agrupa las actividades propuestas al paciente a partir de una evaluación; solo un subconjunto de los hallazgos llega aquí.';



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
    "medicina_id" "uuid" NOT NULL,
    "titulo" "text" NOT NULL,
    "dosis" "text" NOT NULL,
    "frecuencia" "text" NOT NULL,
    "indicaciones" "text" NOT NULL,
    "duracion" "text" NOT NULL,
    "notas" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "title" "text",
    "paciente_id" "uuid"
);


ALTER TABLE "public"."recetas" OWNER TO "postgres";


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
    CONSTRAINT "tratamientos_aplicados_solo_ejecucion" CHECK ((("deleted_at" IS NOT NULL) OR ("estado" = ANY (ARRAY['aplicado'::"text", 'en_proceso'::"text", 'completado'::"text"]))))
);


ALTER TABLE "public"."tratamientos_aplicados" OWNER TO "postgres";


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



ALTER TABLE ONLY "public"."admins"
    ADD CONSTRAINT "admin_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."asistentes"
    ADD CONSTRAINT "asistentes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajas_diarias"
    ADD CONSTRAINT "caja_diaria_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cajas"
    ADD CONSTRAINT "cajas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."citas"
    ADD CONSTRAINT "citas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."compras"
    ADD CONSTRAINT "compras_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."condiciones"
    ADD CONSTRAINT "condiciones_nombre_key" UNIQUE ("nombre");



ALTER TABLE ONLY "public"."condiciones"
    ADD CONSTRAINT "condiciones_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."consultas"
    ADD CONSTRAINT "consultas_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."consumibles_compras"
    ADD CONSTRAINT "consumible_compra_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."consumibles"
    ADD CONSTRAINT "consumibles_pkey" PRIMARY KEY ("id");



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



CREATE UNIQUE INDEX "cajas_una_abierta_idx" ON "public"."cajas" USING "btree" ("cerrada") WHERE ("cerrada" = false);



CREATE UNIQUE INDEX "consumibles_nombre_activo_unico_idx" ON "public"."consumibles" USING "btree" ("lower"("btrim"("nombre"))) WHERE "activo";



CREATE INDEX "idx_afliccion_record" ON "public"."record_condicion" USING "btree" ("record_id");



CREATE INDEX "idx_compra_suplidor" ON "public"."consumibles_compras" USING "btree" ("suplidor_id");



CREATE INDEX "idx_consultas_paciente_id" ON "public"."consultas" USING "btree" ("paciente_id");



CREATE INDEX "idx_contra_tratamiento" ON "public"."contraindicaciones" USING "btree" ("tratamiento_id");



CREATE INDEX "idx_contraindicaciones_medicina_id" ON "public"."contraindicaciones" USING "btree" ("medicina_id");



CREATE INDEX "idx_cuotas_cuenta_vencimiento" ON "public"."cuotas" USING "btree" ("cuenta_id", "fecha_vencimiento") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_diagnosticos_aplicados_consulta_id" ON "public"."diagnosticos_aplicados" USING "btree" ("consulta_id");



CREATE INDEX "idx_diagnosticos_aplicados_diente_id" ON "public"."diagnosticos_aplicados" USING "btree" ("diente_id");



CREATE INDEX "idx_diagnosticos_aplicados_evaluacion" ON "public"."diagnosticos_aplicados" USING "btree" ("evaluacion_id") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_documentos_consulta" ON "public"."documentos_clinicos" USING "btree" ("consulta_id");



CREATE INDEX "idx_evaluaciones_clinicas_paciente" ON "public"."evaluaciones_clinicas" USING "btree" ("paciente_id", "fecha" DESC) WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_items_plan_diagnostico" ON "public"."items_plan_tratamiento" USING "btree" ("diagnostico_aplicado_id") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_items_plan_diente" ON "public"."items_plan_tratamiento" USING "btree" ("diente_id") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_items_plan_estado" ON "public"."items_plan_tratamiento" USING "btree" ("estado") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_items_plan_plan" ON "public"."items_plan_tratamiento" USING "btree" ("plan_id", "orden") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_pagos_cuota_id" ON "public"."pagos" USING "btree" ("cuota_id") WHERE (("cuota_id" IS NOT NULL) AND ("deleted_at" IS NULL));



CREATE INDEX "idx_planes_tratamiento_evaluacion" ON "public"."planes_tratamiento" USING "btree" ("evaluacion_id") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_planes_tratamiento_paciente" ON "public"."planes_tratamiento" USING "btree" ("paciente_id", "fecha_propuesta" DESC) WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_recetas_consulta" ON "public"."recetas" USING "btree" ("consulta_id");



CREATE INDEX "idx_suplidor_contacto_ref" ON "public"."suplidores_contactos" USING "btree" ("suplidor_id");



CREATE INDEX "idx_tratamientos_aplicados_consulta_id" ON "public"."tratamientos_aplicados" USING "btree" ("consulta_id");



CREATE INDEX "idx_tratamientos_aplicados_diente_id" ON "public"."tratamientos_aplicados" USING "btree" ("diente_id");



CREATE INDEX "idx_tratamientos_aplicados_estado" ON "public"."tratamientos_aplicados" USING "btree" ("consulta_id", "estado") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_tratamientos_aplicados_item_plan" ON "public"."tratamientos_aplicados" USING "btree" ("item_plan_id") WHERE ("deleted_at" IS NULL);



CREATE INDEX "movimientos_caja_fecha_idx" ON "public"."movimientos_caja" USING "btree" ("caja_diaria_id", "fecha" DESC) WHERE ("deleted_at" IS NULL);



CREATE INDEX "movimientos_stock_consumible_consumible_fecha_idx" ON "public"."movimientos_stock_consumible" USING "btree" ("consumible_id", "created_at" DESC);



CREATE UNIQUE INDEX "uq_evaluaciones_clinicas_consulta" ON "public"."evaluaciones_clinicas" USING "btree" ("consulta_id") WHERE (("consulta_id" IS NOT NULL) AND ("deleted_at" IS NULL));



CREATE OR REPLACE TRIGGER "pagos_registrar_ingreso_caja" AFTER INSERT ON "public"."pagos" FOR EACH ROW EXECUTE FUNCTION "public"."registrar_pago_en_caja"();



CREATE OR REPLACE TRIGGER "tr_actualizar_stock_al_recibir" AFTER UPDATE ON "public"."compras" FOR EACH ROW EXECUTE FUNCTION "public"."actualizar_stock_por_compra"();



CREATE OR REPLACE TRIGGER "tr_cita_cancelada_log" AFTER UPDATE OF "estado" ON "public"."citas" FOR EACH ROW EXECUTE FUNCTION "public"."manejar_cita_cancelada"();



CREATE OR REPLACE TRIGGER "tr_limpiar_superficie_on_diagnosis_delete" AFTER DELETE ON "public"."diagnosticos_aplicados" FOR EACH ROW EXECUTE FUNCTION "public"."limpiar_diagnosticos_superficie"();



CREATE OR REPLACE TRIGGER "tr_paciente_inactivo_cancela_citas" AFTER UPDATE OF "estatus" ON "public"."personas" FOR EACH ROW EXECUTE FUNCTION "public"."cancelar_citas_paciente_inactivo"();



CREATE OR REPLACE TRIGGER "tr_update_doctores_timestamp" BEFORE UPDATE ON "public"."doctores" FOR EACH ROW EXECUTE FUNCTION "public"."update_timestamp"();



CREATE OR REPLACE TRIGGER "tr_update_pacientes_timestamp" BEFORE UPDATE ON "public"."pacientes" FOR EACH ROW EXECUTE FUNCTION "public"."update_timestamp"();



CREATE OR REPLACE TRIGGER "tr_update_personas_timestamp" BEFORE UPDATE ON "public"."personas" FOR EACH ROW EXECUTE FUNCTION "public"."update_timestamp"();



CREATE OR REPLACE TRIGGER "tr_validar_doctor_persona" BEFORE INSERT OR UPDATE ON "public"."doctores" FOR EACH ROW EXECUTE FUNCTION "public"."validar_doctor_activo"();



CREATE OR REPLACE TRIGGER "tr_validar_edad_persona" BEFORE INSERT OR UPDATE ON "public"."personas" FOR EACH ROW EXECUTE FUNCTION "public"."validar_fecha_nacimiento"();



CREATE OR REPLACE TRIGGER "tr_validar_exceso_pago" BEFORE INSERT OR UPDATE OF "monto", "estado" ON "public"."pagos" FOR EACH ROW EXECUTE FUNCTION "public"."validar_monto_pago"();



CREATE OR REPLACE TRIGGER "tr_validar_limite_cuotas" BEFORE INSERT OR UPDATE ON "public"."cuotas" FOR EACH ROW EXECUTE FUNCTION "public"."validar_monto_cuotas"();



CREATE OR REPLACE TRIGGER "tr_validar_pago_caja_abierta" BEFORE INSERT ON "public"."movimientos_caja" FOR EACH ROW EXECUTE FUNCTION "public"."validar_caja_abierta"();



CREATE OR REPLACE TRIGGER "trg_aplicar_movimiento_stock" BEFORE INSERT ON "public"."movimientos_stock_consumible" FOR EACH ROW EXECUTE FUNCTION "public"."fn_aplicar_movimiento_stock"();



CREATE OR REPLACE TRIGGER "trg_item_plan_ejecutable" BEFORE INSERT OR UPDATE OF "item_plan_id" ON "public"."tratamientos_aplicados" FOR EACH ROW EXECUTE FUNCTION "public"."verificar_item_plan_ejecutable"();



CREATE OR REPLACE TRIGGER "trg_sync_disponibilidad_doctor" AFTER INSERT OR DELETE OR UPDATE ON "public"."citas" FOR EACH ROW EXECUTE FUNCTION "public"."sync_disponibilidad_doctor"();



CREATE OR REPLACE TRIGGER "update_dientes_modtime" BEFORE UPDATE ON "public"."dientes" FOR EACH ROW EXECUTE FUNCTION "public"."update_modified_column"();



ALTER TABLE ONLY "public"."admins"
    ADD CONSTRAINT "admins_id_fkey" FOREIGN KEY ("id") REFERENCES "public"."usuarios"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."asistentes"
    ADD CONSTRAINT "asistentes_id_fkey" FOREIGN KEY ("id") REFERENCES "public"."usuarios"("id") ON UPDATE CASCADE ON DELETE CASCADE;



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



ALTER TABLE ONLY "public"."citas"
    ADD CONSTRAINT "citas_persona_id_fkey" FOREIGN KEY ("persona_id") REFERENCES "public"."personas"("id");



ALTER TABLE ONLY "public"."consultas"
    ADD CONSTRAINT "consultas_cita_id_fkey" FOREIGN KEY ("cita_id") REFERENCES "public"."citas"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."consultas"
    ADD CONSTRAINT "consultas_doctor_id_fkey" FOREIGN KEY ("doctor_id") REFERENCES "public"."doctores"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."consultas"
    ADD CONSTRAINT "consultas_paciente_id_fkey" FOREIGN KEY ("paciente_id") REFERENCES "public"."pacientes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."consumibles_compras"
    ADD CONSTRAINT "consumible_compra_compra_id_fkey" FOREIGN KEY ("compra_id") REFERENCES "public"."compras"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."consumibles_compras"
    ADD CONSTRAINT "consumible_compra_consumible_id_fkey" FOREIGN KEY ("consumible_id") REFERENCES "public"."consumibles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."consumibles_compras"
    ADD CONSTRAINT "consumible_compra_suplidor_id_fkey" FOREIGN KEY ("suplidor_id") REFERENCES "public"."suplidores"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."consumibles"
    ADD CONSTRAINT "consumibles_suplidor_id_fkey" FOREIGN KEY ("suplidor_id") REFERENCES "public"."suplidores"("id");



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
    ADD CONSTRAINT "cuentas_paciente_id_fkey" FOREIGN KEY ("paciente_id") REFERENCES "public"."personas"("id");



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



ALTER TABLE ONLY "public"."doctores"
    ADD CONSTRAINT "doctores_id_fkey" FOREIGN KEY ("id") REFERENCES "public"."usuarios"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."documentos_clinicos"
    ADD CONSTRAINT "documentos_clinicos_consulta_id_fkey" FOREIGN KEY ("consulta_id") REFERENCES "public"."consultas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."documentos_clinicos"
    ADD CONSTRAINT "documentos_clinicos_paciente_id_fkey" FOREIGN KEY ("paciente_id") REFERENCES "public"."pacientes"("id") ON DELETE CASCADE;



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
    ADD CONSTRAINT "evaluaciones_clinicas_paciente_id_fkey" FOREIGN KEY ("paciente_id") REFERENCES "public"."pacientes"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."consumibles_compras"
    ADD CONSTRAINT "fk_consumibles_compras_compra" FOREIGN KEY ("compra_id") REFERENCES "public"."compras"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."contraindicaciones"
    ADD CONSTRAINT "fk_contraindicaciones_medicina" FOREIGN KEY ("medicina_id") REFERENCES "public"."medicinas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."items_cuenta"
    ADD CONSTRAINT "item_cuentas_cuenta_id_fkey" FOREIGN KEY ("cuenta_id") REFERENCES "public"."cuentas"("id") ON DELETE CASCADE;



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



ALTER TABLE ONLY "public"."movimientos_caja"
    ADD CONSTRAINT "movimientos_caja_caja_diaria_id_fkey" FOREIGN KEY ("caja_diaria_id") REFERENCES "public"."cajas"("id") ON DELETE CASCADE;



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
    ADD CONSTRAINT "planes_tratamiento_paciente_id_fkey" FOREIGN KEY ("paciente_id") REFERENCES "public"."pacientes"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."recetas"
    ADD CONSTRAINT "recetas_consulta_id_fkey" FOREIGN KEY ("consulta_id") REFERENCES "public"."consultas"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recetas"
    ADD CONSTRAINT "recetas_medicina_id_fkey" FOREIGN KEY ("medicina_id") REFERENCES "public"."medicinas"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."recetas"
    ADD CONSTRAINT "recetas_paciente_id_fkey" FOREIGN KEY ("paciente_id") REFERENCES "public"."personas"("id");



ALTER TABLE ONLY "public"."record_condicion"
    ADD CONSTRAINT "record_afliccion_condicion_id_fkey" FOREIGN KEY ("condicion_id") REFERENCES "public"."condiciones"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."record_condicion"
    ADD CONSTRAINT "record_afliccion_record_id_fkey" FOREIGN KEY ("record_id") REFERENCES "public"."records"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."records"
    ADD CONSTRAINT "records_paciente_id_fkey" FOREIGN KEY ("paciente_id") REFERENCES "public"."pacientes"("id") ON DELETE CASCADE;



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



ALTER TABLE "public"."asistentes" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "asistentes_delete" ON "public"."asistentes" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "asistentes_insert" ON "public"."asistentes" FOR INSERT TO "authenticated" WITH CHECK ("public"."es_admin"());



CREATE POLICY "asistentes_select" ON "public"."asistentes" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "asistentes_update" ON "public"."asistentes" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR ("id" = "auth"."uid"()))) WITH CHECK (("public"."es_admin"() OR ("id" = "auth"."uid"())));



CREATE POLICY "authenticated_adjust_stock_consumible" ON "public"."movimientos_stock_consumible" FOR INSERT TO "authenticated" WITH CHECK (true);



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



ALTER TABLE "public"."citas" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "citas_delete" ON "public"."citas" FOR DELETE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_asistente"() OR "public"."es_doctor"()));



CREATE POLICY "citas_insert" ON "public"."citas" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_asistente"() OR "public"."es_doctor"()));



CREATE POLICY "citas_select" ON "public"."citas" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "citas_update" ON "public"."citas" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_asistente"() OR "public"."es_doctor"()));



ALTER TABLE "public"."compras" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "compras_delete" ON "public"."compras" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "compras_insert" ON "public"."compras" FOR INSERT TO "authenticated" WITH CHECK ("public"."es_admin"());



CREATE POLICY "compras_select" ON "public"."compras" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "compras_update" ON "public"."compras" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_asistente"())) WITH CHECK (("public"."es_admin"() OR "public"."es_asistente"()));



ALTER TABLE "public"."condiciones" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "condiciones_delete" ON "public"."condiciones" FOR DELETE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "condiciones_insert" ON "public"."condiciones" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "condiciones_select" ON "public"."condiciones" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "condiciones_update" ON "public"."condiciones" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"())) WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "consulta_delete" ON "public"."consultas" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "consulta_insert" ON "public"."consultas" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "consulta_select" ON "public"."consultas" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "consulta_update" ON "public"."consultas" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



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



CREATE POLICY "consumibles_update" ON "public"."consumibles" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_asistente"())) WITH CHECK (("public"."es_admin"() OR "public"."es_asistente"()));



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



CREATE POLICY "cuenta_select" ON "public"."cuentas" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "cuenta_update" ON "public"."cuentas" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



ALTER TABLE "public"."cuentas" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cuotas" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "cuotas_delete" ON "public"."cuotas" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "cuotas_insert" ON "public"."cuotas" FOR INSERT TO "authenticated" WITH CHECK ("public"."es_admin"());



CREATE POLICY "cuotas_select" ON "public"."cuotas" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "cuotas_update" ON "public"."cuotas" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_asistente"())) WITH CHECK (("public"."es_admin"() OR "public"."es_asistente"()));



ALTER TABLE "public"."diagnosticos" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."diagnosticos_aplicados" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "diagnosticos_aplicados_delete" ON "public"."diagnosticos_aplicados" FOR DELETE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "diagnosticos_aplicados_insert" ON "public"."diagnosticos_aplicados" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "diagnosticos_aplicados_select" ON "public"."diagnosticos_aplicados" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "diagnosticos_aplicados_update" ON "public"."diagnosticos_aplicados" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"())) WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "diagnosticos_delete" ON "public"."diagnosticos" FOR DELETE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "diagnosticos_insert" ON "public"."diagnosticos" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "diagnosticos_select" ON "public"."diagnosticos" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "diagnosticos_update" ON "public"."diagnosticos" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"())) WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



ALTER TABLE "public"."dientes" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "dientes_delete" ON "public"."dientes" FOR DELETE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "dientes_insert" ON "public"."dientes" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "dientes_select" ON "public"."dientes" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "dientes_update" ON "public"."dientes" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"())) WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



ALTER TABLE "public"."doctor_asistentes" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "doctor_asistentes_delete" ON "public"."doctor_asistentes" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "doctor_asistentes_insert" ON "public"."doctor_asistentes" FOR INSERT TO "authenticated" WITH CHECK ("public"."es_admin"());



CREATE POLICY "doctor_asistentes_select" ON "public"."doctor_asistentes" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR ("doctor_id" = "auth"."uid"()) OR ("asistente_id" = "auth"."uid"())));



CREATE POLICY "doctor_asistentes_update" ON "public"."doctor_asistentes" FOR UPDATE TO "authenticated" USING ("public"."es_admin"()) WITH CHECK ("public"."es_admin"());



ALTER TABLE "public"."doctores" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "doctores_delete" ON "public"."doctores" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "doctores_insert" ON "public"."doctores" FOR INSERT TO "authenticated" WITH CHECK ("public"."es_admin"());



CREATE POLICY "doctores_select" ON "public"."doctores" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "doctores_update" ON "public"."doctores" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR ("id" = "auth"."uid"()))) WITH CHECK (("public"."es_admin"() OR ("id" = "auth"."uid"())));



ALTER TABLE "public"."documentos_clinicos" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "documentos_clinicos_delete" ON "public"."documentos_clinicos" FOR DELETE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "documentos_clinicos_insert" ON "public"."documentos_clinicos" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "documentos_clinicos_select" ON "public"."documentos_clinicos" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "documentos_clinicos_update" ON "public"."documentos_clinicos" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"())) WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



ALTER TABLE "public"."equipos" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "equipos_delete" ON "public"."equipos" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "equipos_insert" ON "public"."equipos" FOR INSERT TO "authenticated" WITH CHECK ("public"."es_admin"());



ALTER TABLE "public"."equipos_mantenimientos" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "equipos_mantenimientos_delete" ON "public"."equipos_mantenimientos" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "equipos_mantenimientos_insert" ON "public"."equipos_mantenimientos" FOR INSERT TO "authenticated" WITH CHECK ("public"."es_admin"());



CREATE POLICY "equipos_mantenimientos_select" ON "public"."equipos_mantenimientos" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "equipos_mantenimientos_update" ON "public"."equipos_mantenimientos" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_asistente"())) WITH CHECK (("public"."es_admin"() OR "public"."es_asistente"()));



CREATE POLICY "equipos_select" ON "public"."equipos" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "equipos_update" ON "public"."equipos" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_asistente"())) WITH CHECK (("public"."es_admin"() OR "public"."es_asistente"()));



ALTER TABLE "public"."evaluaciones_clinicas" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "evaluaciones_clinicas_delete" ON "public"."evaluaciones_clinicas" FOR DELETE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "evaluaciones_clinicas_insert" ON "public"."evaluaciones_clinicas" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "evaluaciones_clinicas_select" ON "public"."evaluaciones_clinicas" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "evaluaciones_clinicas_update" ON "public"."evaluaciones_clinicas" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"())) WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



ALTER TABLE "public"."items_cuenta" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "items_cuenta_delete" ON "public"."items_cuenta" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "items_cuenta_insert" ON "public"."items_cuenta" FOR INSERT TO "authenticated" WITH CHECK ("public"."es_admin"());



CREATE POLICY "items_cuenta_select" ON "public"."items_cuenta" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "items_cuenta_update" ON "public"."items_cuenta" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_asistente"())) WITH CHECK (("public"."es_admin"() OR "public"."es_asistente"()));



ALTER TABLE "public"."items_plan_tratamiento" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "items_plan_tratamiento_delete" ON "public"."items_plan_tratamiento" FOR DELETE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "items_plan_tratamiento_insert" ON "public"."items_plan_tratamiento" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "items_plan_tratamiento_select" ON "public"."items_plan_tratamiento" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "items_plan_tratamiento_update" ON "public"."items_plan_tratamiento" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"())) WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



ALTER TABLE "public"."medicinas" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "medicinas_delete" ON "public"."medicinas" FOR DELETE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "medicinas_insert" ON "public"."medicinas" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "medicinas_select" ON "public"."medicinas" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "medicinas_update" ON "public"."medicinas" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"())) WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



ALTER TABLE "public"."movimientos_caja" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."movimientos_stock_consumible" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "odontograma_insert" ON "public"."odontogramas" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "odontograma_select" ON "public"."odontogramas" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



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



CREATE POLICY "pacientes_select" ON "public"."pacientes" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "pacientes_update" ON "public"."pacientes" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "pago_delete" ON "public"."pagos" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "pago_insert" ON "public"."pagos" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_asistente"()));



CREATE POLICY "pago_select" ON "public"."pagos" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "pago_update" ON "public"."pagos" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_asistente"()));



ALTER TABLE "public"."pagos" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."persona_contactos" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "persona_contactos_delete" ON "public"."persona_contactos" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "persona_contactos_insert" ON "public"."persona_contactos" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "persona_contactos_select" ON "public"."persona_contactos" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "persona_contactos_update" ON "public"."persona_contactos" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"())) WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "persona_delete" ON "public"."personas" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "persona_insert" ON "public"."personas" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "persona_select" ON "public"."personas" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



CREATE POLICY "persona_update" ON "public"."personas" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"() OR "public"."es_asistente"()));



ALTER TABLE "public"."personas" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."planes_tratamiento" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "planes_tratamiento_delete" ON "public"."planes_tratamiento" FOR DELETE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "planes_tratamiento_insert" ON "public"."planes_tratamiento" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "planes_tratamiento_select" ON "public"."planes_tratamiento" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "planes_tratamiento_update" ON "public"."planes_tratamiento" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"())) WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



ALTER TABLE "public"."procedimientos" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "procedimientos_delete" ON "public"."procedimientos" FOR DELETE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "procedimientos_insert" ON "public"."procedimientos" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "procedimientos_select" ON "public"."procedimientos" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "procedimientos_update" ON "public"."procedimientos" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"())) WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



ALTER TABLE "public"."recetas" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "recetas_delete" ON "public"."recetas" FOR DELETE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "recetas_insert" ON "public"."recetas" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "recetas_select" ON "public"."recetas" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "recetas_update" ON "public"."recetas" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"())) WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



ALTER TABLE "public"."record_condicion" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "record_condicion_delete" ON "public"."record_condicion" FOR DELETE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "record_condicion_insert" ON "public"."record_condicion" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "record_condicion_select" ON "public"."record_condicion" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "record_condicion_update" ON "public"."record_condicion" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"())) WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "record_delete" ON "public"."records" FOR DELETE TO "authenticated" USING ("public"."es_admin"());



CREATE POLICY "record_insert" ON "public"."records" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "record_select" ON "public"."records" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "record_update" ON "public"."records" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



ALTER TABLE "public"."records" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."superficies" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "superficies_delete" ON "public"."superficies" FOR DELETE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "superficies_insert" ON "public"."superficies" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "superficies_select" ON "public"."superficies" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



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


CREATE POLICY "tratamientos_aplicados_delete" ON "public"."tratamientos_aplicados" FOR DELETE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "tratamientos_aplicados_insert" ON "public"."tratamientos_aplicados" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "tratamientos_aplicados_select" ON "public"."tratamientos_aplicados" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "tratamientos_aplicados_update" ON "public"."tratamientos_aplicados" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"())) WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "tratamientos_delete" ON "public"."tratamientos" FOR DELETE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "tratamientos_insert" ON "public"."tratamientos" FOR INSERT TO "authenticated" WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "tratamientos_select" ON "public"."tratamientos" FOR SELECT TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"()));



CREATE POLICY "tratamientos_update" ON "public"."tratamientos" FOR UPDATE TO "authenticated" USING (("public"."es_admin"() OR "public"."es_doctor"())) WITH CHECK (("public"."es_admin"() OR "public"."es_doctor"()));



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






















































































































































GRANT ALL ON FUNCTION "public"."actualizar_stock_por_compra"() TO "anon";
GRANT ALL ON FUNCTION "public"."actualizar_stock_por_compra"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."actualizar_stock_por_compra"() TO "service_role";



GRANT ALL ON FUNCTION "public"."ajustar_stock_consumible"("p_consumible_id" "uuid", "p_nuevo_stock" integer, "p_motivo" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."ajustar_stock_consumible"("p_consumible_id" "uuid", "p_nuevo_stock" integer, "p_motivo" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ajustar_stock_consumible"("p_consumible_id" "uuid", "p_nuevo_stock" integer, "p_motivo" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."cancelar_citas_paciente_inactivo"() TO "anon";
GRANT ALL ON FUNCTION "public"."cancelar_citas_paciente_inactivo"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."cancelar_citas_paciente_inactivo"() TO "service_role";



GRANT ALL ON FUNCTION "public"."crear_consulta_completa"("p_paciente_id" "uuid", "p_doctor_id" "uuid", "p_cita_id" "uuid", "p_fecha" timestamp with time zone, "p_motivo_consulta" "text", "p_temp_condiciones" "jsonb", "p_dientes" "jsonb", "p_documentos" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."crear_consulta_completa"("p_paciente_id" "uuid", "p_doctor_id" "uuid", "p_cita_id" "uuid", "p_fecha" timestamp with time zone, "p_motivo_consulta" "text", "p_temp_condiciones" "jsonb", "p_dientes" "jsonb", "p_documentos" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."crear_consulta_completa"("p_paciente_id" "uuid", "p_doctor_id" "uuid", "p_cita_id" "uuid", "p_fecha" timestamp with time zone, "p_motivo_consulta" "text", "p_temp_condiciones" "jsonb", "p_dientes" "jsonb", "p_documentos" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."es_admin"() TO "anon";
GRANT ALL ON FUNCTION "public"."es_admin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."es_admin"() TO "service_role";



GRANT ALL ON FUNCTION "public"."es_asistente"() TO "anon";
GRANT ALL ON FUNCTION "public"."es_asistente"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."es_asistente"() TO "service_role";



GRANT ALL ON FUNCTION "public"."es_doctor"() TO "anon";
GRANT ALL ON FUNCTION "public"."es_doctor"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."es_doctor"() TO "service_role";



GRANT ALL ON FUNCTION "public"."finalizar_consulta"("p_consulta_id" "uuid", "p_metodo_pago" "text", "p_nota" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."finalizar_consulta"("p_consulta_id" "uuid", "p_metodo_pago" "text", "p_nota" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."finalizar_consulta"("p_consulta_id" "uuid", "p_metodo_pago" "text", "p_nota" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_aplicar_movimiento_stock"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_aplicar_movimiento_stock"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_aplicar_movimiento_stock"() TO "service_role";



GRANT ALL ON FUNCTION "public"."generar_plan_cuotas"("p_cuenta_id" "uuid", "p_cuotas" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."generar_plan_cuotas"("p_cuenta_id" "uuid", "p_cuotas" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."generar_plan_cuotas"("p_cuenta_id" "uuid", "p_cuotas" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."limpiar_diagnosticos_superficie"() TO "anon";
GRANT ALL ON FUNCTION "public"."limpiar_diagnosticos_superficie"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."limpiar_diagnosticos_superficie"() TO "service_role";



GRANT ALL ON FUNCTION "public"."manejar_cita_cancelada"() TO "anon";
GRANT ALL ON FUNCTION "public"."manejar_cita_cancelada"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."manejar_cita_cancelada"() TO "service_role";



GRANT ALL ON FUNCTION "public"."marcar_cuotas_vencidas"("p_cuenta_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."marcar_cuotas_vencidas"("p_cuenta_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."marcar_cuotas_vencidas"("p_cuenta_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."recibir_compra"("p_compra_id" "uuid", "p_usuario_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."recibir_compra"("p_compra_id" "uuid", "p_usuario_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."recibir_compra"("p_compra_id" "uuid", "p_usuario_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."registrar_pago"("p_cuenta_id" "uuid", "p_monto" numeric, "p_metodo_pago" "text", "p_cuota_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."registrar_pago"("p_cuenta_id" "uuid", "p_monto" numeric, "p_metodo_pago" "text", "p_cuota_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."registrar_pago"("p_cuenta_id" "uuid", "p_monto" numeric, "p_metodo_pago" "text", "p_cuota_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."registrar_pago_en_caja"() TO "anon";
GRANT ALL ON FUNCTION "public"."registrar_pago_en_caja"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."registrar_pago_en_caja"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_disponibilidad_doctor"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_disponibilidad_doctor"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_disponibilidad_doctor"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_modified_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_modified_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_modified_column"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_timestamp"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_timestamp"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_timestamp"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validar_caja_abierta"() TO "anon";
GRANT ALL ON FUNCTION "public"."validar_caja_abierta"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validar_caja_abierta"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validar_disponibilidad_doctor_simple"() TO "anon";
GRANT ALL ON FUNCTION "public"."validar_disponibilidad_doctor_simple"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validar_disponibilidad_doctor_simple"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validar_doctor_activo"() TO "anon";
GRANT ALL ON FUNCTION "public"."validar_doctor_activo"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validar_doctor_activo"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validar_fecha_nacimiento"() TO "anon";
GRANT ALL ON FUNCTION "public"."validar_fecha_nacimiento"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validar_fecha_nacimiento"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validar_monto_cuotas"() TO "anon";
GRANT ALL ON FUNCTION "public"."validar_monto_cuotas"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validar_monto_cuotas"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validar_monto_pago"() TO "anon";
GRANT ALL ON FUNCTION "public"."validar_monto_pago"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validar_monto_pago"() TO "service_role";



GRANT ALL ON FUNCTION "public"."verificar_item_plan_ejecutable"() TO "anon";
GRANT ALL ON FUNCTION "public"."verificar_item_plan_ejecutable"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."verificar_item_plan_ejecutable"() TO "service_role";


















GRANT ALL ON TABLE "public"."admins" TO "anon";
GRANT ALL ON TABLE "public"."admins" TO "authenticated";
GRANT ALL ON TABLE "public"."admins" TO "service_role";



GRANT ALL ON TABLE "public"."asistentes" TO "anon";
GRANT ALL ON TABLE "public"."asistentes" TO "authenticated";
GRANT ALL ON TABLE "public"."asistentes" TO "service_role";



GRANT ALL ON TABLE "public"."cajas" TO "anon";
GRANT ALL ON TABLE "public"."cajas" TO "authenticated";
GRANT ALL ON TABLE "public"."cajas" TO "service_role";



GRANT ALL ON TABLE "public"."cajas_diarias" TO "anon";
GRANT ALL ON TABLE "public"."cajas_diarias" TO "authenticated";
GRANT ALL ON TABLE "public"."cajas_diarias" TO "service_role";



GRANT ALL ON TABLE "public"."citas" TO "anon";
GRANT ALL ON TABLE "public"."citas" TO "authenticated";
GRANT ALL ON TABLE "public"."citas" TO "service_role";



GRANT ALL ON TABLE "public"."compras" TO "anon";
GRANT ALL ON TABLE "public"."compras" TO "authenticated";
GRANT ALL ON TABLE "public"."compras" TO "service_role";



GRANT ALL ON TABLE "public"."condiciones" TO "anon";
GRANT ALL ON TABLE "public"."condiciones" TO "authenticated";
GRANT ALL ON TABLE "public"."condiciones" TO "service_role";



GRANT ALL ON TABLE "public"."consultas" TO "anon";
GRANT ALL ON TABLE "public"."consultas" TO "authenticated";
GRANT ALL ON TABLE "public"."consultas" TO "service_role";



GRANT ALL ON TABLE "public"."consulta_resumen" TO "anon";
GRANT ALL ON TABLE "public"."consulta_resumen" TO "authenticated";
GRANT ALL ON TABLE "public"."consulta_resumen" TO "service_role";



GRANT ALL ON TABLE "public"."consumibles" TO "anon";
GRANT ALL ON TABLE "public"."consumibles" TO "authenticated";
GRANT ALL ON TABLE "public"."consumibles" TO "service_role";



GRANT ALL ON TABLE "public"."consumibles_compras" TO "anon";
GRANT ALL ON TABLE "public"."consumibles_compras" TO "authenticated";
GRANT ALL ON TABLE "public"."consumibles_compras" TO "service_role";



GRANT ALL ON TABLE "public"."contactos" TO "anon";
GRANT ALL ON TABLE "public"."contactos" TO "authenticated";
GRANT ALL ON TABLE "public"."contactos" TO "service_role";



GRANT ALL ON TABLE "public"."contraindicaciones" TO "anon";
GRANT ALL ON TABLE "public"."contraindicaciones" TO "authenticated";
GRANT ALL ON TABLE "public"."contraindicaciones" TO "service_role";



GRANT ALL ON TABLE "public"."cuentas" TO "anon";
GRANT ALL ON TABLE "public"."cuentas" TO "authenticated";
GRANT ALL ON TABLE "public"."cuentas" TO "service_role";



GRANT ALL ON TABLE "public"."cuotas" TO "anon";
GRANT ALL ON TABLE "public"."cuotas" TO "authenticated";
GRANT ALL ON TABLE "public"."cuotas" TO "service_role";



GRANT ALL ON TABLE "public"."diagnosticos" TO "anon";
GRANT ALL ON TABLE "public"."diagnosticos" TO "authenticated";
GRANT ALL ON TABLE "public"."diagnosticos" TO "service_role";



GRANT ALL ON TABLE "public"."diagnosticos_aplicados" TO "anon";
GRANT ALL ON TABLE "public"."diagnosticos_aplicados" TO "authenticated";
GRANT ALL ON TABLE "public"."diagnosticos_aplicados" TO "service_role";



GRANT ALL ON TABLE "public"."dientes" TO "anon";
GRANT ALL ON TABLE "public"."dientes" TO "authenticated";
GRANT ALL ON TABLE "public"."dientes" TO "service_role";



GRANT ALL ON TABLE "public"."doctor_asistentes" TO "anon";
GRANT ALL ON TABLE "public"."doctor_asistentes" TO "authenticated";
GRANT ALL ON TABLE "public"."doctor_asistentes" TO "service_role";



GRANT ALL ON TABLE "public"."doctores" TO "anon";
GRANT ALL ON TABLE "public"."doctores" TO "authenticated";
GRANT ALL ON TABLE "public"."doctores" TO "service_role";



GRANT ALL ON TABLE "public"."documentos_clinicos" TO "anon";
GRANT ALL ON TABLE "public"."documentos_clinicos" TO "authenticated";
GRANT ALL ON TABLE "public"."documentos_clinicos" TO "service_role";



GRANT ALL ON TABLE "public"."equipos" TO "anon";
GRANT ALL ON TABLE "public"."equipos" TO "authenticated";
GRANT ALL ON TABLE "public"."equipos" TO "service_role";



GRANT ALL ON TABLE "public"."equipos_mantenimientos" TO "anon";
GRANT ALL ON TABLE "public"."equipos_mantenimientos" TO "authenticated";
GRANT ALL ON TABLE "public"."equipos_mantenimientos" TO "service_role";



GRANT ALL ON TABLE "public"."evaluaciones_clinicas" TO "anon";
GRANT ALL ON TABLE "public"."evaluaciones_clinicas" TO "authenticated";
GRANT ALL ON TABLE "public"."evaluaciones_clinicas" TO "service_role";



GRANT ALL ON TABLE "public"."items_cuenta" TO "anon";
GRANT ALL ON TABLE "public"."items_cuenta" TO "authenticated";
GRANT ALL ON TABLE "public"."items_cuenta" TO "service_role";



GRANT ALL ON TABLE "public"."items_plan_tratamiento" TO "anon";
GRANT ALL ON TABLE "public"."items_plan_tratamiento" TO "authenticated";
GRANT ALL ON TABLE "public"."items_plan_tratamiento" TO "service_role";



GRANT ALL ON TABLE "public"."medicinas" TO "anon";
GRANT ALL ON TABLE "public"."medicinas" TO "authenticated";
GRANT ALL ON TABLE "public"."medicinas" TO "service_role";



GRANT ALL ON TABLE "public"."movimientos_caja" TO "anon";
GRANT ALL ON TABLE "public"."movimientos_caja" TO "authenticated";
GRANT ALL ON TABLE "public"."movimientos_caja" TO "service_role";



GRANT ALL ON TABLE "public"."movimientos_stock_consumible" TO "anon";
GRANT ALL ON TABLE "public"."movimientos_stock_consumible" TO "authenticated";
GRANT ALL ON TABLE "public"."movimientos_stock_consumible" TO "service_role";



GRANT ALL ON TABLE "public"."odontogramas" TO "anon";
GRANT ALL ON TABLE "public"."odontogramas" TO "authenticated";
GRANT ALL ON TABLE "public"."odontogramas" TO "service_role";



GRANT ALL ON TABLE "public"."ordenes_medicas" TO "anon";
GRANT ALL ON TABLE "public"."ordenes_medicas" TO "authenticated";
GRANT ALL ON TABLE "public"."ordenes_medicas" TO "service_role";



GRANT ALL ON TABLE "public"."pacientes" TO "anon";
GRANT ALL ON TABLE "public"."pacientes" TO "authenticated";
GRANT ALL ON TABLE "public"."pacientes" TO "service_role";



GRANT ALL ON TABLE "public"."pagos" TO "anon";
GRANT ALL ON TABLE "public"."pagos" TO "authenticated";
GRANT ALL ON TABLE "public"."pagos" TO "service_role";



GRANT ALL ON TABLE "public"."persona_contactos" TO "anon";
GRANT ALL ON TABLE "public"."persona_contactos" TO "authenticated";
GRANT ALL ON TABLE "public"."persona_contactos" TO "service_role";



GRANT ALL ON TABLE "public"."personas" TO "anon";
GRANT ALL ON TABLE "public"."personas" TO "authenticated";
GRANT ALL ON TABLE "public"."personas" TO "service_role";



GRANT ALL ON TABLE "public"."planes_tratamiento" TO "anon";
GRANT ALL ON TABLE "public"."planes_tratamiento" TO "authenticated";
GRANT ALL ON TABLE "public"."planes_tratamiento" TO "service_role";



GRANT ALL ON TABLE "public"."procedimientos" TO "anon";
GRANT ALL ON TABLE "public"."procedimientos" TO "authenticated";
GRANT ALL ON TABLE "public"."procedimientos" TO "service_role";



GRANT ALL ON TABLE "public"."recetas" TO "anon";
GRANT ALL ON TABLE "public"."recetas" TO "authenticated";
GRANT ALL ON TABLE "public"."recetas" TO "service_role";



GRANT ALL ON TABLE "public"."record_condicion" TO "anon";
GRANT ALL ON TABLE "public"."record_condicion" TO "authenticated";
GRANT ALL ON TABLE "public"."record_condicion" TO "service_role";



GRANT ALL ON TABLE "public"."records" TO "anon";
GRANT ALL ON TABLE "public"."records" TO "authenticated";
GRANT ALL ON TABLE "public"."records" TO "service_role";



GRANT ALL ON TABLE "public"."superficies" TO "anon";
GRANT ALL ON TABLE "public"."superficies" TO "authenticated";
GRANT ALL ON TABLE "public"."superficies" TO "service_role";



GRANT ALL ON TABLE "public"."suplidores" TO "anon";
GRANT ALL ON TABLE "public"."suplidores" TO "authenticated";
GRANT ALL ON TABLE "public"."suplidores" TO "service_role";



GRANT ALL ON TABLE "public"."suplidores_contactos" TO "anon";
GRANT ALL ON TABLE "public"."suplidores_contactos" TO "authenticated";
GRANT ALL ON TABLE "public"."suplidores_contactos" TO "service_role";



GRANT ALL ON TABLE "public"."tratamientos" TO "anon";
GRANT ALL ON TABLE "public"."tratamientos" TO "authenticated";
GRANT ALL ON TABLE "public"."tratamientos" TO "service_role";



GRANT ALL ON TABLE "public"."tratamientos_aplicados" TO "anon";
GRANT ALL ON TABLE "public"."tratamientos_aplicados" TO "authenticated";
GRANT ALL ON TABLE "public"."tratamientos_aplicados" TO "service_role";



GRANT ALL ON TABLE "public"."usuarios" TO "anon";
GRANT ALL ON TABLE "public"."usuarios" TO "authenticated";
GRANT ALL ON TABLE "public"."usuarios" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































