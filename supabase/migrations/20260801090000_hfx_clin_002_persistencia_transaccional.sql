-- HFX-CLIN-002 · Persistencia y cierre clínico transaccional
--
-- El guardado clínico dejaba de ser una operación y pasaba a ser una lista de
-- llamadas independientes: actualizar consulta, borrar/insertar recetas,
-- reconciliar odontograma, marcar finalizada, descontar insumo por insumo y
-- finalmente crear la cuenta. Cualquier interrupción entre dos pasos producía
-- un estado clínico imposible: consulta cerrada con cita abierta, inventario
-- descontado sin cuenta, o una receta previa borrada por un insert fallido.
--
-- Esta migración crea dos operaciones y ninguna más:
--
--   * `guardar_borrador_consulta` — todo el borrador clínico en una
--     transacción, con versión optimista e identidad estable.
--   * `cerrar_consulta` — el cierre completo (borrador final, insumos, stock,
--     cuenta, receta emitida, cita y auditoría) en una transacción idempotente.
--
-- Códigos de error estables que la aplicación traduce a acciones:
--
--   CL001  conflicto de versión: otro actor guardó primero.
--   CL002  la consulta ya está finalizada.
--   CL003  stock insuficiente para el consumo declarado.
--   CL004  payload o recurso inválido.
--   CL005  intento de modificar una receta ya emitida.
--   42501  el actor no puede ejercer sobre esta consulta.

begin;

-- ---------------------------------------------------------------------------
-- 0. Default privileges: una función nueva no nace expuesta
-- ---------------------------------------------------------------------------
-- HFX-CLIN-001 cerró los defaults para `public` y `anon`, pero una función
-- creada por `postgres` seguía naciendo con EXECUTE para `authenticated`. Eso
-- publicaba automáticamente cada función interna nueva, incluidas las bases
-- que esta migración añade. A partir de aquí el acceso del cliente se concede
-- una por una.
alter default privileges for role postgres in schema public
  revoke execute on functions from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 1. Esquema: versión, cierre e idempotencia
-- ---------------------------------------------------------------------------

alter table public.consultas
  add column if not exists version integer not null default 1,
  add column if not exists finalizada_at timestamptz,
  add column if not exists cerrada_por uuid references public.doctores(id),
  add column if not exists cierre_key text;

comment on column public.consultas.version is
  'Versión optimista del borrador clínico. La incrementa cada guardado servidor.';
comment on column public.consultas.cierre_key is
  'Clave de idempotencia del intento de cierre que efectivamente cerró la consulta.';

-- Las consultas ya finalizadas antes de esta migración no tienen fecha de
-- cierre real; se usa su última actualización para no inventar un dato nuevo.
update public.consultas
   set finalizada_at = coalesce(updated_at, created_at, now())
 where coalesce(finalizada, false) and finalizada_at is null;

-- Una cita no puede tener dos consultas vigentes a la vez: es lo que permitía
-- que un doble clic abriera dos expedientes para la misma atención.
do $$
declare
  v_duplicadas text;
begin
  select string_agg(distinct cita_id::text, ', ')
    into v_duplicadas
    from (
      select cita_id
        from public.consultas
       where cita_id is not null
         and deleted_at is null
         and finalizada is not true
       group by cita_id
      having count(*) > 1
    ) d;

  if v_duplicadas is not null then
    raise exception
      'HFX-CLIN-002: hay citas con más de una consulta abierta (%). Cierra o elimina lógicamente las sobrantes antes de aplicar esta migración.',
      v_duplicadas
      using errcode = 'CL004';
  end if;
end;
$$;

create unique index if not exists consultas_cita_vigente_uk
  on public.consultas (cita_id)
  where cita_id is not null and deleted_at is null and finalizada is not true;

do $$
declare
  v_duplicadas text;
begin
  select string_agg(distinct consulta_id::text, ', ')
    into v_duplicadas
    from (
      select consulta_id
        from public.cuentas
       where deleted_at is null
       group by consulta_id
      having count(*) > 1
    ) d;

  if v_duplicadas is not null then
    raise exception
      'HFX-CLIN-002: hay consultas con más de una cuenta vigente (%). Consolida las cuentas antes de aplicar esta migración.',
      v_duplicadas
      using errcode = 'CL004';
  end if;
