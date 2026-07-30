-- ============================================================================
--  Motivo de la cita · citas.motivo
--  Ejecuta este archivo en el SQL Editor de Supabase (una sola vez).
--
--  Objetivo:
--    El diálogo de nueva cita pide "Motivo de Consulta" desde siempre, pero
--    `citas` no tenía dónde guardarlo: el texto se perdía al confirmar. Con
--    esta columna, lo que escribe quien agenda llega al odontólogo y prellena
--    el motivo de la consulta cuando la atiende desde esa cita.
--
--  Notas:
--    · Es `text` y nullable: las citas ya existentes no tienen motivo y una
--      cita puede agendarse sin él (el campo del formulario es opcional).
--    · No se toca `consultas.motivo_consulta`: son dos cosas distintas: lo que
--      el paciente dijo al agendar y lo que el odontólogo registra al evaluar.
--      El primero solo prellena al segundo, que sigue siendo editable.
-- ============================================================================

alter table "public"."citas"
  add column if not exists "motivo" text;

comment on column "public"."citas"."motivo" is
  'Motivo declarado al agendar la cita. Prellena consultas.motivo_consulta.';
