#!/usr/bin/env bash
# HFX-CLIN-004 · la jornada completa, por REST y con los tokens de cada rol.
#
# Recorre lo que el ticket promete, sin pasar por Flutter y sin `set role`: cada
# llamada viaja con el JWT de quien la haría en la clínica, así que RLS y grants
# se ejercen de verdad.
#
#   1. La asistente registra un paciente nuevo (una sola transacción) y le
#      agenda una cita.
#   2. Marca su llegada; el doctor abre la consulta y la reabre sin duplicarla.
#   3. Walk-in del doctor: registra su propia urgencia y la atiende.
#   4. Walk-in del admin: hace lo mismo, porque el admin también ejerce.
#   5. La asistente no puede abrir ninguna consulta, ni propia ni ajena.
#
# Uso:  supabase/tests/hfx_clin_004_jornada_e2e.sh

set -euo pipefail

API_URL="${API_URL:-http://127.0.0.1:54321}"
PGURL="${PGURL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
env_supabase() { npx supabase status -o env 2>/dev/null | grep "^$1=" | cut -d= -f2- | tr -d '"'; }
ANON_KEY="${ANON_KEY:-$(env_supabase ANON_KEY)}"
SERVICE_ROLE_KEY="${SERVICE_ROLE_KEY:-$(env_supabase SERVICE_ROLE_KEY)}"
PASSWORD='Smoke-HFX-004!'
SUFIJO="$RANDOM$RANDOM"
declare -a USUARIOS=()
declare -a PACIENTES=()

fallo() { echo "FALLO · $1" >&2; exit 1; }
ok() { echo "OK   · $1"; }

limpiar() {
  for pid in "${PACIENTES[@]:-}"; do
    [[ -z "$pid" ]] && continue
    psql "$PGURL" -q -v ON_ERROR_STOP=0 >/dev/null 2>&1 <<SQL || true
delete from public.auditoria_clinica where consulta_id in (
  select id from public.consultas where paciente_id = '$pid');
delete from public.dientes where odontograma_id in (
  select id from public.odontogramas where consulta_id in (
    select id from public.consultas where paciente_id = '$pid'));
delete from public.odontogramas where consulta_id in (
  select id from public.consultas where paciente_id = '$pid');
delete from public.consultas where paciente_id = '$pid';
delete from public.citas where persona_id = '$pid';
delete from public.record_condicion where record_id in (
  select id from public.records where paciente_id = '$pid');
delete from public.records where paciente_id = '$pid';
delete from public.persona_contactos where persona_id = '$pid';
delete from public.pacientes where id = '$pid';
delete from public.personas where id = '$pid';
SQL
  done
  for uid in "${USUARIOS[@]:-}"; do
    [[ -z "$uid" ]] && continue
    curl -s -X DELETE "$API_URL/auth/v1/admin/users/$uid" \
      -H "apikey: $SERVICE_ROLE_KEY" \
      -H "Authorization: Bearer $SERVICE_ROLE_KEY" >/dev/null || true
    psql "$PGURL" -q -v ON_ERROR_STOP=0 >/dev/null 2>&1 -c "
      delete from public.citas where doctor_id='$uid';
      delete from public.admins where id='$uid';
      delete from public.asistentes where id='$uid';
      delete from public.doctores where id='$uid';
      delete from public.usuarios where id='$uid';
      delete from public.persona_contactos where persona_id='$uid';
      delete from public.personas where id='$uid';" || true
  done
}
trap limpiar EXIT

crear_usuario() {
  local email="$1" metadata="$2" respuesta
  respuesta=$(curl -s -X POST "$API_URL/auth/v1/admin/users" \
    -H "apikey: $SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"$email\",\"password\":\"$PASSWORD\",\"email_confirm\":true,\"user_metadata\":$metadata}")
  NUEVO_ID=$(jq -r '.id // empty' <<<"$respuesta")
  [[ -n "$NUEVO_ID" ]] || fallo "alta de usuario: $respuesta"
  USUARIOS+=("$NUEVO_ID")
}

login() {
  curl -s -X POST "$API_URL/auth/v1/token?grant_type=password" \
    -H "apikey: $ANON_KEY" -H 'Content-Type: application/json' \
    -d "{\"email\":\"$1\",\"password\":\"$PASSWORD\"}" |
    jq -r '.access_token // empty'
}

# rpc <token> <nombre> <json>  → cuerpo de la respuesta; deja el código en HTTP
rpc() {
  local token="$1" nombre="$2" cuerpo="$3"
  HTTP=$(curl -s -o /tmp/hfx004_rpc.json -w '%{http_code}' \
    -X POST "$API_URL/rest/v1/rpc/$nombre" \
    -H "apikey: $ANON_KEY" -H "Authorization: Bearer $token" \
    -H 'Content-Type: application/json' -d "$cuerpo")
  cat /tmp/hfx004_rpc.json
}

