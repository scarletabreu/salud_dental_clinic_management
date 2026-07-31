#!/usr/bin/env bash
# Ensayo de la migración de producción, sobre una réplica local.
#
# Restaura una copia de seguridad de producción en el stack local, le aplica el
# adaptador y las migraciones pendientes, y se detiene en el primer fallo. Es
# la forma de convertir «esperemos que el push salga bien» en «ya lo vimos
# salir bien», sin tocar la instancia remota ni los datos reales de la clínica.
#
# DESTRUYE la base local. Es intencionado: la local es material desechable.
#
#   tool/produccion/ensayo_migracion.sh /ruta/a/la/copia
#
# La copia se toma con:
#   npx supabase db dump --linked            -f 01_schema.sql
#   npx supabase db dump --linked --data-only -f 02_datos.sql

set -uo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$RAIZ"

COPIA="${1:-}"
[[ -n "$COPIA" && -f "$COPIA/01_schema.sql" ]] || {
  echo "uso: $0 /ruta/a/la/copia   (debe contener 01_schema.sql y 02_datos.sql)"
  exit 2
}

DB='postgresql://postgres:postgres@127.0.0.1:54322/postgres'
REGISTRO="${REGISTRO:-$RAIZ/docs/qa/ensayo-produccion}"
mkdir -p "$REGISTRO"

paso() { printf '\n\033[1m▶ %s\033[0m\n' "$1"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
mal()  { printf '  \033[31m✗\033[0m %s\n' "$1"; }

# ---------------------------------------------------------------------------
paso 'Vaciando la base local y restaurando producción'
# ---------------------------------------------------------------------------
psql "$DB" -q -v ON_ERROR_STOP=1 >"$REGISTRO/00_vaciado.log" 2>&1 <<'SQL'
set session_replication_role = replica;
delete from auth.identities;
delete from auth.sessions;
delete from auth.refresh_tokens;
delete from auth.users;
drop schema public cascade;
create schema public;
grant usage on schema public to postgres, anon, authenticated, service_role;
grant all   on schema public to postgres, service_role;
SQL
ok 'base local vaciada'

psql "$DB" -q -v ON_ERROR_STOP=1 -f "$COPIA/01_schema.sql" >"$REGISTRO/01_esquema.log" 2>&1 \
  || { mal 'no se pudo restaurar el esquema'; grep -m5 ERROR "$REGISTRO/01_esquema.log"; exit 1; }
ok 'esquema de producción restaurado'

# El volcado de datos termina con los `setval` de las secuencias, pero también
# trae los buckets de Storage, que el stack local ya tiene. Sin ignorar ese
# choque la carga aborta antes de llegar a los `setval` y toda secuencia queda
# en 1: la primera migración que escriba una fila muere con «duplicate key».
psql "$DB" -q -f "$COPIA/02_datos.sql" >"$REGISTRO/02_datos.log" 2>&1
ok 'datos de producción restaurados'

# Red de seguridad: se recalculan todas las secuencias contra los datos reales,
# por si la carga se saltó algún `setval`.
psql "$DB" -q -v ON_ERROR_STOP=1 >>"$REGISTRO/02_datos.log" 2>&1 <<'SQL'
do $$
declare r record; v_max bigint;
begin
  for r in
    select s.relname as seq, t.relname as tabla, a.attname as col
      from pg_class s
      join pg_depend d on d.objid = s.oid and d.classid = 'pg_class'::regclass
      join pg_class t on t.oid = d.refobjid
      join pg_attribute a on a.attrelid = t.oid and a.attnum = d.refobjsubid
     where s.relkind = 'S' and s.relnamespace = 'public'::regnamespace
  loop
    execute format('select coalesce(max(%I),0) from public.%I', r.col, r.tabla) into v_max;
    perform setval('public.'||r.seq, greatest(v_max, 1), v_max > 0);
  end loop;
end;
$$;
SQL
ok 'secuencias resincronizadas'

printf '  · réplica: %s\n' \
  "$(psql "$DB" -qAt -c "select 'usuarios '||(select count(*) from auth.users)||
                                ', personas '||(select count(*) from personas)||
                                ', citas '||(select count(*) from citas)||
                                ', consultas '||(select count(*) from consultas)")"

# ---------------------------------------------------------------------------
paso 'Aplicando el adaptador de deriva'
# ---------------------------------------------------------------------------
for adaptador in supabase/produccion/*.sql; do
  [[ -e "$adaptador" ]] || break
  nombre=$(basename "$adaptador")
  if psql "$DB" -q -v ON_ERROR_STOP=1 -f "$adaptador" >"$REGISTRO/adapt_$nombre.log" 2>&1; then
    ok "$nombre"
  else
    mal "$nombre"; grep -m5 ERROR "$REGISTRO/adapt_$nombre.log"; exit 1
  fi
done

# Parche opcional de ensayo: simula una decisión de datos aún no tomada, para
# poder comprobar si el resto de las migraciones aplica. Nunca va al repositorio.
if [[ -n "${PARCHE_ENSAYO:-}" && -f "$PARCHE_ENSAYO" ]]; then
  paso 'Aplicando parche de ensayo (simulación, no es una decisión)'
  psql "$DB" -q -v ON_ERROR_STOP=1 -f "$PARCHE_ENSAYO" >"$REGISTRO/parche.log" 2>&1 \
    && ok "$(basename "$PARCHE_ENSAYO")" || { mal 'parche'; exit 1; }
fi

# ---------------------------------------------------------------------------
paso 'Aplicando las migraciones pendientes'
# ---------------------------------------------------------------------------
# Las dos de `linea_base` describen lo que producción ya tiene: en el push real
# se marcan como aplicadas con `supabase migration repair`, no se ejecutan.
FALLOS=0
for m in supabase/migrations/*.sql; do
  nombre=$(basename "$m")
  case "$nombre" in 20260725*) continue ;; esac

  if psql "$DB" -q -v ON_ERROR_STOP=1 -f "$m" >"$REGISTRO/mig_$nombre.log" 2>&1; then
    ok "$nombre"
  else
    mal "$nombre"
    grep -m5 "ERROR" "$REGISTRO/mig_$nombre.log" | sed 's/^/      /'
    FALLOS=1
    break
  fi
done

echo
if [[ "$FALLOS" -ne 0 ]]; then
  echo '════════════════════════════════════════════════════════════'
  printf ' \033[31mENSAYO ROJO\033[0m · la migración no es segura todavía.\n'
  echo " Detalle en $REGISTRO/"
  echo '════════════════════════════════════════════════════════════'
  exit 1
fi

echo '════════════════════════════════════════════════════════════'
printf ' \033[32mENSAYO VERDE\033[0m · las migraciones aplican sobre los datos reales.\n'
echo " Detalle en $REGISTRO/"
echo '════════════════════════════════════════════════════════════'
