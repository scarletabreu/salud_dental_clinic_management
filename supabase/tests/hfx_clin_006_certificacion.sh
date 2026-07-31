#!/usr/bin/env bash
# HFX-CLIN-006 · certificación completa del core clínico.
#
# Ejecuta todos los gates obligatorios del ticket en una sola pasada y sobre una
# base reconstruida desde cero, que es la única forma de demostrar que el
# repositorio basta: si algo sólo funciona porque la instancia local tiene un
# parche aplicado a mano, aquí se cae.
#
# Orden deliberado: primero se reconstruye la base, luego los gates estáticos
# (analyze, tests unitarios, Deno), después la suite SQL, y al final las
# jornadas por REST y los escenarios de fallo, que son los que dejan datos.
#
#   supabase/tests/hfx_clin_006_certificacion.sh
#
# Variables útiles:
#   SALTAR_RESET=1   reutiliza la base actual (para depurar; no certifica).

set -uo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$RAIZ"

EVIDENCIA="${EVIDENCIA:-$RAIZ/docs/qa/hfx-clin-006}"
rm -rf "$EVIDENCIA"
mkdir -p "$EVIDENCIA"

VERDES=0
ROJOS=0
declare -a FALLIDOS=()

gate() {
  local nombre="$1" registro="$2"; shift 2
  printf '\n\033[1m▶ %s\033[0m\n' "$nombre"
  if "$@" >"$EVIDENCIA/$registro" 2>&1; then
    VERDES=$((VERDES + 1))
    printf '  \033[32m✓\033[0m %s  → %s\n' "$nombre" "docs/qa/hfx-clin-006/$registro"
  else
    ROJOS=$((ROJOS + 1))
    FALLIDOS+=("$nombre ($registro)")
    printf '  \033[31m✗\033[0m %s  → %s\n' "$nombre" "docs/qa/hfx-clin-006/$registro"
    tail -n 15 "$EVIDENCIA/$registro" | sed 's/^/    /'
  fi
}

# `flutter analyze` sale con 0 aunque haya `info`, y con 1 si hay error o
# warning. Lo que la Definition of Done exige es que no haya ni errores ni
# warnings, así que se comprueba el conteo y no sólo el código de salida.
analyze_limpio() {
  local salida
  salida=$(flutter analyze 2>&1)
  echo "$salida"
  local graves
  graves=$(grep -cE '^\s+(error|warning) •' <<<"$salida" || true)
  echo
  echo "Errores y warnings: $graves"
  [[ "$graves" -eq 0 ]]
}

