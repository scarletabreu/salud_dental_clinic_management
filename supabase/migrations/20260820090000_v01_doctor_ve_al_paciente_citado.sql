-- V-01 · El doctor no podía abrir la consulta de un paciente que nunca atendió.
--
-- Lo que se veía: la doctora registra la llegada, pulsa «Iniciar consulta» y la
-- pantalla queda en un indicador de carga permanente, sin un solo texto, sin
-- mensaje de error y sin salida. No había forma de atender a ese paciente.
--
-- La cadena que lo producía se muerde la cola:
--
--   1. `pacientes_select` exige `puede_ver_paciente(id)`, que para un doctor no
--      admin pedía una fila activa en `doctor_paciente`.
--   2. Esa fila sólo la crea `fn_autoasignar_doctor_paciente`, trigger
--      AFTER INSERT de `consultas`. Antes de la primera consulta no existe.
--   3. `EfectuarConsultaPage` lee `pacientes` ANTES de crear la consulta
--      (`esPersonaSinFichaClinica`). La RLS devuelve vacío, el cliente concluye
--      «esta persona no tiene ficha clínica» y entra en la rama que pinta un
--      `CircularProgressIndicator` y nada más.
--
-- La regla que faltaba es la del propio negocio: **un doctor ve a los pacientes
-- que tiene citados**. Sin esa cita no ve nada; con ella puede abrir el
-- expediente y atender, que es exactamente para lo que se agendó.
--
-- Esto no amplía lo alcanzable. `citas_insert` ya deja a un doctor agendarse
-- una cita consigo mismo (`doctor_id = auth.uid()`), y al iniciar la consulta
-- el trigger de autoasignación le daba acceso igual. Lo único que cambia es que
-- deja de existir el estado intermedio en el que la interfaz es inservible.

begin;

-- `doctor_paciente` sólo existe en producción (drift versionado en
-- HFX-CLIN-011): en la línea base local la función se crea pero ninguna policy
-- la invoca. Igual que allí, el cuerpo no se valida al crearla.
set check_function_bodies = off;

create or replace function public.puede_ver_paciente(p_paciente_id uuid)
returns boolean
    language sql stable security definer
    set search_path to 'public'
    as $$
    SELECT
        es_asistente()
        OR (
            es_doctor_no_admin() AND (
                EXISTS (
                    SELECT 1 FROM doctor_paciente dp
                    WHERE dp.paciente_id = p_paciente_id
                      AND dp.doctor_id = auth.uid()
                      AND dp.activo
                )
                -- V-01: la cita es la que autoriza el primer encuentro. Sin
                -- ella el doctor seguía sin ver al paciente y la consulta no
                -- se podía abrir nunca.
                OR EXISTS (
                    SELECT 1 FROM citas c
                    WHERE c.persona_id = p_paciente_id
                      AND c.doctor_id = auth.uid()
                      AND c.deleted_at IS NULL
                )
            )
        )
        OR (
            es_admin() AND NOT EXISTS (
                SELECT 1 FROM doctor_paciente dp
                JOIN admins a ON a.id = dp.doctor_id
                WHERE dp.paciente_id = p_paciente_id
                  AND dp.activo
                  AND dp.doctor_id <> auth.uid()
            )
        );
$$;

comment on function public.puede_ver_paciente(uuid) is
  'Regla de negocio: un doctor regular ve a los pacientes con asignación activa '
  'en doctor_paciente y a los que tiene citados (cita viva a su nombre); un '
  'admin ve todos los pacientes excepto los asignados activamente a OTRO admin; '
  'un asistente ve todos. Reutilizar esta función en toda policy que filtre por '
  'paciente_id.';

commit;
