-- SD-141 · Evaluación clínica desacoplada de la representación visual.
-- El JSON conserva estados dentales y tejidos blandos; dientes/superficies
-- continúan normalizados para tratamientos y facturación.
alter table public.odontogramas
  add column if not exists evaluacion_clinica jsonb not null
  default '{"hallazgos": {}, "tejidos_blandos": {}}'::jsonb;

comment on column public.odontogramas.evaluacion_clinica is
  'Hallazgos clínicos FDI y evaluación de tejidos blandos del odontograma.';