end;
$$;

create unique index if not exists cuentas_consulta_vigente_uk
  on public.cuentas (consulta_id)
  where deleted_at is null;

-- ---------------------------------------------------------------------------
-- 2. Consumo clínico: del formulario al ledger, sin perderse entre recargas
-- ---------------------------------------------------------------------------

-- Los insumos vivían solo en memoria del navegador: recargar la consulta los
-- perdía y el descuento ocurría fuera de la transacción de cierre.
create table if not exists public.consumos_consulta (
  id            uuid primary key default gen_random_uuid(),
  consulta_id   uuid not null references public.consultas(id) on delete cascade,
  consumible_id uuid not null references public.consumibles(id) on delete restrict,
  nombre        text,
  cantidad      integer not null check (cantidad > 0),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz
);

create unique index if not exists consumos_consulta_vigente_uk
  on public.consumos_consulta (consulta_id, consumible_id)
  where deleted_at is null;

create index if not exists consumos_consulta_consulta_idx
  on public.consumos_consulta (consulta_id)
  where deleted_at is null;

alter table public.consumos_consulta enable row level security;

drop policy if exists consumos_consulta_select on public.consumos_consulta;
create policy consumos_consulta_select on public.consumos_consulta
  for select to authenticated
  using (public.puede_ver_consulta(consulta_id));

-- La escritura pasa exclusivamente por las RPC de esta migración.
alter table public.movimientos_stock_consumible
  add column if not exists consulta_id uuid references public.consultas(id);

alter table public.movimientos_stock_consumible
  drop constraint if exists movimientos_stock_consumible_motivo_check;

alter table public.movimientos_stock_consumible
  add constraint movimientos_stock_consumible_motivo_check
  check (motivo in ('merma', 'correccion', 'usoInterno', 'consumoClinico'));

-- El ledger es la barrera real contra el doble descuento: un reintento del
-- cierre no puede insertar un segundo movimiento para el mismo consumible.
create unique index if not exists movimientos_stock_consumo_clinico_uk
  on public.movimientos_stock_consumible (consulta_id, consumible_id)
  where consulta_id is not null;

create index if not exists movimientos_stock_consulta_idx
  on public.movimientos_stock_consumible (consulta_id)
  where consulta_id is not null;

-- ---------------------------------------------------------------------------
-- 3. Recetas: borrador mutable, emisión inmutable
-- ---------------------------------------------------------------------------

alter table public.recetas
  add column if not exists version integer not null default 1,
  add column if not exists emitida_at timestamptz;

alter table public.recetas drop constraint if exists recetas_estado_check;

update public.recetas set estado = 'emitida' where estado = 'activa';
update public.recetas set estado = 'borrador' where estado is null;

update public.recetas
   set emitida_at = coalesce(fecha_emision, created_at)
 where estado in ('emitida', 'anulada', 'reemplazada') and emitida_at is null;

alter table public.recetas
  add constraint recetas_estado_check
  check (estado in ('borrador', 'emitida', 'anulada', 'reemplazada'));

alter table public.recetas alter column estado set default 'borrador';

comment on column public.recetas.version is
  'Versión de la receta. Permite detectar ediciones concurrentes del borrador.';

-- Una receta emitida es un documento clínico entregado al paciente: solo puede
-- anularse o reemplazarse, nunca reescribirse ni borrarse.
-- SECURITY DEFINER: el disparador consulta `es_contexto_interno()`, cuyo
-- EXECUTE HFX-CLIN-001 revocó a `authenticated`.
create or replace function public.hfx_clin_002_proteger_receta_emitida()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
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

alter function public.hfx_clin_002_proteger_receta_emitida() owner to postgres;

drop trigger if exists trg_proteger_receta_emitida on public.recetas;
create trigger trg_proteger_receta_emitida
  before update or delete on public.recetas
  for each row execute function public.hfx_clin_002_proteger_receta_emitida();