# ---------------------------------------------------------------------------
# Actores
# ---------------------------------------------------------------------------
crear_usuario "hfx004.admin.$SUFIJO@local.test" \
  "{\"rol\":\"admin\",\"nombre\":\"Alma\",\"apellido\":\"Dirección\",\"fecha_nacimiento\":\"1980-01-01\",\"cedula\":\"HFX004-A-$SUFIJO\",\"username\":\"hfx004_a_$SUFIJO\",\"especialidad\":\"General\",\"departamento\":\"Dirección\"}"
ADMIN_ID="$NUEVO_ID"
crear_usuario "hfx004.doctor.$SUFIJO@local.test" \
  "{\"rol\":\"doctor\",\"nombre\":\"Delia\",\"apellido\":\"Clínica\",\"fecha_nacimiento\":\"1981-01-01\",\"cedula\":\"HFX004-D-$SUFIJO\",\"username\":\"hfx004_d_$SUFIJO\",\"especialidad\":\"General\"}"
DOCTOR_ID="$NUEVO_ID"
crear_usuario "hfx004.asistente.$SUFIJO@local.test" \
  "{\"rol\":\"asistente\",\"nombre\":\"Rita\",\"apellido\":\"Recepción\",\"fecha_nacimiento\":\"1990-01-01\",\"cedula\":\"HFX004-AS-$SUFIJO\",\"username\":\"hfx004_as_$SUFIJO\",\"turno\":\"matutino\"}"
ASISTENTE_ID="$NUEVO_ID"

TOKEN_ADMIN=$(login "hfx004.admin.$SUFIJO@local.test")
TOKEN_DOCTOR=$(login "hfx004.doctor.$SUFIJO@local.test")
TOKEN_ASISTENTE=$(login "hfx004.asistente.$SUFIJO@local.test")
[[ -n "$TOKEN_ADMIN" && -n "$TOKEN_DOCTOR" && -n "$TOKEN_ASISTENTE" ]] ||
  fallo 'login de actores'

# ---------------------------------------------------------------------------
# 1 · Paciente nuevo, en una sola transacción, dado de alta por recepción
# ---------------------------------------------------------------------------
respuesta=$(rpc "$TOKEN_ASISTENTE" registrar_paciente "$(cat <<JSON
{"p_payload":{
  "nombre":"Paula","apellido":"Nueva","fecha_nacimiento":"1994-02-02",
  "cedula":"402-000$SUFIJO","genero":"femenino",
  "contactos":[{"numero_telefono":"(809) 555-$SUFIJO","email":"Paula.Nueva@Correo.COM"}],
  "record":{"tipo_sangre":"o_positivo"}
}}
JSON
)")
PACIENTE_ID=$(jq -r '.paciente_id // empty' <<<"$respuesta")
[[ -n "$PACIENTE_ID" ]] || fallo "alta de paciente (HTTP $HTTP): $respuesta"
PACIENTES+=("$PACIENTE_ID")

