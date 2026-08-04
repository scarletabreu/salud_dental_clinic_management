#!/usr/bin/env bash
# MU-0 · Verificación de que el Realtime local entrega eventos con RLS.
#
# Prepara el seed de certificación (usuarios @cert.local con contraseña
# conocida) y corre el script Dart que abre dos sesiones (admin y doctora),
# las suscribe a postgres_changes de `citas` y comprueba el recorte por rol.
#
#   tool/e2e/realtime_rls.sh
#
# Stack LOCAL siempre: reescribe datos de prueba.

set -uo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$RAIZ"

DB_URL='postgresql://postgres:postgres@127.0.0.1:54322/postgres'

EVIDENCIA="${EVIDENCIA:-$RAIZ/docs/qa/e2e-ui}"
mkdir -p "$EVIDENCIA"

echo '▶ Preparando la base: seed de certificación'
psql "$DB_URL" -q -v ON_ERROR_STOP=1 \
  -f supabase/tests/hfx_clin_006_seed_certificacion.sql \
  >"$EVIDENCIA/realtime_rls_seed.log" 2>&1 \
  || { echo '  ✗ falló el seed'; tail -20 "$EVIDENCIA/realtime_rls_seed.log"; exit 1; }

echo '▶ Verificando entrega de eventos con RLS a dos sesiones'
dart run tool/e2e/realtime_rls_fase0.dart
