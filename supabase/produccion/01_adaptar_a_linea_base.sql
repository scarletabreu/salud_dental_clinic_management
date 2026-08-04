-- Adaptador de producción a la línea base del repositorio.
--
-- Se ejecuta UNA VEZ contra la instancia remota, ANTES de `supabase db push`.
-- No es una migración: no va en `supabase/migrations/` porque describe la
-- deriva de una instancia concreta, no una evolución del producto.
--
-- Por qué hace falta: producción no es «el repo menos las migraciones HFX».
-- Ha derivado por su cuenta —hay objetos hechos a mano desde el Studio— y las
-- migraciones HFX están escritas contra la línea base del repositorio. Aplicar
-- `db push` sin esto revienta a mitad de camino y deja la base en un estado
-- intermedio, con los datos reales de la clínica dentro.
--
-- Cada bloque es idempotente y se puede volver a ejecutar sin daño. Ninguno
-- borra datos: sólo amplía tipos y normaliza valores.
--
-- Verificado sobre una réplica de producción restaurada desde copia de
-- seguridad; ver `tool/produccion/ensayo_migracion.sh`.

-- ---------------------------------------------------------------------------
-- 1. `recetas.estado`: el enum de producción no conoce el ciclo de vida nuevo
-- ---------------------------------------------------------------------------
-- La línea base del repositorio no tiene siquiera columna `estado` en
-- `recetas`: la introduce `20260731090200_hfx_clin_000_recetas_formato_sd153`
-- como texto con un CHECK. Producción llegó al mismo formato por otra vía y
-- la resolvió con un enum `estado_receta` de tres etiquetas:
--
--     activa, anulada, reemplazada
--
-- HFX-CLIN-002 necesita cuatro —`borrador`, `emitida`, `anulada`,
-- `reemplazada`— y hace `update ... set estado = 'emitida'`, que contra ese
-- enum falla con «invalid input value for enum estado_receta».
--
-- Se amplía el enum en vez de convertir la columna a texto: es la operación
-- reversible, no reescribe la tabla y no puede perder una receta. Las etiquetas
-- viejas se conservan, así que nada de lo ya guardado deja de ser válido.
--
-- `alter type ... add value` no puede correr dentro de un bloque de
-- transacción, de ahí que vaya suelto y no dentro de un `do $$`.

do $$
begin
  if exists (
    select 1
      from information_schema.columns
     where table_schema = 'public' and table_name = 'recetas'
       and column_name = 'estado' and udt_name = 'estado_receta'
  ) then
    -- Se convierte a texto en vez de ampliar el enum. Ampliarlo parecía la
    -- opción menos invasiva, pero deja la columna con un tipo que el resto del
    -- sistema no espera: las RPC y las pruebas comparan `estado` contra
    -- variables `text`, y Postgres responde «operator does not exist:
    -- estado_receta = text». Quedaría una producción que aplica las migraciones
    -- y luego falla al usarse, que es peor que fallar al migrar.
    --
    -- La conversión conserva todos los valores tal cual: `activa` sigue siendo
    -- `activa` hasta que HFX-CLIN-002 la pase a `emitida`. No se pierde ninguna
    -- receta ni cambia ninguna semántica.
    alter table public.recetas
      alter column estado drop default;

    alter table public.recetas
      alter column estado type text using estado::text;

    raise notice 'adaptador: recetas.estado convertida de enum a texto.';
  else
    raise notice 'adaptador: recetas.estado ya es texto; nada que hacer.';
  end if;
end;
$$;

-- El enum queda huérfano si nadie más lo usa. Se retira sólo en ese caso, para
-- no tocar una columna de otra tabla que todavía dependa de él.
do $$
begin
  if exists (select 1 from pg_type where typname = 'estado_receta')
     and not exists (
       select 1 from pg_attribute a
        join pg_class c on c.oid = a.attrelid
        join pg_type t on t.oid = a.atttypid
       where t.typname = 'estado_receta' and a.attnum > 0 and not a.attisdropped
     ) then
    drop type public.estado_receta;
    raise notice 'adaptador: enum estado_receta retirado (ya no lo usa nadie).';
  end if;
end;
$$;
