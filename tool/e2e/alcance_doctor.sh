#!/usr/bin/env bash
# E2E de navegador · ¿ve un doctor la agenda de otro doctor?
#
# El seed de certificación pone todas las citas del día en manos de la misma
# doctora, así que por sí solo no puede demostrar nada: no ver citas ajenas
# cuando no existen citas ajenas es un aprobado gratis. Aquí se le añaden citas
# del admin —que también ejerce (HFX-CLIN-000)— en el mismo día, y luego se
# conduce la aplicación con la sesión de la doctora.
#
#   tool/e2e/alcance_doctor.sh
#
# Stack LOCAL siempre: crea citas y reescribe correos de prueba.

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
  >"$EVIDENCIA/alcance_seed.log" 2>&1 || { echo '  ✗ falló el seed'; tail -20 "$EVIDENCIA/alcance_seed.log"; exit 1; }
psql "$DB_URL" -q -v ON_ERROR_STOP=1 \
  -f supabase/tests/e2e_ui_login_overlay.sql \
  >>"$EVIDENCIA/alcance_seed.log" 2>&1 || { echo '  ✗ falló el overlay'; tail -20 "$EVIDENCIA/alcance_seed.log"; exit 1; }

echo '▶ Sembrando citas del OTRO doctor en el mismo día'
psql "$DB_URL" -q -v ON_ERROR_STOP=1 >>"$EVIDENCIA/alcance_seed.log" 2>&1 <<'SQL' || { echo '  ✗ falló la siembra'; tail -20 "$EVIDENCIA/alcance_seed.log"; exit 1; }
do $$
declare
  v_admin    constant uuid := 'ce470000-0000-4000-8000-000000000001';
  v_paciente uuid;
  v_dia      timestamptz := date_trunc('day', now()) + interval '8 hours';
begin
  select c.persona_id into v_paciente
    from public.citas c
   where c.doctor_id = 'ce470000-0000-4000-8000-000000000002'
   limit 1;
  if v_paciente is null then
    raise exception 'el seed no dejó ninguna cita de la doctora: escenario inválido';
  end if;

  delete from public.citas where doctor_id = v_admin and motivo = 'Cita del otro doctor';

  insert into public.citas (persona_id, doctor_id, fecha_hora, duracion_minutos,
                            estado, motivo)
  values (v_paciente, v_admin, v_dia + interval '7 hours', 30,
          'confirmada', 'Cita del otro doctor');
end;
$$;
SQL
CITAS_OTRO=$(psql "$DB_URL" -qAt -c "
  select count(*) from public.citas
   where doctor_id = 'ce470000-0000-4000-8000-000000000001'
     and motivo = 'Cita del otro doctor';")
[[ "$CITAS_OTRO" == '1' ]] || { echo "  ✗ el escenario no quedó montado (citas del otro doctor: $CITAS_OTRO)"; exit 1; }
echo "  ✓ base lista: la doctora y el admin tienen citas el mismo día"

# El puerto puede estar ocupado por otro arnés en marcha; en ese caso se
# reutiliza el chromedriver que ya está escuchando en vez de fallar.
PUERTO="${PUERTO_CHROMEDRIVER:-4444}"
if curl -s --max-time 2 "http://127.0.0.1:$PUERTO/status" | grep -q '"ready"'; then
  echo "▶ Reutilizando el chromedriver que ya escucha en :$PUERTO"
else
  echo "▶ Arrancando chromedriver en :$PUERTO"
  chromedriver --port="$PUERTO" >"$EVIDENCIA/alcance_chromedriver.log" 2>&1 &
  CHROMEDRIVER_PID=$!
  trap 'kill "$CHROMEDRIVER_PID" 2>/dev/null' EXIT
  sleep 3
  kill -0 "$CHROMEDRIVER_PID" 2>/dev/null || { echo '  ✗ chromedriver no arrancó'; cat "$EVIDENCIA/alcance_chromedriver.log"; exit 1; }
fi

echo '▶ Conduciendo la aplicación como la doctora (headless)'
export CHROME_EXECUTABLE="${CHROME_EXECUTABLE:-/usr/bin/chromium}"
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/alcance_doctor_agenda_test.dart \
  -d web-server \
  --browser-name=chrome \
  --chrome-binary="$CHROME_EXECUTABLE" \
  --headless \
  --driver-port="$PUERTO" \
  --browser-dimension=1440x900 \
  --dart-define=APP_ENVIRONMENT=development \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$ANON_KEY" \
  2>&1 | tee "$EVIDENCIA/alcance_doctor.log"
ESTADO="${PIPESTATUS[0]}"

if [[ "$ESTADO" -ne 0 ]]; then
  echo "  ✗ la doctora SÍ alcanza lo ajeno (exit $ESTADO) → $EVIDENCIA/alcance_doctor.log"
  exit "$ESTADO"
fi
echo '  ✓ la doctora sólo ve su agenda y no hay filtro por doctores'
