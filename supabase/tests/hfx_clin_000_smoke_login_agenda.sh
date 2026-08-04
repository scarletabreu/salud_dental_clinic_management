#!/usr/bin/env bash
# HFX-CLIN-000 · Smoke de login y agenda para los tres roles.
#
# Recorre contra el stack LOCAL el mismo camino que hace el navegador cuando
# alguien entra a la app: alta del usuario (Auth -> trigger handle_new_user),
# login con contraseña, resolución del perfil por `perfil_actual()`, catálogo
# de doctores agendables y lectura de la agenda por PostgREST.
#
# No toca ninguna instancia remota y borra los usuarios que crea.
#
#   supabase start && supabase db reset
#   ./supabase/tests/hfx_clin_000_smoke_login_agenda.sh
set -euo pipefail

API_URL="${API_URL:-http://127.0.0.1:54321}"
PGURL="${PGURL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"

env_de_supabase() { supabase status -o env 2>/dev/null | grep "^$1=" | cut -d= -f2- | tr -d '"'; }
ANON_KEY="${ANON_KEY:-$(env_de_supabase ANON_KEY)}"
SERVICE_ROLE_KEY="${SERVICE_ROLE_KEY:-$(env_de_supabase SERVICE_ROLE_KEY)}"

if [[ -z "$ANON_KEY" || -z "$SERVICE_ROLE_KEY" ]]; then
  echo "FALLO: no se pudieron leer las llaves locales (¿'supabase start'?)." >&2
  exit 1
fi

PASSWORD='Smoke-HFX-000!'
declare -a CREADOS=()

limpiar() {
  for uid in "${CREADOS[@]:-}"; do
    [[ -z "$uid" ]] && continue
    curl -s -X DELETE "$API_URL/auth/v1/admin/users/$uid" \
      -H "apikey: $SERVICE_ROLE_KEY" -H "Authorization: Bearer $SERVICE_ROLE_KEY" >/dev/null || true
    psql "$PGURL" -q -c "delete from public.admins where id = '$uid';
                         delete from public.asistentes where id = '$uid';
                         delete from public.doctores where id = '$uid';
                         delete from public.usuarios where id = '$uid';
                         delete from public.persona_contactos where persona_id = '$uid';
                         delete from public.personas where id = '$uid';" >/dev/null || true
  done
}
trap limpiar EXIT

ok()    { echo "OK   · $1"; }
fallo() { echo "FALLO · $1" >&2; exit 1; }

# 1. Alta por Auth: el trigger versionado es quien crea el perfil.
#
# Deja el UUID en `NUEVO_UID` en vez de imprimirlo: si se leyera con `$(...)`
# la función correría en un subshell y la lista de creados —la que usa la
# limpieza— se quedaría vacía en el proceso principal.
crear_usuario() { # $1 email, $2 metadata json
  local respuesta
  respuesta=$(curl -s -X POST "$API_URL/auth/v1/admin/users" \
    -H "apikey: $SERVICE_ROLE_KEY" -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"$1\",\"password\":\"$PASSWORD\",\"email_confirm\":true,\"user_metadata\":$2}")
  NUEVO_UID=$(jq -r '.id // empty' <<<"$respuesta")
  [[ -z "$NUEVO_UID" ]] && fallo "alta de $1: $(jq -c '.' <<<"$respuesta")"
  CREADOS+=("$NUEVO_UID")
}

sufijo="$RANDOM$RANDOM"
crear_usuario "smoke.admin.$sufijo@local.test" \
  "{\"rol\":\"admin\",\"nombre\":\"Ada\",\"apellido\":\"Admin\",\"fecha_nacimiento\":\"1980-01-01\",\"cedula\":\"001-$sufijo-1\",\"username\":\"smoke_admin_$sufijo\",\"especialidad\":\"Endodoncia\",\"departamento\":\"Clínica\",\"telefono\":\"809-555-0100\"}"
ADMIN_ID="$NUEVO_UID"
crear_usuario "smoke.doctor.$sufijo@local.test" \
  "{\"rol\":\"doctor\",\"nombre\":\"Bruno\",\"apellido\":\"Doctor\",\"fecha_nacimiento\":\"1985-01-01\",\"cedula\":\"002-$sufijo-2\",\"username\":\"smoke_doctor_$sufijo\",\"especialidad\":\"Ortodoncia\"}"
DOCTOR_ID="$NUEVO_UID"
crear_usuario "smoke.asistente.$sufijo@local.test" \
  "{\"rol\":\"asistente\",\"nombre\":\"Carla\",\"apellido\":\"Asistente\",\"fecha_nacimiento\":\"1992-01-01\",\"cedula\":\"003-$sufijo-3\",\"username\":\"smoke_asis_$sufijo\",\"turno\":\"matutino\"}"
ok "alta de los tres roles por Auth + trigger"

