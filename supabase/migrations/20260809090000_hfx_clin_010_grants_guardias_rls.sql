-- HFX-CLIN-010 · Devolver EXECUTE a las funciones-guardia de RLS de producción.
--
-- HFX-CLIN-001 revocó EXECUTE de todas las funciones de public a authenticated
-- y solo re-otorgó las que existen en la línea base del repositorio. La
-- instancia de producción trae una familia propia de guardias (puede_ver_paciente,
-- puede_ver_odontograma, ...) que sus policies y vistas sí usan; al quedarse sin
-- grant, cada SELECT sobre pacientes, dientes, cuentas o planes muere con
-- «permission denied for function ...».
--
-- Son todas SECURITY DEFINER con owner postgres: devolverles EXECUTE solo
-- permite evaluar la regla de visibilidad, no salta ninguna policy. El bloque
-- es condicional porque estas funciones no existen en la línea base local:
-- ahí la migración es un no-op.

do $$
declare
  guardia text;
begin
  foreach guardia in array array[
    'puede_ver_paciente',
    'puede_ver_odontograma',
    'puede_ver_diente',
    'puede_ver_cuenta',
    'puede_ver_plan',
    'puede_ver_evaluacion',
    'puede_ver_receta',
    'debe_ocultar_contacto_paciente'
  ] loop
    if exists (
      select 1
        from pg_proc p
        join pg_namespace n on n.oid = p.pronamespace
       where n.nspname = 'public'
         and p.proname = guardia
         and p.pronargs = 1
         and p.proargtypes[0] = 'uuid'::regtype
    ) then
      execute format(
        'grant execute on function public.%I(uuid) to authenticated, service_role',
        guardia
      );
    end if;
  end loop;
end;
$$;
