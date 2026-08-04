-- HFX-CLIN-008 · Un odontograma sin piezas hacía imposible trabajar la consulta
--
-- Síntoma: toda consulta abierta desde una cita respondía 400 a
-- `guardar_borrador_consulta` y a `cerrar_consulta` con
-- «La pieza N no pertenece al odontograma de la consulta …» (CL004). Nada del
-- trabajo clínico se podía guardar ni cerrar.
--
-- Causa: `crear_consulta_completa` materializa las piezas a partir de
-- `p_dientes`, que le llega desde el cliente. `iniciar_consulta_de_cita`
-- (HFX-CLIN-004) se añadió como camino nuevo, pero el cubit construye la
-- consulta inicial **sin odontograma**, así que envía `[]`: la consulta nacía
-- con odontograma y con cero dientes. La pantalla, en cambio, dibuja las 52
-- piezas en memoria, de modo que el odontograma se veía completo y cada
-- anotación se estrellaba contra una fila que no existía.
--
-- Por qué la certificación no lo vio: `abrir_consulta()` en
-- `hfx_clin_006_lib.sh` pasa `$DENTICION_FDI`, y el resto de las pruebas
-- insertan sus dientes a mano. El arnés hacía el trabajo que el cliente no
-- hace, así que las catorce jornadas ejercían un odontograma que en producción
-- nunca existía.
--
-- Corrección: la dentición completa deja de depender de lo que mande el
-- cliente. `crear_consulta_completa` completa las piezas que falten después de
-- aplicar `p_dientes`, de modo que la invariante «todo odontograma tiene sus 52
-- piezas» se cumple por construcción, venga la llamada de donde venga. Se
-- reparan además los odontogramas ya creados vacíos.

-- ---------------------------------------------------------------------------
-- 1. La dentición FDI como dato de la base
-- ---------------------------------------------------------------------------
-- Espejo de `lib/features/consulta/domain/usecases/dientes_iniciales.dart`.
-- La numeración FDI y el reparto de caras son norma internacional, no decisión
-- de producto: duplicarlos aquí es aceptable y es lo que permite que la base
-- garantice la invariante sin depender del cliente.

create or replace function public.hfx_clin_008_denticion_fdi()
returns table (fdi integer)
language sql
immutable
as $$
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

comment on function public.hfx_clin_008_denticion_fdi() is
  'HFX-CLIN-008. Las 52 piezas FDI (32 permanentes + 20 temporales).';

create or replace function public.hfx_clin_008_superficies_de(p_fdi integer)
returns public.tipo_superficie[]
language sql
immutable
as $$
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

comment on function public.hfx_clin_008_superficies_de(integer) is
  'HFX-CLIN-008. Caras que corresponden a una pieza según su código FDI.';

-- ---------------------------------------------------------------------------
-- 2. Completar las piezas que falten en un odontograma
-- ---------------------------------------------------------------------------
-- Idempotente a propósito: se puede llamar sobre un odontograma vacío, sobre
-- uno a medias o sobre uno completo. Nunca toca las piezas que ya existen, de
-- modo que no puede borrar un hallazgo.

create or replace function public.hfx_clin_008_completar_odontograma(
  p_odontograma_id uuid
) returns integer
language plpgsql
security definer
set search_path to 'public'
as $$
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

alter function public.hfx_clin_008_completar_odontograma(uuid) owner to postgres;

comment on function public.hfx_clin_008_completar_odontograma(uuid) is
  'HFX-CLIN-008. Materializa las piezas FDI que falten, con sus caras. Idempotente.';

-- No se expone por PostgREST: es una pieza interna de `crear_consulta_completa`.
revoke all on function public.hfx_clin_008_completar_odontograma(uuid) from public;
revoke all on function public.hfx_clin_008_completar_odontograma(uuid) from anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3. La creación de la consulta garantiza la dentición
-- ---------------------------------------------------------------------------
-- `crear_consulta_completa` tiene dos envoltorios —el de 9 argumentos fija el
-- tipo de atención y el de 8 comprueba la cita— sobre un único cuerpo real,
-- `hfx_base_crear_consulta_completa`. La corrección va ahí, en el cuerpo, para
-- que valga por igual para todos los caminos.
--
-- Se conserva intacto el tratamiento de `p_dientes`, de modo que quien sí lo
-- manda —el arnés de certificación y `CrearConsultaUseCase`— sigue creando sus
-- piezas con las caras que describa el payload. Lo único nuevo es completar
-- después lo que falte.

create or replace function public.hfx_base_crear_consulta_completa(
  p_paciente_id      uuid,
  p_doctor_id        uuid,
  p_cita_id          uuid,
  p_fecha            timestamptz,
  p_motivo_consulta  text,
  p_temp_condiciones jsonb,
  p_dientes          jsonb,
  p_documentos       jsonb
) returns uuid
language plpgsql
security definer
as $$
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

alter function public.hfx_base_crear_consulta_completa(
  uuid, uuid, uuid, timestamptz, text, jsonb, jsonb, jsonb
) owner to postgres;

-- ---------------------------------------------------------------------------
-- 4. Reparar los odontogramas que ya nacieron incompletos
-- ---------------------------------------------------------------------------
-- Sólo añade piezas que faltan; ninguna anotación existente se toca. Se
-- excluyen las consultas ya finalizadas: su expediente está cerrado y añadirle
-- piezas en blanco no lo mejora, sólo lo reescribe.

do $$
declare
  v_odontograma uuid;
  v_reparados   integer := 0;
begin
  for v_odontograma in
    select o.id
      from odontogramas o
      join consultas c on c.id = o.consulta_id
     where o.deleted_at is null
       and c.deleted_at is null
       and not coalesce(c.finalizada, false)
       and (select count(*) from dientes d where d.odontograma_id = o.id) < 52
  loop
    perform public.hfx_clin_008_completar_odontograma(v_odontograma);
    v_reparados := v_reparados + 1;
  end loop;

  if v_reparados > 0 then
    raise notice 'HFX-CLIN-008: % odontograma(s) abierto(s) completados.', v_reparados;
  end if;
end;
$$;
