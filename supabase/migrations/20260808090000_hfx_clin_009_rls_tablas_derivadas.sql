-- HFX-CLIN-009 · Tablas que sólo existen en producción y estaban sin RLS
--
-- Encontrado al verificar la instancia remota después de aplicar el programa
-- HFX-CLIN. El gate estructural de la certificación comprueba que ninguna tabla
-- de `public` quede sin RLS o sin políticas, pero lo hace **contra la base
-- local**: una tabla que sólo existe en producción es invisible para él.
--
-- Las dos que aparecieron:
--
--   · `auditoria_log` — no está en el repositorio; se creó a mano en el Studio.
--     Tenía RLS **desactivado** y `authenticated` con `select`. Guarda
--     `to_jsonb(OLD)` y `to_jsonb(NEW)` de cada fila auditada: 271 registros
--     con imágenes completas de `citas`, `consultas`, `cuentas` y `pagos`.
--     Cualquier usuario con sesión —una asistente, por ejemplo— podía leer el
--     detalle clínico y financiero entero por PostgREST. Es exactamente lo que
--     HFX-CLIN-001 y HFX-CLIN-005 cerraron en el resto del sistema.
--
--   · `items_receta` — tabla legada. La aplicación no la consulta: usa la
--     columna JSONB del mismo nombre en `recetas` (SD-153). Tenía RLS activado
--     pero **sin ninguna política**, que ya niega toda lectura; se le retiran
--     además los permisos para que la intención quede escrita y no dependa de
--     que nadie añada una política por descuido.
--
-- Ninguna de las dos existe en la base local, así que esta migración es un
-- no-op allí. Los bloques van guardados por existencia a propósito.
--
-- Los `trigger` que escriben en `auditoria_log` son `security definer` y
-- pertenecen a `postgres`, de modo que siguen funcionando: revocar permisos a
-- `authenticated` no afecta a quien escribe en nombre del propietario.

do $$
begin
  if to_regclass('public.auditoria_log') is null then
    raise notice 'HFX-CLIN-009: auditoria_log no existe aquí; nada que hacer.';
    return;
  end if;

  -- Sin políticas, RLS activado niega toda lectura a quien no sea propietario
  -- ni tenga `bypassrls`. Es lo correcto: nadie debe leer esta tabla desde el
  -- cliente. Se conserva íntegra —no se borra ni una fila—, sólo deja de estar
  -- al alcance de una sesión de la aplicación.
  execute 'alter table public.auditoria_log enable row level security';
  execute 'revoke all on table public.auditoria_log from anon, authenticated';

  raise notice 'HFX-CLIN-009: auditoria_log cerrada al cliente (% filas conservadas).',
    (select count(*) from public.auditoria_log);
end;
$$;

do $$
begin
  if to_regclass('public.items_receta') is null then
    raise notice 'HFX-CLIN-009: items_receta no existe aquí; nada que hacer.';
    return;
  end if;

  execute 'alter table public.items_receta enable row level security';
  execute 'revoke all on table public.items_receta from anon, authenticated';

  raise notice 'HFX-CLIN-009: items_receta cerrada al cliente.';
end;
$$;

-- ---------------------------------------------------------------------------
-- Comprobación: no queda ninguna tabla de `public` legible sin política.
-- ---------------------------------------------------------------------------
-- Se comprueba aquí, dentro de la migración, porque el gate de la
-- certificación no puede ver lo que no existe en la base local. Así la
-- verificación viaja con el esquema y se ejecuta allá donde se aplique.
do $$
declare
  v_abiertas text;
begin
  select string_agg(c.relname, ', ' order by c.relname)
    into v_abiertas
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public'
     and c.relkind = 'r'
     and (
       not c.relrowsecurity
       or not exists (
         select 1 from pg_policies p
          where p.schemaname = 'public' and p.tablename = c.relname
       )
     )
     and (
       has_table_privilege('authenticated', c.oid, 'select')
       or has_table_privilege('anon', c.oid, 'select')
     );

  if v_abiertas is not null then
    raise exception
      'HFX-CLIN-009: estas tablas siguen siendo legibles sin política: %',
      v_abiertas;
  end if;

  raise notice 'HFX-CLIN-009: ninguna tabla de public queda legible sin política.';
end;
$$;
