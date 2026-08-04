#!/usr/bin/env bash
# Reproduce los cinco registros ambiguos HFX-QA-108 en Flutter web + Chromium
# headless contra Supabase local. No abre ventanas ni toma el foco del usuario.

set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$RAIZ"

DB_URL='postgresql://postgres:postgres@127.0.0.1:54322/postgres'
SUPABASE_URL='http://127.0.0.1:54321'
ANON_KEY='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0'

psql "$DB_URL" -q -v ON_ERROR_STOP=1 \
  -f supabase/tests/hfx_clin_006_seed_certificacion.sql
psql "$DB_URL" -q -v ON_ERROR_STOP=1 \
  -f supabase/tests/e2e_ui_login_overlay.sql >/dev/null
psql "$DB_URL" -q -v ON_ERROR_STOP=1 \
  -f supabase/tests/e2e_qa108_odontograma_seed.sql

CHROMEDRIVER_LOG="$(mktemp -t hfx_qa108_chromedriver.XXXXXX.log)"
chromedriver --port=4444 >"$CHROMEDRIVER_LOG" 2>&1 &
CHROMEDRIVER_PID=$!
trap 'kill "$CHROMEDRIVER_PID" 2>/dev/null || true; rm -f "$CHROMEDRIVER_LOG"' EXIT
sleep 2

export CHROME_EXECUTABLE="${CHROME_EXECUTABLE:-/usr/bin/chromium}"
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/qa108_odontograma_ambiguos_test.dart \
  -d web-server \
  --browser-name=chrome \
  --chrome-binary="$CHROME_EXECUTABLE" \
  --headless \
  --browser-dimension=1440x1000 \
  --dart-define=APP_ENVIRONMENT=development \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$ANON_KEY"
