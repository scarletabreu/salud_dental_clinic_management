-- ============================================================================
--  SD-81 · Completar el enum estado_cita
--  Ejecuta este archivo en el SQL Editor de Supabase (una sola vez).
--
--  El enum original tenía 4 valores {pendiente, confirmada, atendida, cancelada}
--  con mapeos ad-hoc en Dart. Esta migración deja el enum 1:1 con el enum Dart
--  `EstadoCita` (7 valores en snake_case):
--    programada, confirmada, en_espera, en_consulta, completada, cancelada, no_asistio
--
--  Estrategia:
--    · RENAME de los valores heredados que cambian de nombre:
--        pendiente -> programada
--        atendida  -> completada
--      (RENAME VALUE actualiza filas y defaults existentes automáticamente.)
--    · ADD de los tres valores nuevos.
--
--  Nota: ALTER TYPE ... ADD VALUE no puede ejecutarse dentro de una transacción
--  junto con el uso del nuevo valor; por eso van como sentencias sueltas.
-- ============================================================================

alter type estado_cita rename value 'pendiente' to 'programada';
alter type estado_cita rename value 'atendida' to 'completada';

alter type estado_cita add value if not exists 'en_espera';
alter type estado_cita add value if not exists 'en_consulta';
alter type estado_cita add value if not exists 'no_asistio';