-- ---------------------------------------------------------------------------
-- 4. Auditoría clínica
-- ---------------------------------------------------------------------------

create table if not exists public.auditoria_clinica (
  id          uuid primary key default gen_random_uuid(),
  consulta_id uuid not null references public.consultas(id) on delete cascade,
  evento      text not null,
  actor_id    uuid,
  rol         text,
  metadata    jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now()
);

create index if not exists auditoria_clinica_consulta_idx
  on public.auditoria_clinica (consulta_id, created_at desc);

alter table public.auditoria_clinica enable row level security;

drop policy if exists auditoria_clinica_select on public.auditoria_clinica;
create policy auditoria_clinica_select on public.auditoria_clinica
  for select to authenticated
  using (public.puede_ver_consulta(consulta_id));

-- ---------------------------------------------------------------------------
-- 5. Autorización compartida por las dos operaciones
-- ---------------------------------------------------------------------------

-- Devuelve el actor clínico autorizado sobre la consulta, o falla. Mantiene la
-- excepción de contexto interno que HFX-CLIN-001 usa para migraciones y
-- pruebas ejecutadas como `postgres`/`service_role`.
create or replace function public.hfx_clin_002_actor_clinico(p_consulta_id uuid)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $$
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

alter function public.hfx_clin_002_actor_clinico(uuid) owner to postgres;

-- ---------------------------------------------------------------------------
-- 6. Aplicación del borrador clínico
-- ---------------------------------------------------------------------------

-- Reconcilia el payload versionado contra el estado persistido. El llamador ya
-- bloqueó la consulta y validó actor, estado y versión.
--
-- Contrato del payload (v1): una clave ausente no se toca; una clave presente
-- describe el conjunto completo deseado, y lo que desaparece se anula por
-- borrado lógico en vez de borrarse.
create or replace function public.hfx_clin_002_aplicar_borrador(
  p_consulta_id uuid,
  p_actor_id    uuid,
  p_payload     jsonb
) returns jsonb
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

alter function public.hfx_clin_002_aplicar_borrador(uuid, uuid, jsonb) owner to postgres;

-- ---------------------------------------------------------------------------
-- 7. RPC de borrador
-- ---------------------------------------------------------------------------

