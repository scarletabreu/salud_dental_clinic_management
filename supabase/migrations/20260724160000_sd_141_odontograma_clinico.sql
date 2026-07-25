-- SD-141 · Odontodiagrama del formulario físico.
--
-- La evaluación clínica (hallazgos por pieza FDI y tejidos blandos) vive en un
-- jsonb aparte: `dientes` y `superficies` siguen normalizados porque de ellos
-- cuelgan los tratamientos aplicados y la facturación, mientras que el
-- odontodiagrama es una anotación por consulta que no genera cargos.
--
-- Forma del documento:
--   {
--     "hallazgos": {
--       "16": [{"estado": "cariada", "superficies": ["oclusal", "mesial"]},
--              {"estado": "restaurada", "superficies": ["distal"]}],
--       "48": [{"estado": "extraccion_indicada"}]
--     },
--     "tejidos_blandos": {"lengua": "Úlcera en borde lateral izquierdo"}
--   }
--
-- `estado` usa las claves del papel: cariada, restaurada, extraccion_indicada,
-- perdida, pulpectomia_pulpotomia, no_erupcionado y otro. Una entrada sin
-- `superficies` afecta a la pieza completa.
--
-- Reversible con:
--   alter table public.odontogramas drop column evaluacion_clinica;
alter table public.odontogramas
  add column if not exists evaluacion_clinica jsonb not null
  default '{"hallazgos": {}, "tejidos_blandos": {}}'::jsonb;

comment on column public.odontogramas.evaluacion_clinica is
  'Odontodiagrama SD-141: hallazgos FDI por superficie y tejidos blandos.';
