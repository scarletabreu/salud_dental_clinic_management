#!/usr/bin/env bash
# MU-6 · Jornada multiusuario a tres sesiones (admin, doctora, asistente).
#
# Prepara el seed de certificación, limpia los restos de corridas anteriores
# y ejecuta la jornada: asignación, llegada, reagenda, apertura de caja,
# consulta finalizada → cuenta, cobro y cierre, verificando que cada evento
# llega a las otras sesiones en menos de 2 s y que ningún rol recibe datos
# fuera de su alcance.
#
#   tool/e2e/jornada_multiusuario.sh
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
  >"$EVIDENCIA/jornada_mu_seed.log" 2>&1 \
  || { echo '  ✗ falló el seed'; tail -20 "$EVIDENCIA/jornada_mu_seed.log"; exit 1; }

echo '▶ Limpiando restos de corridas anteriores'
psql "$DB_URL" -q -v ON_ERROR_STOP=1 >>"$EVIDENCIA/jornada_mu_seed.log" 2>&1 <<'SQL' \
  || { echo '  ✗ falló la limpieza'; tail -20 "$EVIDENCIA/jornada_mu_seed.log"; exit 1; }
do $$
declare
  v_hoy date := (now() at time zone 'America/Santo_Domingo')::date;
begin
  delete from public.movimientos_caja
   where caja_diaria_id in (select id from public.cajas where fecha_civil = v_hoy);
  delete from public.pagos
   where cuenta_id in (select id from public.cuentas where nota = 'MU-6 jornada');
  delete from public.cuentas where nota = 'MU-6 jornada';
  delete from public.consultas where motivo_consulta = 'MU-6 jornada';
  delete from public.citas where motivo like 'MU-6 jornada%';
  delete from public.doctor_paciente
   where paciente_id in
     (select id from public.personas where apellido = 'MU-6 jornada');
  delete from public.pacientes
   where id in (select id from public.personas where apellido = 'MU-6 jornada');
  delete from public.personas where apellido = 'MU-6 jornada';
  delete from public.cajas where fecha_civil = v_hoy;
  delete from public.doctor_asistentes
   where asistente_id = 'ce470000-0000-4000-8000-000000000003';
end;
$$;
SQL

echo '▶ Ejecutando la jornada multiusuario (tres sesiones reales)'
dart run tool/e2e/jornada_multiusuario.dart 2>&1 | tee "$EVIDENCIA/jornada_multiusuario.log"
exit "${PIPESTATUS[0]}"
