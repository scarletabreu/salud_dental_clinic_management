#!/usr/bin/env bash
# D11 · alcance clínico por doctor, comprobado por REST y no por psql.
#
#   bash supabase/tests/d11_alcance_clinico_rest.sh
#
# Por qué REST y no sólo SQL: la RLS puede estar bien y el dato salir igual por
# otro camino. Aquí se cayó `consulta_resumen`, una vista de la línea base que
# no declaraba `security_invoker` y que PostgREST servía a cualquier doctor
# saltándose `consulta_select`. Una prueba en psql sobre la tabla no lo habría
# visto nunca.
#
# Contrato: el doctor ve su consulta y su cita; el doctor ajeno no ve ninguna
# de las dos, ni por la tabla ni por la vista; el admin las ve todas.
set -euo pipefail

API_URL="${API_URL:-http://127.0.0.1:54321}"
PGURL="${PGURL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
env_supabase() { supabase status -o env 2>/dev/null | grep "^$1=" | cut -d= -f2- | tr -d '"'; }
ANON_KEY="${ANON_KEY:-$(env_supabase ANON_KEY)}"
SERVICE_ROLE_KEY="${SERVICE_ROLE_KEY:-$(env_supabase SERVICE_ROLE_KEY)}"
PASSWORD='Alcance-D11!'
SUFIJO="$RANDOM$RANDOM"
declare -a USUARIOS=()
PACIENTE_ID=''

fallo() { echo "FALLO · $1" >&2; exit 1; }
ok() { echo "OK   · $1"; }

# `doctor_paciente` se llena solo al crear la consulta (trigger
# `fn_autoasignar_doctor_paciente`), y apunta a las tres personas: por eso se
# vacía antes que nada, o el borrado de `usuarios` choca con su clave ajena.
limpiar() {
  local ids="'00000000-0000-0000-0000-000000000000'"
  for uid in "${USUARIOS[@]:-}"; do [[ -n "$uid" ]] && ids="$ids,'$uid'"; done
  [[ -n "$PACIENTE_ID" ]] && ids="$ids,'$PACIENTE_ID'"
  psql "$PGURL" -q -v ON_ERROR_STOP=0 >/dev/null 2>&1 <<SQL || true
delete from public.auditoria_clinica
 where consulta_id in (select id from public.consultas where doctor_id in ($ids))
    or cita_id in (select id from public.citas where doctor_id in ($ids));
delete from public.citas where doctor_id in ($ids) or persona_id in ($ids);
delete from public.consultas where doctor_id in ($ids) or paciente_id in ($ids);
delete from public.doctor_paciente
 where doctor_id in ($ids) or paciente_id in ($ids) or asignado_por in ($ids);
delete from public.pacientes where id in ($ids);
delete from public.doctores where id in ($ids);
delete from public.admins where id in ($ids);
delete from public.asistentes where id in ($ids);
delete from public.usuarios where id in ($ids);
delete from public.personas where id in ($ids);
SQL
  for uid in "${USUARIOS[@]:-}"; do
    [[ -z "$uid" ]] && continue
    curl -s -X DELETE "$API_URL/auth/v1/admin/users/$uid" \
      -H "apikey: $SERVICE_ROLE_KEY" \
      -H "Authorization: Bearer $SERVICE_ROLE_KEY" >/dev/null || true
  done
}
trap limpiar EXIT

crear_usuario() { # email metadata → NUEVO_ID
  local respuesta
  respuesta=$(curl -s -X POST "$API_URL/auth/v1/admin/users" \
    -H "apikey: $SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"$1\",\"password\":\"$PASSWORD\",\"email_confirm\":true,\"user_metadata\":$2}")
  NUEVO_ID=$(jq -r '.id // empty' <<<"$respuesta")
  [[ -n "$NUEVO_ID" ]] || fallo "alta de usuario: $respuesta"
  USUARIOS+=("$NUEVO_ID")
}

login() {
  curl -s -X POST "$API_URL/auth/v1/token?grant_type=password" \
    -H "apikey: $ANON_KEY" -H 'Content-Type: application/json' \
    -d "{\"email\":\"$1\",\"password\":\"$PASSWORD\"}" | jq -r '.access_token // empty'
}

