-- ============================================================================
--  Línea base: objetos fuera del esquema `public` (HFX-CLIN-000).
--
--  Un `supabase db dump` sólo trae `public`. Todo lo que vive en `storage`,
--  en la publicación de realtime o en `auth` quedaba fuera del repositorio y
--  sólo existía en la instancia: una base reconstruida se quedaba sin bucket
--  de documentos, sin bucket de fotos y sin realtime en caja.
--
--  Recoge lo que hasta hoy aportaban `crear_consulta_completa.sql` (nunca
--  aplicado por el CLI: su nombre no cumple la convención de timestamp),
--  `20260721110000_sd_112_caja_diaria.sql` y
--  `20260727120000_sd_151_fotos_pacientes_privadas.sql`.
--
--  Es idempotente: se puede reaplicar sobre una instancia que ya lo tenga.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Realtime: la pantalla de caja se refresca sola con los movimientos del día.
-- `alter publication ... add table` no admite `if not exists`.
-- ---------------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
     where pubname = 'supabase_realtime'
       and schemaname = 'public'
       and tablename = 'movimientos_caja'
  ) then
    alter publication supabase_realtime add table public.movimientos_caja;
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Storage · documentos clínicos adjuntos a una consulta.
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('documentos-clinicos', 'documentos-clinicos', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "documentos_clinicos_insert" on storage.objects;
create policy "documentos_clinicos_insert"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'documentos-clinicos');

drop policy if exists "documentos_clinicos_select" on storage.objects;
create policy "documentos_clinicos_select"
  on storage.objects for select to public
  using (bucket_id = 'documentos-clinicos');

-- ---------------------------------------------------------------------------
-- Storage · foto del paciente (SD-151). Bucket privado: la imagen es
-- información personal y sólo se sirve por URL firmada.
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('fotos-pacientes', 'fotos-pacientes', false)
on conflict (id) do update set public = false;

drop policy if exists fotos_pacientes_select on storage.objects;
create policy fotos_pacientes_select on storage.objects for select to authenticated
using (
  bucket_id = 'fotos-pacientes'
  and (public.es_admin() or public.es_doctor() or public.es_asistente())
  and exists (
    select 1 from public.pacientes p
    where p.id::text = (storage.foldername(name))[1] and p.deleted_at is null
  )
);

drop policy if exists fotos_pacientes_insert on storage.objects;
create policy fotos_pacientes_insert on storage.objects for insert to authenticated
with check (
  bucket_id = 'fotos-pacientes'
  and (public.es_admin() or public.es_doctor() or public.es_asistente())
  and exists (
    select 1 from public.pacientes p
    where p.id::text = (storage.foldername(name))[1] and p.deleted_at is null
  )
);

drop policy if exists fotos_pacientes_update on storage.objects;
create policy fotos_pacientes_update on storage.objects for update to authenticated
using (
  bucket_id = 'fotos-pacientes'
  and (public.es_admin() or public.es_doctor() or public.es_asistente())
  and exists (
    select 1 from public.pacientes p
    where p.id::text = (storage.foldername(name))[1] and p.deleted_at is null
  )
)
with check (
  bucket_id = 'fotos-pacientes'
  and (public.es_admin() or public.es_doctor() or public.es_asistente())
  and exists (
    select 1 from public.pacientes p
    where p.id::text = (storage.foldername(name))[1] and p.deleted_at is null
  )
);

drop policy if exists fotos_pacientes_delete on storage.objects;
create policy fotos_pacientes_delete on storage.objects for delete to authenticated
using (
  bucket_id = 'fotos-pacientes'
  and (public.es_admin() or public.es_doctor() or public.es_asistente())
  and exists (
    select 1 from public.pacientes p
    where p.id::text = (storage.foldername(name))[1] and p.deleted_at is null
  )
);