suite_sql() {
  local archivo estado=0
  for archivo in supabase/tests/*_test.sql; do
    echo "── $archivo"
    if ! psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" \
           -v ON_ERROR_STOP=1 -f "$archivo" 2>&1; then
      estado=1
    fi
  done
  return $estado
}

echo "════════════════════════════════════════════════════════════"
echo " HFX-CLIN-006 · certificación del core clínico"
echo " $(date '+%Y-%m-%d %H:%M:%S') · rama $(git rev-parse --abbrev-ref HEAD) · $(git rev-parse --short HEAD)"
echo "════════════════════════════════════════════════════════════"

# ---------------------------------------------------------------------------
# 1 · La base se reconstruye desde el repositorio
# ---------------------------------------------------------------------------
if [[ "${SALTAR_RESET:-0}" != "1" ]]; then
  gate 'supabase db reset (bootstrap desde un clon limpio)' 'db_reset.log' \
    npx supabase db reset
else
  echo; echo '  · db reset omitido por SALTAR_RESET=1: esto NO certifica.'
fi

# ---------------------------------------------------------------------------
# 2 · Gates estáticos
# ---------------------------------------------------------------------------
gate 'flutter analyze'            'flutter_analyze.log' analyze_limpio
gate 'flutter test (suite Dart)'  'flutter_test.log'    flutter test
gate 'deno test (Edge Functions)' 'deno_test.log'       deno test --allow-all supabase/functions/

# ---------------------------------------------------------------------------
# 3 · Suite SQL
# ---------------------------------------------------------------------------
gate 'suite SQL completa' 'suite_sql.log' suite_sql

# ---------------------------------------------------------------------------
# 4 · Jornadas por REST, con los tokens de cada rol
# ---------------------------------------------------------------------------
# Cada jornada parte de una base reconstruida. No es cautela de más: las tres
# atienden a los mismos pacientes de la misma agenda, así que encadenarlas haría
# que la segunda encontrase las citas ya completadas por la primera y fallase
# por un motivo que no tiene nada que ver con lo que quiere demostrar. Una
# jornada sólo certifica si se puede recorrer entera desde el principio.
jornada() {
  local nombre="$1" registro="$2" script="$3"
  if [[ "${SALTAR_RESET:-0}" != "1" ]]; then
    npx supabase db reset >>"$EVIDENCIA/db_reset.log" 2>&1
    psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' \
      -q -v ON_ERROR_STOP=1 -f supabase/tests/hfx_clin_006_seed_certificacion.sql \
      >>"$EVIDENCIA/seed.log" 2>&1
  fi
  gate "$nombre" "$registro" "$script"
}

jornada 'jornada admin-doctor' 'jornada_admin_doctor.log' \
  supabase/tests/hfx_clin_006_jornada_admin_doctor.sh
jornada 'jornada doctor'       'jornada_doctor.log' \
  supabase/tests/hfx_clin_006_jornada_doctor.sh
jornada 'jornada asistente'    'jornada_asistente.log' \
  supabase/tests/hfx_clin_006_jornada_asistente.sh

# ---------------------------------------------------------------------------
# 5 · Escenarios de fallo y concurrencia
# ---------------------------------------------------------------------------
jornada 'escenarios de fallo' 'escenarios_de_fallo.log' \
  supabase/tests/hfx_clin_006_escenarios_de_fallo.sh

# ---------------------------------------------------------------------------
# 6 · Pruebas ofensivas y de concurrencia heredadas
# ---------------------------------------------------------------------------
gate 'REST ofensivo (HFX-CLIN-001)'   'rest_ofensivo.log' \
  supabase/tests/hfx_clin_001_rest_ofensivo.sh
gate 'concurrencia de cierre (HFX-CLIN-002)' 'concurrencia_cierre.log' \
  supabase/tests/hfx_clin_002_concurrencia.sh
gate 'contrato REST (HFX-CLIN-002)'   'contrato_rest.log' \
  supabase/tests/hfx_clin_002_contrato_rest.sh
gate 'concurrencia de agenda (HFX-CLIN-004)' 'concurrencia_agenda.log' \
  supabase/tests/hfx_clin_004_concurrencia.sh
gate 'jornada E2E (HFX-CLIN-004)'     'jornada_e2e_004.log' \
  supabase/tests/hfx_clin_004_jornada_e2e.sh

# ---------------------------------------------------------------------------
# 7 · Estado final de la base: hashes y drift
# ---------------------------------------------------------------------------
{
  echo '# Migraciones aplicadas y su hash'
  echo
  for m in supabase/migrations/*.sql; do
    printf '%s  %s\n' "$(sha256sum "$m" | cut -c1-16)" "$(basename "$m")"
  done
  echo
  echo '# Reglas clínicas en vigor'
  psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -qA -F' | ' -c \
    "select codigo, version, estado, severidad, accion, parametros::text
       from reglas_clinicas order by codigo"
  echo
  echo '# Tablas sin RLS o sin políticas (debe estar vacío)'
  psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' -qA -F' | ' -c \
    "select c.relname
       from pg_class c join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public' and c.relkind = 'r'
        and (not c.relrowsecurity
             or not exists (select 1 from pg_policies p
                             where p.schemaname = 'public'
                               and p.tablename = c.relname))
      order by 1"
} >"$EVIDENCIA/estado_base.txt" 2>&1
echo; echo "  · estado de la base → docs/qa/hfx-clin-006/estado_base.txt"

# ---------------------------------------------------------------------------
echo
echo "════════════════════════════════════════════════════════════"
if [[ "$ROJOS" -eq 0 ]]; then
  printf ' \033[32mCERTIFICACIÓN VERDE\033[0m · %d gates superados.\n' "$VERDES"
  echo " Evidencia en docs/qa/hfx-clin-006/"
  echo "════════════════════════════════════════════════════════════"
  exit 0
fi

printf ' \033[31mCERTIFICACIÓN ROJA\033[0m · %d verdes, %d fallidos.\n' "$VERDES" "$ROJOS"
for f in "${FALLIDOS[@]}"; do echo "   ✗ $f"; done
echo "════════════════════════════════════════════════════════════"
exit 1