filas() { # token ruta → número de filas, o el error si no fue una lista
  curl -s "$API_URL/rest/v1/$2" -H "apikey: $ANON_KEY" -H "Authorization: Bearer $1" |
    jq 'if type == "array" then length else . end'
}

esperar() { # etiqueta token ruta esperado
  local obtenido; obtenido=$(filas "$2" "$3")
  [[ "$obtenido" == "$4" ]] || fallo "$1 · $3 devolvió $obtenido (esperado $4)"
  ok "$1 · $3 → $4"
}

meta() { # rol nombre cedula username
  printf '{"rol":"%s","nombre":"%s","apellido":"Alcance","fecha_nacimiento":"1985-01-01","cedula":"%s","username":"%s","especialidad":"General","departamento":"Dirección"}' \
    "$1" "$2" "$3" "$4"
}

crear_usuario "d11-propio-$SUFIJO@test.local"  "$(meta doctor Ana   "D11P$SUFIJO" "d11p$SUFIJO")"; DOCTOR=$NUEVO_ID
crear_usuario "d11-ajeno-$SUFIJO@test.local"   "$(meta doctor Beto  "D11A$SUFIJO" "d11a$SUFIJO")"; AJENO=$NUEVO_ID
crear_usuario "d11-admin-$SUFIJO@test.local"   "$(meta admin  Delia "D11D$SUFIJO" "d11d$SUFIJO")"; ADMIN=$NUEVO_ID

PACIENTE_ID=$(psql "$PGURL" -qAt -c "
  insert into public.personas (nombre, apellido, fecha_nacimiento, cedula)
  values ('Pablo', 'Alcance', date '1990-01-01', 'D11X$SUFIJO') returning id;")
psql "$PGURL" -q -c "insert into public.pacientes (id, genero) values ('$PACIENTE_ID', 'masculino');"
CONSULTA=$(psql "$PGURL" -qAt -c "
  insert into public.consultas (paciente_id, doctor_id, fecha, motivo_consulta)
  values ('$PACIENTE_ID', '$DOCTOR', now(), 'Alcance D11') returning id;")
psql "$PGURL" -q -c "
  insert into public.citas (persona_id, doctor_id, fecha_hora, duracion_minutos, estado)
  values ('$PACIENTE_ID', '$DOCTOR', now() + interval '1 day', 30, 'programada');"

TOK_DOCTOR=$(login "d11-propio-$SUFIJO@test.local")
TOK_AJENO=$(login "d11-ajeno-$SUFIJO@test.local")
TOK_ADMIN=$(login "d11-admin-$SUFIJO@test.local")
[[ -n "$TOK_DOCTOR" && -n "$TOK_AJENO" && -n "$TOK_ADMIN" ]] || fallo 'no se pudo iniciar sesión'

esperar 'el doctor lee su consulta'        "$TOK_DOCTOR" "consultas?id=eq.$CONSULTA&select=id"        1
esperar 'el doctor ajeno no la lee'        "$TOK_AJENO"  "consultas?id=eq.$CONSULTA&select=id"        0
esperar 'el admin la lee'                  "$TOK_ADMIN"  "consultas?id=eq.$CONSULTA&select=id"        1
esperar 'la vista no es un desvío'         "$TOK_AJENO"  "consulta_resumen?id=eq.$CONSULTA&select=id" 0
esperar 'la vista sigue sirviendo al suyo' "$TOK_DOCTOR" "consulta_resumen?id=eq.$CONSULTA&select=id" 1
esperar 'el doctor ve su agenda'           "$TOK_DOCTOR" "citas?doctor_id=eq.$DOCTOR&select=id"       1
esperar 'la agenda ajena no se ve'         "$TOK_AJENO"  "citas?doctor_id=eq.$DOCTOR&select=id"       0
esperar 'el admin ve toda la agenda'       "$TOK_ADMIN"  "citas?doctor_id=eq.$DOCTOR&select=id"       1

echo 'TODO OK · D11: cada doctor ve lo suyo; el admin, todo.'
