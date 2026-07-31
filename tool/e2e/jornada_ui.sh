#!/usr/bin/env bash
# E2E de navegador sobre la aplicación real, headless.
#
# Arranca chromedriver y conduce la app con `flutter drive`. Chromium corre en
# modo headless: no se abre ninguna ventana ni se roba el foco, así que se
# puede lanzar mientras se trabaja en otra cosa.
#
# Apunta SIEMPRE al stack local. La configuración de `dart_define.json` del
# repositorio apunta a producción, y conducir clics automáticos contra datos
# reales no es aceptable: por eso los `--dart-define` van explícitos aquí.
#
#   tool/e2e/jornada_ui.sh

set -uo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$RAIZ"

DB_URL='postgresql://postgres:postgres@127.0.0.1:54322/postgres'
SUPABASE_URL='http://127.0.0.1:54321'
ANON_KEY='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0'

EVIDENCIA="${EVIDENCIA:-$RAIZ/docs/qa/e2e-ui}"
mkdir -p "$EVIDENCIA"

echo '▶ Preparando la base: seed de certificación + overlay de login'
psql "$DB_URL" -q -v ON_ERROR_STOP=1 \
  -f supabase/tests/hfx_clin_006_seed_certificacion.sql \
  >"$EVIDENCIA/seed.log" 2>&1 || { echo '  ✗ falló el seed'; tail -20 "$EVIDENCIA/seed.log"; exit 1; }
psql "$DB_URL" -q -v ON_ERROR_STOP=1 \
  -f supabase/tests/e2e_ui_login_overlay.sql \
  >"$EVIDENCIA/overlay.log" 2>&1 || { echo '  ✗ falló el overlay'; tail -20 "$EVIDENCIA/overlay.log"; exit 1; }

# El alta escribe siempre la misma ficha, con la misma cédula. Sin limpiarla,
# la segunda ejecución muere contra la unicidad de cédula y el fallo aparece
# disfrazado de «la ficha no se cerró tras guardar», que apunta a otro sitio.
psql "$DB_URL" -q -v ON_ERROR_STOP=1 >>"$EVIDENCIA/seed.log" 2>&1 <<'LIMPIEZA'
do $$
declare
  v_id uuid;
begin
  select p.id into v_id
    from public.personas p
   where p.nombre = 'Elena' and p.apellido = 'Encarnación E2E';
  if v_id is null then
    return;
  end if;
  delete from public.records   where paciente_id = v_id;
  delete from public.pacientes where id = v_id;
  delete from public.personas  where id = v_id;
end;
$$;
LIMPIEZA
echo '  ✓ base lista'

echo '▶ Arrancando chromedriver'
chromedriver --port=4444 >"$EVIDENCIA/chromedriver.log" 2>&1 &
CHROMEDRIVER_PID=$!
trap 'kill "$CHROMEDRIVER_PID" 2>/dev/null' EXIT
sleep 3
kill -0 "$CHROMEDRIVER_PID" 2>/dev/null || { echo '  ✗ chromedriver no arrancó'; cat "$EVIDENCIA/chromedriver.log"; exit 1; }
echo "  ✓ chromedriver en :4444 (pid $CHROMEDRIVER_PID)"

echo '▶ Conduciendo la aplicación (headless)'
export CHROME_EXECUTABLE="${CHROME_EXECUTABLE:-/usr/bin/chromium}"

flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/jornada_ui_test.dart \
  -d web-server \
  --browser-name=chrome \
  --chrome-binary="$CHROME_EXECUTABLE" \
  --headless \
  --browser-dimension=1440x900 \
  --dart-define=APP_ENVIRONMENT=development \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$ANON_KEY" \
  2>&1 | tee "$EVIDENCIA/jornada_ui.log"

ESTADO="${PIPESTATUS[0]}"
if [[ "$ESTADO" -ne 0 ]]; then
  echo "  ✗ jornada por interfaz fallida (exit $ESTADO) → docs/qa/e2e-ui/jornada_ui.log"
  exit "$ESTADO"
fi
echo "  ✓ jornada por interfaz superada → docs/qa/e2e-ui/jornada_ui.log"

# El alta puede «parecer» correcta en pantalla y no haber escrito nada, así que
# la última palabra la tiene la base: el paciente existe y su expediente nació
# con el tipo de sangre que la aplicación dice enviar.
echo '▶ Comprobando en la base lo que dejó el alta'
COMPROBACION=$(psql "$DB_URL" -qAt -c "
  select p.nombre || '|' || r.tipo_sangre
    from public.personas p
    join public.pacientes pa on pa.id = p.id
    join public.records r on r.paciente_id = p.id
   where p.nombre = 'Elena' and p.apellido = 'Encarnación E2E'
     and p.deleted_at is null")

if [[ "$COMPROBACION" != 'Elena|o_positivo' ]]; then
  echo "  ✗ el alta no dejó la ficha esperada: «$COMPROBACION»"
  exit 1
fi
echo '  ✓ el paciente existe y su expediente nació con tipo de sangre o_positivo'
