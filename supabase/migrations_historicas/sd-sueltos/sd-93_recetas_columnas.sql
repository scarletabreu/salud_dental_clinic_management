-- ============================================================================
--  SD-93 · Columnas faltantes en `recetas` para la persistencia desde consulta
--  Ejecuta este archivo en el SQL Editor de Supabase (una sola vez).
--
--  La tabla `recetas` fue creada con un schema mínimo. SD-92 y SD-93 añadieron
--  el flujo de recetas dentro de la consulta, que requiere tres columnas nuevas:
--    · title       → nombre/título de la receta (p. ej. "Amoxicilina 500mg")
--    · paciente_id → FK al paciente, necesaria para el historial de recetas
--    · consulta_id → FK a la consulta que originó la receta (nullable: recetas
--                    creadas fuera de una consulta no tienen consulta_id)
--
--  Todas las operaciones son ADD COLUMN IF NOT EXISTS (aditivas/idempotentes).
-- ============================================================================

alter table recetas
  add column if not exists title       text,
  add column if not exists paciente_id uuid references personas(id),
  add column if not exists consulta_id uuid references consultas(id);
