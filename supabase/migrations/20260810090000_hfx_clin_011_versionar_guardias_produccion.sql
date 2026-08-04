-- HFX-CLIN-011 · Versionar las guardias RLS de producción.
--
-- Estas funciones nacieron a mano en la instancia remota (drift) y el repo
-- nunca las vio: por eso HFX-CLIN-001 no les devolvió el EXECUTE tras el
-- revoke en bloque y hubo que parchearlo en HFX-CLIN-010. Aquí quedan
-- registradas con la definición exacta de producción (dump del 1 ago 2026)
-- para que el próximo cambio masivo de permisos las tenga en cuenta.
--
-- `doctor_paciente` solo existe en producción: en la línea base local estas
-- funciones se crean pero ninguna policy las invoca, así que nunca se
-- ejecutan ahí. `check_function_bodies = off` (lo mismo que emite pg_dump)
-- evita que la validación del cuerpo falle donde la tabla no existe.

set check_function_bodies = off;

create or replace function public.es_doctor_no_admin() returns boolean
    language sql stable security definer
    set search_path to 'public'
    as $$
    SELECT es_doctor() AND NOT es_admin();
$$;

create or replace function public.puede_ver_paciente(p_paciente_id uuid) returns boolean
    language sql stable security definer
    set search_path to 'public'
    as $$
    SELECT
        es_asistente()
        OR (
            es_doctor_no_admin() AND EXISTS (
                SELECT 1 FROM doctor_paciente dp
                WHERE dp.paciente_id = p_paciente_id
                  AND dp.doctor_id = auth.uid()
                  AND dp.activo
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
  'Regla de negocio: un doctor regular solo ve pacientes con asignación activa en doctor_paciente; un admin ve todos los pacientes excepto los asignados activamente a OTRO admin; un asistente ve todos. Reutilizar esta función en toda policy que filtre por paciente_id.';

create or replace function public.puede_ver_odontograma(p_odontograma_id uuid) returns boolean
    language sql stable security definer
    set search_path to 'public'
    as $$
    SELECT puede_ver_consulta(o.consulta_id) FROM odontogramas o WHERE o.id = p_odontograma_id;
$$;

comment on function public.puede_ver_odontograma(uuid) is
  'Encadena: odontograma -> consulta -> paciente.';

create or replace function public.puede_ver_diente(p_diente_id uuid) returns boolean
    language sql stable security definer
    set search_path to 'public'
    as $$
    SELECT puede_ver_odontograma(d.odontograma_id) FROM dientes d WHERE d.id = p_diente_id;
$$;

comment on function public.puede_ver_diente(uuid) is
  'Encadena: diente -> odontograma -> consulta -> paciente.';

create or replace function public.puede_ver_cuenta(p_cuenta_id uuid) returns boolean
    language sql stable security definer
    set search_path to 'public'
    as $$
    SELECT puede_ver_paciente(COALESCE(cu.paciente_id, c.paciente_id))
    FROM cuentas cu LEFT JOIN consultas c ON c.id = cu.consulta_id
    WHERE cu.id = p_cuenta_id;
$$;

create or replace function public.puede_ver_plan(p_plan_id uuid) returns boolean
    language sql stable security definer
    set search_path to 'public'
    as $$
    SELECT puede_ver_paciente(pt.paciente_id) FROM planes_tratamiento pt WHERE pt.id = p_plan_id;
$$;

create or replace function public.puede_ver_evaluacion(p_evaluacion_id uuid) returns boolean
    language sql stable security definer
    set search_path to 'public'
    as $$
    SELECT puede_ver_paciente(e.paciente_id) FROM evaluaciones_clinicas e WHERE e.id = p_evaluacion_id;
$$;

create or replace function public.puede_ver_receta(p_receta_id uuid) returns boolean
    language sql stable security definer
    set search_path to 'public'
    as $$
    SELECT puede_ver_paciente(COALESCE(r.paciente_id, c.paciente_id))
    FROM recetas r LEFT JOIN consultas c ON c.id = r.consulta_id
    WHERE r.id = p_receta_id;
$$;

create or replace function public.debe_ocultar_contacto_paciente(p_persona_id uuid) returns boolean
    language sql stable security definer
    set search_path to 'public'
    as $$
    SELECT
        es_doctor_no_admin()
        AND EXISTS (SELECT 1 FROM pacientes p WHERE p.id = p_persona_id);
$$;

reset check_function_bodies;

-- El mismo contrato de ejecución que dejó HFX-CLIN-010: las guardias las
-- evalúan las policies con el rol del llamante, así que authenticated
-- necesita EXECUTE. es_doctor_no_admin solo se invoca desde dentro de las
-- SECURITY DEFINER y queda reservada.
revoke execute on function public.es_doctor_no_admin() from public, anon, authenticated;
grant execute on function public.es_doctor_no_admin() to service_role;

grant execute on function public.puede_ver_paciente(uuid) to authenticated, service_role;
grant execute on function public.puede_ver_odontograma(uuid) to authenticated, service_role;
grant execute on function public.puede_ver_diente(uuid) to authenticated, service_role;
grant execute on function public.puede_ver_cuenta(uuid) to authenticated, service_role;
grant execute on function public.puede_ver_plan(uuid) to authenticated, service_role;
grant execute on function public.puede_ver_evaluacion(uuid) to authenticated, service_role;
grant execute on function public.puede_ver_receta(uuid) to authenticated, service_role;
grant execute on function public.debe_ocultar_contacto_paciente(uuid) to authenticated, service_role;
