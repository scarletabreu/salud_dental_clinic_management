-- ============================================================================
-- SD-83 · Consultas en curso
-- Ejecuta este archivo una vez en Supabase SQL Editor.
-- ============================================================================

alter table consultas
add column if not exists finalizada boolean not null default false;

update consultas
set finalizada = coalesce(finalizada, false)
where finalizada is null;
