-- ============================================================================
--  SD-91 · Historial del odontograma: construir desde consultas previas
--  Ejecuta este archivo en el SQL Editor de Supabase (una sola vez).
--
--  Objetivo:
--    Al iniciar una consulta, proyectamos los tratamientos aplicados de TODAS
--    las consultas anteriores del paciente sobre el odontograma nuevo (capa
--    "histórico"). La query parte de `tratamientos_aplicados` y une:
--      · consultas (inner)  → filtra por paciente_id
--      · dientes   (inner)  → trae fdi_code para ubicar el tratamiento
--
--  Índices:
--    · tratamientos_aplicados.consulta_id  → YA EXISTE (idx_..._consulta_id, SD-84)
--    · tratamientos_aplicados.diente_id    → YA EXISTE (idx_..._diente_id,   SD-84)
--    · consultas.paciente_id               → SE AGREGA AQUÍ. Sin él, el filtro
--      por paciente hace seq scan sobre `consultas`. También acelera el
--      historial clínico existente (fetchConsultasByPaciente).
-- ============================================================================

create index if not exists idx_consultas_paciente_id
  on consultas (paciente_id);
