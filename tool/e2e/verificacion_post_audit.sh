#!/usr/bin/env bash
# Verificación post-audit · las tres jornadas de la clínica por la interfaz.
#
# Conduce la aplicación real, headless, contra el stack LOCAL:
#
#   1 · doctora   → agenda, llegada, consulta completa (vitales, odontograma,
#                   diagnóstico, tratamiento, receta), cierre, dos consultas a
#                   la vez, contraindicación absoluta y reanudación.
#   2 · asistente → agenda de los doctores que apoya, llegada, alta de
#                   paciente, nueva cita, cuentas y caja; y las dos ausencias
#                   que la separan de la clínica.
#   3 · admin     → expediente, PDF y cobro de la pre-factura.
#   4 · admin     → arqueo de caja y compra registrada + recibida.
#
# El orden importa: el admin cobra la cuenta que dejó la consulta de la doctora.
#
#   tool/e2e/verificacion_post_audit.sh

set -uo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$RAIZ"

DB_URL='postgresql://postgres:postgres@127.0.0.1:54322/postgres'
SUPABASE_URL='http://127.0.0.1:54321'
ANON_KEY='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0'

EVIDENCIA="${EVIDENCIA:-$RAIZ/docs/qa/verificacion-post-audit}"
mkdir -p "$EVIDENCIA"

echo '▶ Preparando la base'
psql "$DB_URL" -q -v ON_ERROR_STOP=1 \
  -f supabase/tests/hfx_clin_006_seed_certificacion.sql \
  >"$EVIDENCIA/preparacion.log" 2>&1 || { echo '  ✗ falló el seed'; tail -20 "$EVIDENCIA/preparacion.log"; exit 1; }
psql "$DB_URL" -q -v ON_ERROR_STOP=1 \
  -f supabase/tests/e2e_ui_login_overlay.sql \
  >>"$EVIDENCIA/preparacion.log" 2>&1 || { echo '  ✗ falló el overlay de login'; tail -20 "$EVIDENCIA/preparacion.log"; exit 1; }
# Las altas de paciente escriben siempre la misma cédula: sin limpiarlas, la
# segunda corrida muere contra la unicidad y el fallo aparece disfrazado de
# «la ficha no se cerró tras guardar».
psql "$DB_URL" -q -v ON_ERROR_STOP=1 >>"$EVIDENCIA/preparacion.log" 2>&1 <<'LIMPIEZA'
do $$
declare
  v_id uuid;
begin
  for v_id in
    select p.id from public.personas p
     where p.apellido in ('Encarnación E2E', 'Recepción E2E')
  loop
    delete from public.citas    where persona_id = v_id;
    delete from public.records  where paciente_id = v_id;
    delete from public.pacientes where id = v_id;
    delete from public.personas  where id = v_id;
  end loop;
end;
$$;
LIMPIEZA

psql "$DB_URL" -q -v ON_ERROR_STOP=1 \
  -f supabase/tests/e2e_agenda_hoy_overlay.sql \
  >>"$EVIDENCIA/preparacion.log" 2>&1 || { echo '  ✗ falló el overlay de agenda'; tail -20 "$EVIDENCIA/preparacion.log"; exit 1; }

echo '  ✓ base lista (seed + login + agenda de hoy)'

echo '▶ Arrancando chromedriver'
chromedriver --port=4444 >"$EVIDENCIA/chromedriver.log" 2>&1 &
CHROMEDRIVER_PID=$!
trap 'kill "$CHROMEDRIVER_PID" 2>/dev/null' EXIT
sleep 3
kill -0 "$CHROMEDRIVER_PID" 2>/dev/null || { echo '  ✗ chromedriver no arrancó'; cat "$EVIDENCIA/chromedriver.log"; exit 1; }
echo "  ✓ chromedriver en :4444 (pid $CHROMEDRIVER_PID)"

export CHROME_EXECUTABLE="${CHROME_EXECUTABLE:-/usr/bin/chromium}"

# Cada jornada va en su propia invocación —y por tanto en su propio navegador—
# porque `app.main()` no reinicia la sesión: Supabase la persiste.
conducir() {
  local objetivo="$1" registro="$2"
  flutter drive \
    --driver=test_driver/integration_test.dart \
    --target="$objetivo" \
    -d web-server \
    --browser-name=chrome \
    --chrome-binary="$CHROME_EXECUTABLE" \
    --headless \
    --browser-dimension=1440x1000 \
    --dart-define=APP_ENVIRONMENT=development \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_PUBLISHABLE_KEY="$ANON_KEY" \
    >"$EVIDENCIA/$registro" 2>&1
  return $?
}

jornada() {
  local titulo="$1" objetivo="$2" registro="$3"
  echo "▶ Jornada: $titulo"
  if conducir "$objetivo" "$registro" && grep -q 'All tests passed' "$EVIDENCIA/$registro"; then
    echo "  ✓ superada → $EVIDENCIA/$registro"
    return 0
  fi
  echo "  ✗ FALLÓ → $EVIDENCIA/$registro"
  grep -A20 -m1 -E '(Test failed|✗|Expected:|Actual:|No apareció|fail\()' "$EVIDENCIA/$registro" | head -40
  return 1
}

FALLOS=()
jornada 'doctora punta a punta'  integration_test/verif_doctor_test.dart    doctora.log   || FALLOS+=('doctora')
jornada 'asistente de recepción' integration_test/verif_asistente_test.dart asistente.log || FALLOS+=('asistente')
# El admin va en dos invocaciones: juntas superaban los 20 minutos que
# `integration_test` le da al driver para devolver el resultado, y la corrida
# moría en un `DriverError: request_data` con todo el trabajo ya hecho.
jornada 'admin · expediente y cobro' integration_test/verif_admin_test.dart         admin.log         || FALLOS+=('admin')
jornada 'admin · caja y compras'     integration_test/verif_admin_compras_test.dart admin_compras.log || FALLOS+=('admin-compras')

echo '▶ Lo que quedó escrito en la base'
psql "$DB_URL" -qAt -f tool/e2e/verificacion_post_audit.sql | tee "$EVIDENCIA/estado_base.txt"

if ((${#FALLOS[@]})); then
  echo "✗ Jornadas fallidas: ${FALLOS[*]}"
  exit 1
fi
echo '✓ Las tres jornadas superadas'
