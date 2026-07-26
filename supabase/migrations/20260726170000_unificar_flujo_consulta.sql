-- Hotfix UX: el doctor diagnostica, planifica y ejecuta dentro de una misma
-- consulta. La vinculación con el plan sigue siendo auditable mediante
-- item_plan_id, pero una intervención agregada durante la sesión ya no exige
-- una explicación de texto por el mero hecho de no haber sido planificada.

alter table public.tratamientos_aplicados
  drop constraint if exists tratamientos_origen_ejecucion_requerido;

comment on column public.tratamientos_aplicados.justificacion_no_planificada is
  'Motivo clínico opcional para una ejecución sin item_plan_id.';

notify pgrst, 'reload schema';