completo=$(psql "$PGURL" -qAt -c "
  select (select count(*) from public.pacientes where id='$PACIENTE_ID')
       + (select count(*) from public.records where paciente_id='$PACIENTE_ID')
       + (select count(*) from public.persona_contactos where persona_id='$PACIENTE_ID');")
[[ "$completo" == "3" ]] ||
  fallo "el alta no dejó ficha, expediente y contacto (suma $completo)"
ok 'recepción da de alta al paciente completo en una sola operación'

# ---------------------------------------------------------------------------
# 2 · Cita, llegada y consulta
# ---------------------------------------------------------------------------
CITA_ID=$(curl -s -X POST "$API_URL/rest/v1/citas" \
  -H "apikey: $ANON_KEY" -H "Authorization: Bearer $TOKEN_ASISTENTE" \
  -H 'Content-Type: application/json' -H 'Prefer: return=representation' \
  -d "{\"persona_id\":\"$PACIENTE_ID\",\"doctor_id\":\"$DOCTOR_ID\",\"fecha_hora\":\"$(date -u -d '+1 day' +%Y-%m-%dT%H:00:00Z)\",\"duracion_minutos\":30,\"estado\":\"confirmada\"}" |
  jq -r '.[0].id // empty')
[[ -n "$CITA_ID" ]] || fallo 'la asistente no pudo agendar la cita'

# Sin llegada no hay consulta: el paciente todavía no está.
rpc "$TOKEN_DOCTOR" iniciar_consulta_de_cita "{\"p_cita_id\":\"$CITA_ID\"}" >/dev/null
[[ "$HTTP" != "200" ]] || fallo 'se abrió una consulta sin registrar la llegada'
ok 'sin llegada registrada no se abre la consulta'

rpc "$TOKEN_ASISTENTE" registrar_llegada_cita "{\"p_cita_id\":\"$CITA_ID\"}" >/dev/null
[[ "$HTTP" == "200" ]] || fallo "recepción no pudo marcar la llegada (HTTP $HTTP)"

primera=$(rpc "$TOKEN_DOCTOR" iniciar_consulta_de_cita "{\"p_cita_id\":\"$CITA_ID\"}")
CONSULTA_ID=$(jq -r '.consulta_id // empty' <<<"$primera")
[[ "$(jq -r '.estado' <<<"$primera")" == "creada" ]] ||
  fallo "el primer inicio no creó la consulta: $primera"

segunda=$(rpc "$TOKEN_DOCTOR" iniciar_consulta_de_cita "{\"p_cita_id\":\"$CITA_ID\"}")
[[ "$(jq -r '.estado' <<<"$segunda")" == "reanudada" ]] ||
  fallo "el reintento no reanudó: $segunda"
[[ "$(jq -r '.consulta_id' <<<"$segunda")" == "$CONSULTA_ID" ]] ||
  fallo 'el reintento devolvió otra consulta'

vigentes=$(psql "$PGURL" -qAt -c "
  select count(*) from public.consultas where cita_id='$CITA_ID' and deleted_at is null;")
[[ "$vigentes" == "1" ]] || fallo "la cita quedó con $vigentes consultas"
ok 'paciente nuevo → cita → llegada → consulta, y reintentar reanuda'

# ---------------------------------------------------------------------------
# 3 · Walk-in atendido por el doctor
# ---------------------------------------------------------------------------
urgencia=$(rpc "$TOKEN_DOCTOR" registrar_cita_emergencia \
  "{\"p_paciente_id\":\"$PACIENTE_ID\",\"p_motivo\":\"Dolor agudo\"}")
CITA_URG=$(jq -r '.cita_id // empty' <<<"$urgencia")
[[ -n "$CITA_URG" ]] || fallo "el doctor no pudo registrar su urgencia: $urgencia"

marca=$(psql "$PGURL" -qAt -c "
  select es_emergencia::text || ':' || estado::text || ':' || (doctor_id='$DOCTOR_ID')::text
    from public.citas where id='$CITA_URG';")
[[ "$marca" == "true:en_espera:true" ]] ||
  fallo "la urgencia no quedó identificada ni en espera ($marca)"

abierta=$(rpc "$TOKEN_DOCTOR" iniciar_consulta_de_cita "{\"p_cita_id\":\"$CITA_URG\"}")
[[ "$(jq -r '.estado' <<<"$abierta")" == "creada" ]] ||
  fallo "el doctor no pudo atender su urgencia: $abierta"
ok 'walk-in del doctor: registra la urgencia, queda marcada y la atiende'

# ---------------------------------------------------------------------------
# 4 · Walk-in atendido por el admin, que también ejerce
# ---------------------------------------------------------------------------
urgencia=$(rpc "$TOKEN_ADMIN" registrar_cita_emergencia \
  "{\"p_paciente_id\":\"$PACIENTE_ID\",\"p_motivo\":\"Segunda urgencia\"}")
CITA_URG_ADMIN=$(jq -r '.cita_id // empty' <<<"$urgencia")
[[ -n "$CITA_URG_ADMIN" ]] || fallo "el admin no pudo registrar la urgencia: $urgencia"

abierta=$(rpc "$TOKEN_ADMIN" iniciar_consulta_de_cita "{\"p_cita_id\":\"$CITA_URG_ADMIN\"}")
[[ "$(jq -r '.estado' <<<"$abierta")" == "creada" ]] ||
  fallo "el admin no pudo atender su propia cita: $abierta"
ok 'walk-in del admin: el administrador ejerce como doctor en lo suyo'

# ---------------------------------------------------------------------------
# 5 · La asistente no abre consultas
# ---------------------------------------------------------------------------
urgencia=$(rpc "$TOKEN_ASISTENTE" registrar_cita_emergencia \
  "{\"p_paciente_id\":\"$PACIENTE_ID\",\"p_doctor_id\":\"$DOCTOR_ID\",\"p_motivo\":\"Urgencia de recepción\"}")
CITA_URG_ASIS=$(jq -r '.cita_id // empty' <<<"$urgencia")
[[ -n "$CITA_URG_ASIS" ]] ||
  fallo "la asistente no pudo registrar una urgencia para el doctor: $urgencia"

rpc "$TOKEN_ASISTENTE" iniciar_consulta_de_cita "{\"p_cita_id\":\"$CITA_URG_ASIS\"}" >/dev/null
[[ "$HTTP" != "200" ]] || fallo 'la asistente abrió una consulta'
ok 'la asistente encamina la urgencia pero no escribe clínica'

echo 'SMOKE HFX-CLIN-004 COMPLETO · jornada de admin-doctor, doctor y asistente.'
