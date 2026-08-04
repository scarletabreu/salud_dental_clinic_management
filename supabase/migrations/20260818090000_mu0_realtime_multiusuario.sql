-- ============================================================================
--  MU-0 · Cimientos multiusuario: publicación realtime por dominio.
--
--  Con 3-4 sesiones simultáneas (admin, doctor, asistente) las pantallas
--  deben enterarse de lo que hacen los demás. Hasta hoy la publicación
--  `supabase_realtime` sólo contenía `movimientos_caja`; todo lo demás se
--  cargaba una vez al montar y quedaba congelado.
--
--  Se publican las tablas que alimentan los dos mecanismos del plan
--  multiusuario:
--    · stream vivo (mecanismo A): citas, cajas, cuentas
--    · señal de invalidación (mecanismo B): personas, pacientes,
--      consumibles, doctor_asistentes, reglas_clinicas
--
--  El recorte por rol NO se hace aquí: Realtime aplica las policies RLS de
--  cada tabla (`citas_select` de d11 ya limita admin/doctor/asistente), así
--  que cada sesión recibe sólo los eventos que su rol puede leer.
--
--  Deliberadamente fuera:
--    · `usuarios`: tiene grants de columna que ya han mordido (HFX-CLIN-010)
--      y realtime entrega filas completas; los cambios de rol viajan por el
--      refresh de token (~1 h), no por eventos.
--    · `REPLICA IDENTITY`: no se toca. Los borrados del dominio son soft
--      (estados, `deleted_at`, `estatus`), el default (clave primaria en
--      eventos DELETE) alcanza.
--
--  Idempotente: `alter publication ... add table` no admite `if not exists`,
--  se usa el guard de `pg_publication_tables` que ya estableció
--  `20260725000100_linea_base_objetos_no_public.sql`.
-- ============================================================================

do $$
declare
  v_tabla text;
begin
  foreach v_tabla in array array[
    'cajas',
    'citas',
    'cuentas',
    'personas',
    'pacientes',
    'consumibles',
    'doctor_asistentes',
    'reglas_clinicas'
  ] loop
    if not exists (
      select 1 from pg_publication_tables
       where pubname = 'supabase_realtime'
         and schemaname = 'public'
         and tablename = v_tabla
    ) then
      execute format(
        'alter publication supabase_realtime add table public.%I', v_tabla
      );
    end if;
  end loop;
end;
$$;
