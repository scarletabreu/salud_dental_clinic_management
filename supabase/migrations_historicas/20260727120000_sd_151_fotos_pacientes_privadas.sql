-- SD-151: la imagen es información personal. Solo se guarda su referencia,
-- nunca el binario ni una URL pública persistente.
alter table public.pacientes
  add column if not exists foto_ruta text,
  add column if not exists foto_mime_type text,
  add column if not exists foto_tamano_bytes integer,
  add column if not exists foto_actualizada_en timestamptz;

alter table public.pacientes
  drop constraint if exists pacientes_foto_mime_type_check,
  add constraint pacientes_foto_mime_type_check
    check (foto_mime_type is null or foto_mime_type = 'image/jpeg'),
  drop constraint if exists pacientes_foto_tamano_bytes_check,
  add constraint pacientes_foto_tamano_bytes_check
    check (foto_tamano_bytes is null or foto_tamano_bytes between 1 and 2097152);

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