create or replace function public.guardar_borrador_consulta(
  p_consulta_id uuid,
  p_version     integer default null,
  p_payload     jsonb default '{}'::jsonb
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_actor_id  uuid;
  v_version   integer;
  v_finalizada boolean;
  v_resultado jsonb;
  v_actualizado timestamptz;
begin
  v_actor_id := public.hfx_clin_002_actor_clinico(p_consulta_id);

  -- Serializa los guardados concurrentes de la misma consulta.
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

  update consultas
     set version = version + 1, updated_at = now()
   where id = p_consulta_id
  returning version, updated_at into v_version, v_actualizado;

  return v_resultado || jsonb_build_object(
    'consulta_id', p_consulta_id,
    'version', v_version,
    'actualizado_en', v_actualizado,
    'finalizada', false
  );
end;
$$;

alter function public.guardar_borrador_consulta(uuid, integer, jsonb) owner to postgres;

-- ---------------------------------------------------------------------------
-- 8. RPC de cierre
-- ---------------------------------------------------------------------------

-- Devuelve el resultado consolidado de una consulta ya cerrada. Es lo que
-- recibe un reintento: la misma respuesta, sin repetir ningún efecto.
create or replace function public.hfx_clin_002_resultado_cierre(p_consulta_id uuid)
returns jsonb
language sql
security definer
set search_path to 'public'
as $$
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

alter function public.hfx_clin_002_resultado_cierre(uuid) owner to postgres;

-- Única operación de cierre: o queda todo confirmado, o no cambia nada.
create or replace function public.cerrar_consulta(
  p_consulta_id      uuid,
  p_version          integer default null,
  p_payload          jsonb default '{}'::jsonb,
  p_idempotencia_key text default null,
  p_metodo_pago      text default 'contado',
  p_nota             text default null
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
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
begin
  v_actor_id := public.hfx_clin_002_actor_clinico(p_consulta_id);

  select version, coalesce(finalizada, false), cita_id, cierre_key
    into v_version, v_finalizada, v_cita_id, v_cierre_key
    from consultas
   where id = p_consulta_id and deleted_at is null
     for update;

  -- Idempotencia: el mismo intento lógico devuelve el resultado existente.
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

  -- La cita se bloquea junto con la consulta: el cierre las mueve a la vez.
  if v_cita_id is not null then
    perform 1 from citas where id = v_cita_id for update;
  end if;

  -- 8.1 Último borrador dentro de la misma transacción del cierre.
  perform public.hfx_clin_002_aplicar_borrador(p_consulta_id, v_actor_id, p_payload);

  -- 8.2 Consumo de inventario: verificar antes de mover, y mover una sola vez.
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

  -- 8.3 Emisión de las recetas que quedaron en borrador con contenido.
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

  -- Un borrador vacío no se emite: no es un documento clínico.
  update recetas
     set deleted_at = now(), updated_at = now()
   where consulta_id = p_consulta_id
     and deleted_at is null
     and estado = 'borrador';

  -- 8.4 Cuenta, ítems de lo ejecutado y cierre de la cita.
  --
  -- Una evaluación sin ejecución no genera pre-factura: cobrar cero es ruido
  -- administrativo, y el plan propuesto o aceptado no factura por sí mismo.
  select count(*) into v_facturables
    from tratamientos_aplicados
   where consulta_id = p_consulta_id
     and deleted_at is null
     and coalesce(estado, 'aplicado') <> 'indicado';

  if v_facturables > 0 then
    v_cuenta_id := public.hfx_base_finalizar_consulta(p_consulta_id, p_metodo_pago, p_nota);
  elsif v_cita_id is not null then
    -- `hfx_base_finalizar_consulta` es quien cierra la cita; si no se invoca,
    -- el cierre igual tiene que dejarla completada.
    update citas
       set estado = 'completada'::estado_cita, updated_at = now()
     where id = v_cita_id
       and estado <> 'completada'::estado_cita
       and estado <> 'cancelada'::estado_cita;
  end if;

  -- 8.5 Cierre clínico.
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
      'idempotencia_key', p_idempotencia_key
    )
  );

  return public.hfx_clin_002_resultado_cierre(p_consulta_id);
end;
$$;

alter function public.cerrar_consulta(uuid, integer, jsonb, text, text, text) owner to postgres;

-- ---------------------------------------------------------------------------
-- 9. Grants: el contrato de HFX-CLIN-001 se mantiene
-- ---------------------------------------------------------------------------

revoke all on function public.hfx_clin_002_actor_clinico(uuid)
  from public, anon, authenticated;
revoke all on function public.hfx_clin_002_aplicar_borrador(uuid, uuid, jsonb)
  from public, anon, authenticated;
revoke all on function public.hfx_clin_002_resultado_cierre(uuid)
  from public, anon, authenticated;
revoke all on function public.hfx_clin_002_proteger_receta_emitida()
  from public, anon, authenticated;
revoke all on function public.guardar_borrador_consulta(uuid, integer, jsonb)
  from public, anon;
revoke all on function public.cerrar_consulta(uuid, integer, jsonb, text, text, text)
  from public, anon;

grant execute on function public.hfx_clin_002_actor_clinico(uuid) to service_role;
grant execute on function public.hfx_clin_002_aplicar_borrador(uuid, uuid, jsonb) to service_role;
grant execute on function public.hfx_clin_002_resultado_cierre(uuid) to service_role;
grant execute on function public.hfx_clin_002_proteger_receta_emitida() to service_role;

grant execute on function public.guardar_borrador_consulta(uuid, integer, jsonb)
  to authenticated, service_role;
grant execute on function public.cerrar_consulta(uuid, integer, jsonb, text, text, text)
  to authenticated, service_role;

grant select on public.consumos_consulta to authenticated, service_role;
grant select on public.auditoria_clinica to authenticated, service_role;
grant insert, update, delete on public.consumos_consulta to service_role;
grant insert on public.auditoria_clinica to service_role;

commit;
