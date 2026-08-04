#!/usr/bin/env bash
# HFX-CLIN-004 · dos reservas y dos inicios de consulta simultáneos.
#
# La prueba SQL corre dentro de una transacción y por eso no puede observar la
# carrera entre sesiones, que es justo el defecto del ticket: dos recepciones
# comprobaban disponibilidad a la vez y ambas insertaban. Aquí se abren dos
# conexiones reales.
#
#   1. Dos INSERT del mismo intervalo para el mismo doctor: uno entra, el otro
#      lo rechaza la restricción de exclusión.
#   2. Dos `iniciar_consulta_de_cita` a la vez sobre la misma cita: una crea y
#      la otra reanuda la misma consulta, nunca una segunda.
#
# Uso:  supabase/tests/hfx_clin_004_concurrencia.sh [DATABASE_URL]

set -euo pipefail

DB_URL="${1:-${DATABASE_URL_LOCAL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}}"

DOCTOR='51000000-0000-4000-8000-000000000001'
PACIENTE='51000000-0000-4000-8000-000000000002'
CITA='51000000-0000-4000-8000-000000000003'

psql_q() { psql "$DB_URL" -v ON_ERROR_STOP=1 -qtA "$@"; }

limpiar() {
  psql "$DB_URL" -qtA >/dev/null 2>&1 <<SQL || true
delete from public.auditoria_clinica where consulta_id in (
  select id from public.consultas where paciente_id = '$PACIENTE');
delete from public.dientes where odontograma_id in (
  select id from public.odontogramas where consulta_id in (
    select id from public.consultas where paciente_id = '$PACIENTE'));
delete from public.odontogramas where consulta_id in (
  select id from public.consultas where paciente_id = '$PACIENTE');
delete from public.consultas where paciente_id = '$PACIENTE';
delete from public.citas where persona_id = '$PACIENTE';
delete from public.pacientes where id = '$PACIENTE';
delete from public.personas where id = '$PACIENTE';
delete from public.doctores where id = '$DOCTOR';
delete from public.usuarios where id = '$DOCTOR';
delete from auth.users where id = '$DOCTOR';
delete from public.personas where id = '$DOCTOR';
SQL
}

trap limpiar EXIT
limpiar

psql_q >/dev/null <<SQL
insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  created_at, updated_at, raw_user_meta_data
) values (
  '$DOCTOR', '00000000-0000-0000-0000-000000000000', 'authenticated',
  'authenticated', 'hfx004-conc@test.local', 'x', now(), now(),
  '{"rol":"doctor","nombre":"Diana","apellido":"Carrera","fecha_nacimiento":"1985-01-01","cedula":"HFX004-CC","username":"hfx004_cc","especialidad":"General"}'
);

insert into public.personas (id, nombre, apellido, fecha_nacimiento, cedula)
values ('$PACIENTE', 'Pablo', 'Carrera', date '1990-01-01', 'HFX004-PC');
insert into public.pacientes (id, genero) values ('$PACIENTE', 'masculino');
insert into public.records (paciente_id, tipo_sangre, cirugias_previas, historial_familiar)
values ('$PACIENTE', 'o_positivo', '{}', '');
SQL

# --------------------------------------------------------------------------
# 1 · Dos reservas simultáneas del mismo intervalo.
# --------------------------------------------------------------------------
# La sesión A inserta y retiene la transacción abierta; B intenta el mismo
# hueco y queda esperando en el índice de exclusión hasta que A confirma.

psql "$DB_URL" -v ON_ERROR_STOP=1 -qtA >/dev/null <<SQL &
begin;
insert into public.citas (persona_id, doctor_id, fecha_hora, duracion_minutos)
values ('$PACIENTE', '$DOCTOR', date_trunc('hour', now()) + interval '1 day', 60);
select pg_sleep(3);
commit;
SQL
PID_A=$!

sleep 1

SALIDA_B=$(psql "$DB_URL" -qtA <<SQL 2>&1 || true
insert into public.citas (persona_id, doctor_id, fecha_hora, duracion_minutos)
values ('$PACIENTE', '$DOCTOR', date_trunc('hour', now()) + interval '1 day 30 minutes', 60);
SQL
)

wait "$PID_A"

if ! grep -q "citas_sin_solape" <<<"$SALIDA_B"; then
  echo "FALLO: la segunda reserva no fue rechazada. Salida: $SALIDA_B" >&2
  exit 1
fi

RESERVAS=$(psql_q -c "select count(*) from public.citas where doctor_id = '$DOCTOR' and deleted_at is null;")
[ "$RESERVAS" = "1" ] || { echo "FALLO: quedaron $RESERVAS reservas (esperada 1)" >&2; exit 1; }

echo "OK · dos reservas simultáneas del mismo intervalo producen una sola cita"

# --------------------------------------------------------------------------
# 2 · Dos inicios de consulta simultáneos sobre la misma cita.
# --------------------------------------------------------------------------

psql_q >/dev/null <<SQL
insert into public.citas (id, persona_id, doctor_id, fecha_hora, duracion_minutos, estado)
values ('$CITA', '$PACIENTE', '$DOCTOR', date_trunc('hour', now()) + interval '2 days', 30, 'en_espera');
SQL

psql "$DB_URL" -v ON_ERROR_STOP=1 -qtA >/dev/null <<SQL &
begin;
select public.iniciar_consulta_de_cita('$CITA');
select pg_sleep(3);
commit;
SQL
PID_A=$!

sleep 1

SALIDA_B=$(psql "$DB_URL" -qtA <<SQL 2>&1 || true
select public.iniciar_consulta_de_cita('$CITA') ->> 'estado';
SQL
)

wait "$PID_A"

if ! grep -q "reanudada" <<<"$SALIDA_B"; then
  echo "FALLO: el segundo inicio no reanudó la consulta existente. Salida: $SALIDA_B" >&2
  exit 1
fi

CONSULTAS=$(psql_q -c "select count(*) from public.consultas where cita_id = '$CITA' and deleted_at is null;")
ESTADO=$(psql_q -c "select estado from public.citas where id = '$CITA';")

[ "$CONSULTAS" = "1" ]        || { echo "FALLO: la cita quedó con $CONSULTAS consultas" >&2; exit 1; }
[ "$ESTADO" = "en_consulta" ] || { echo "FALLO: la cita quedó en $ESTADO" >&2; exit 1; }

echo "OK · dos inicios simultáneos producen una sola consulta y la cita queda en_consulta"
echo "SMOKE HFX-CLIN-004 COMPLETO · concurrencia de agenda y de inicio de consulta."
