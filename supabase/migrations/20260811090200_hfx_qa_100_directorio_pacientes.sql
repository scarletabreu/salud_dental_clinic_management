-- HFX-QA-100 · Directorio mínimo de pacientes para resolver nombres.
--
-- Por qué hace falta. Al adoptar el modelo de producción, `pacientes_select` y
-- `persona_select` pasan por `puede_ver_paciente()`: un doctor regular sólo lee
-- la ficha de los pacientes con asignación activa en `doctor_paciente`. Eso es
-- lo que se quiere para los datos clínicos y de contacto. Pero los listados
-- necesitan poner un **nombre** en filas que el rol sí tiene derecho a ver por
-- otra vía —la decisión D11 deja al doctor ver todas las consultas—, y sin esta
-- vista esas filas volverían a pintar `Paciente #uuid` (defecto D4).
--
-- Es la versión bien hecha de lo que `pacientes_seguro` intentaba ser: expone
-- exactamente tres campos, ningún dato clínico, ningún dato de contacto, ni
-- cédula, ni fecha de nacimiento.
--
-- Patrón SD-146: vista sin `security_invoker`, propiedad de `postgres`, de modo
-- que atraviesa el RLS de `personas`/`pacientes`; el control de acceso lo pone
-- la propia vista, que sólo devuelve filas a personal clínico autenticado.
--
-- No filtra `deleted_at`: un paciente dado de baja debe seguir resolviendo su
-- nombre en el historial de consultas antiguas.

create or replace view public.directorio_pacientes as
  select
    p.id,
    per.nombre,
    per.apellido
  from public.pacientes p
  join public.personas per on per.id = p.id
  where public.es_admin() or public.es_doctor() or public.es_asistente();

comment on view public.directorio_pacientes is
  'Directorio de nombres de pacientes, legible por todo el personal clínico autenticado. Existe para que los listados (consultas, agenda) puedan mostrar un nombre en filas cuyo paciente el rol no tiene derecho a abrir por completo. Sin datos clínicos ni de contacto: la ficha sigue gobernada por puede_ver_paciente().';

revoke all on table public.directorio_pacientes from anon;
grant select on table public.directorio_pacientes to authenticated;
grant all    on table public.directorio_pacientes to service_role;

notify pgrst, 'reload schema';