# 2. Login: lo que hace la pantalla de acceso.
login() {
  local token
  token=$(curl -s -X POST "$API_URL/auth/v1/token?grant_type=password" \
    -H "apikey: $ANON_KEY" -H 'Content-Type: application/json' \
    -d "{\"email\":\"$1\",\"password\":\"$PASSWORD\"}" | jq -r '.access_token // empty')
  [[ -z "$token" ]] && fallo "login de $1"
  echo "$token"
}

TOKEN_ADMIN=$(login "smoke.admin.$sufijo@local.test")
TOKEN_DOCTOR=$(login "smoke.doctor.$sufijo@local.test")
TOKEN_ASIS=$(login "smoke.asistente.$sufijo@local.test")
ok "los tres roles inician sesión"

rpc() { # $1 token, $2 función
  curl -s -X POST "$API_URL/rest/v1/rpc/$2" \
    -H "apikey: $ANON_KEY" -H "Authorization: Bearer $1" \
    -H 'Content-Type: application/json' -d '{}'
}

# 3. Perfil: el contrato único que resuelve la sesión.
perfil_admin=$(rpc "$TOKEN_ADMIN" perfil_actual)
[[ $(jq -r '.[0].rol' <<<"$perfil_admin") == 'admin' ]] || fallo "el perfil del admin no resuelve como admin: $perfil_admin"
[[ $(jq -r '.[0].especialidad' <<<"$perfil_admin") == 'Endodoncia' ]] || fallo "el admin no trae identidad clínica"
[[ $(jq -r '.[0].departamento' <<<"$perfil_admin") == 'Clínica' ]] || fallo "el admin no trae datos administrativos"
[[ $(jq -r '.[0].id' <<<"$perfil_admin") == "$ADMIN_ID" ]] || fallo "el UUID del perfil no es el de Auth"
[[ $(jq -r '.[0] | has("password_hash")' <<<"$perfil_admin") == 'false' ]] || fallo "el perfil devuelve password_hash"
[[ $(jq -r '.[0].rol' <<<"$(rpc "$TOKEN_DOCTOR" perfil_actual)") == 'doctor' ]] || fallo "el perfil del doctor no resuelve"
perfil_asis=$(rpc "$TOKEN_ASIS" perfil_actual)
[[ $(jq -r '.[0].rol' <<<"$perfil_asis") == 'asistente' ]] || fallo "el perfil del asistente no resuelve"
[[ $(jq -r '.[0].turno' <<<"$perfil_asis") == 'matutino' ]] || fallo "el asistente no trae turno"
[[ $(jq -r '.[0].especialidad' <<<"$perfil_asis") == 'null' ]] || fallo "el asistente trae identidad clínica"
ok "perfil_actual() devuelve el contrato de cada rol y ninguna contraseña"

# 4. Catálogo de doctores: el admin tiene que ser agendable.
catalogo=$(rpc "$TOKEN_ASIS" get_active_doctors)
[[ $(jq -r --arg id "$ADMIN_ID" '[.[] | select(.doctor_id == $id)] | length' <<<"$catalogo") == '1' ]] \
  || fallo "el admin no aparece en el catálogo de doctores agendables"
[[ $(jq -r --arg id "$ADMIN_ID" '.[] | select(.doctor_id == $id) | .es_admin' <<<"$catalogo") == 'true' ]] \
  || fallo "el admin del catálogo no viene marcado como admin"
[[ $(jq -r --arg id "$DOCTOR_ID" '[.[] | select(.doctor_id == $id)] | length' <<<"$catalogo") == '1' ]] \
  || fallo "el doctor no aparece en el catálogo"
[[ $(jq -r '[.[] | select(has("password_hash"))] | length' <<<"$catalogo") == '0' ]] \
  || fallo "el catálogo devuelve password_hash"
ok "el admin es doctor agendable y el catálogo no filtra contraseñas"

# 5. Agenda: la lectura que hace la pantalla de citas del día.
agenda() {
  curl -s -o /dev/null -w '%{http_code}' \
    "$API_URL/rest/v1/citas?select=id,fecha_hora,doctor_id,estado&limit=5" \
    -H "apikey: $ANON_KEY" -H "Authorization: Bearer $1"
}
for par in "admin:$TOKEN_ADMIN" "doctor:$TOKEN_DOCTOR" "asistente:$TOKEN_ASIS"; do
  rol="${par%%:*}"; token="${par#*:}"
  codigo=$(agenda "$token")
  [[ "$codigo" == '200' ]] || fallo "la agenda responde $codigo para $rol"
done
ok "los tres roles leen la agenda"

# 6. Sin sesión no hay nada: la UI no es la barrera.
anon_perfil=$(curl -s -X POST "$API_URL/rest/v1/rpc/perfil_actual" \
  -H "apikey: $ANON_KEY" -H 'Content-Type: application/json' -d '{}')
[[ $(jq -r '.code // empty' <<<"$anon_perfil") == '42501' ]] \
  || fallo "anon pudo ejecutar perfil_actual: $anon_perfil"
ok "anon no ejecuta perfil_actual"

echo
echo "SMOKE HFX-CLIN-000 COMPLETO · login, perfil, catálogo y agenda para los tres roles."
