-- ============================================================================
--  SD-82 · Signos Vitales en Consulta
--  Ejecutar UNA SOLA VEZ en el SQL Editor de Supabase.
-- ============================================================================

ALTER TABLE consultas ADD COLUMN IF NOT EXISTS signos_vitales jsonb;
