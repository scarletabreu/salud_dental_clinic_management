-- ============================================================================
--  SD-54 · Efectuar Consulta
--  Ejecuta este archivo en el SQL Editor de Supabase (una sola vez).
--
--  Crea:
--    1. La función RPC `crear_consulta_completa` (transaccional/atómica): inserta
--       la consulta, su odontograma (1:1), los 32 dientes (FDI 11-48) con sus
--       superficies y los documentos clínicos en UNA sola transacción. Si algo
--       falla (p. ej. pérdida de conexión) NO quedan registros huérfanos.
--    2. El bucket público `documentos-clinicos` y sus políticas para subir
--       radiografías.
--
--  Supuestos sobre el esquema (ajusta si difiere):
--    · Las PK `id` tienen DEFAULT gen_random_uuid().
--    · consultas.temp_condiciones es jsonb.
--    · superficies.tratamientos es jsonb (default '[]').
-- ============================================================================

create or replace function crear_consulta_completa(
  p_paciente_id     uuid,
  p_doctor_id       uuid,
  p_cita_id         uuid,
  p_fecha           timestamptz,
  p_motivo_consulta text,
  p_temp_condiciones jsonb,
  p_dientes         jsonb,
  p_documentos      jsonb
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
    p_motivo_consulta, coalesce(p_temp_condiciones, '[]'::jsonb), now(), now()
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
      odontograma_id, fdi_code, esta_ausente, created_at, updated_at
    )
    values (
      v_odontograma_id, (v_diente ->> 'fdi_code')::int, false, now(), now()
    )
    returning id into v_diente_id;

    for v_superficie in select * from jsonb_array_elements(v_diente -> 'superficies')
    loop
      insert into superficies (
        diente_id, tipo_superficie, tratamientos, created_at, updated_at
      )
      values (
        v_diente_id, v_superficie #>> '{}', '[]'::jsonb, now(), now()
      );
    end loop;
  end loop;

  -- 4. Documentos clínicos (radiografías ya subidas a Storage)
  if p_documentos is not null then
    for v_doc in select * from jsonb_array_elements(p_documentos)
    loop
      insert into documentos_clinicos (
        paciente_id, consulta_id, descripcion, tipo_documento,
        url_archivo, fecha_creacion, created_at, updated_at
      )
      values (
        p_paciente_id,
        v_consulta_id,
        v_doc ->> 'descripcion',
        v_doc ->> 'tipo_documento',
        v_doc ->> 'url_archivo',
        (v_doc ->> 'fecha_creacion')::timestamptz,
        now(), now()
      );
    end loop;
  end if;

  return v_consulta_id;
end;
$$;

grant execute on function crear_consulta_completa(
  uuid, uuid, uuid, timestamptz, text, jsonb, jsonb, jsonb
) to authenticated, anon;

-- ============================================================================
--  Storage: bucket + políticas para radiografías
-- ============================================================================

insert into storage.buckets (id, name, public)
values ('documentos-clinicos', 'documentos-clinicos', true)
on conflict (id) do nothing;

create policy "documentos_clinicos_insert"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'documentos-clinicos');

create policy "documentos_clinicos_select"
  on storage.objects for select to public
  using (bucket_id = 'documentos-clinicos');
