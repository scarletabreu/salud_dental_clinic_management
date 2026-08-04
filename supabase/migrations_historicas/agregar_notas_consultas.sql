-- ============================================================================
--  SD-54 · Notas clínicas de la consulta
--  Ejecuta este archivo en el SQL Editor de Supabase (una sola vez).
--
--  El workspace de "Efectuar consulta" guarda las notas clínicas al terminar;
--  esta columna no existía en el esquema original.
-- ============================================================================

alter table consultas add column if not exists notas text;
