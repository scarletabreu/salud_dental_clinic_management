#!/usr/bin/env bash
# HFX-CLIN-001 · llamadas REST directas, sin pasar por Flutter.
set -euo pipefail

API_URL="${API_URL:-http://127.0.0.1:54321}"
PGURL="${PGURL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
env_supabase() { supabase status -o env 2>/dev/null | grep "^$1=" | cut -d= -f2- | tr -d '"'; }
ANON_KEY="${ANON_KEY:-$(env_supabase ANON_KEY)}"
SERVICE_ROLE_KEY="${SERVICE_ROLE_KEY:-$(env_supabase SERVICE_ROLE_KEY)}"
PASSWORD='Smoke-HFX-001!'
SUFIJO="$RANDOM$RANDOM"
PACIENTE_ID="$(printf '%08x-0000-4000-8000-000000000001' "$RANDOM")"
declare -a USUARIOS=()

fallo() { echo "FALLO · $1" >&2; exit 1; }
ok() { echo "OK   · $1"; }

limpiar() {
  psql "$PGURL" -q -v ON_ERROR_STOP=0 <<SQL >/dev/null 2>&1 || true
delete from public.auditoria_correcciones_clinicas
 where consulta_id in (select id from public.consultas where paciente_id = '$PACIENTE_ID');
delete from public.consultas where paciente_id = '$PACIENTE_ID';
delete from public.citas where persona_id = '$PACIENTE_ID';
delete from public.pacientes where id = '$PACIENTE_ID';
delete from public.personas where id = '$PACIENTE_ID';
SQL
  for uid in "${USUARIOS[@]:-}"; do
    [[ -z "$uid" ]] && continue
    curl -s -X DELETE "$API_URL/auth/v1/admin/users/$uid" \
      -H "apikey: $SERVICE_ROLE_KEY" \
      -H "Authorization: Bearer $SERVICE_ROLE_KEY" >/dev/null || true
    psql "$PGURL" -q -v ON_ERROR_STOP=0 -c "
      delete from public.admins where id='$uid';
      delete from public.asistentes where id='$uid';
      delete from public.doctores where id='$uid';
      delete from public.usuarios where id='$uid';
      delete from public.persona_contactos where persona_id='$uid';
      delete from public.personas where id='$uid';" >/dev/null 2>&1 || true
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
  [[ -n "$NUEVO_ID" ]] || fallo "alta local: $respuesta"
  USUARIOS+=("$NUEVO_ID")
}

login() {
  curl -s -X POST "$API_URL/auth/v1/token?grant_type=password" \
    -H "apikey: $ANON_KEY" -H 'Content-Type: application/json' \
    -d "{\"email\":\"$1\",\"password\":\"$PASSWORD\"}" |
    jq -r '.access_token // empty'
}

crear_usuario "hfx001.admin.$SUFIJO@local.test" \
  "{\"rol\":\"admin\",\"nombre\":\"Ana\",\"apellido\":\"Admin\",\"fecha_nacimiento\":\"1980-01-01\",\"cedula\":\"HFX001-A-$SUFIJO\",\"username\":\"hfx001_a_$SUFIJO\",\"especialidad\":\"General\",\"departamento\":\"Dirección\"}"
ADMIN_ID="$NUEVO_ID"
crear_usuario "hfx001.doctor.a.$SUFIJO@local.test" \
  "{\"rol\":\"doctor\",\"nombre\":\"Dora\",\"apellido\":\"Autora\",\"fecha_nacimiento\":\"1981-01-01\",\"cedula\":\"HFX001-D1-$SUFIJO\",\"username\":\"hfx001_d1_$SUFIJO\",\"especialidad\":\"General\"}"
DOCTOR_A_ID="$NUEVO_ID"
crear_usuario "hfx001.doctor.b.$SUFIJO@local.test" \
  "{\"rol\":\"doctor\",\"nombre\":\"Dino\",\"apellido\":\"Ajeno\",\"fecha_nacimiento\":\"1982-01-01\",\"cedula\":\"HFX001-D2-$SUFIJO\",\"username\":\"hfx001_d2_$SUFIJO\",\"especialidad\":\"General\"}"
DOCTOR_B_ID="$NUEVO_ID"
crear_usuario "hfx001.asistente.$SUFIJO@local.test" \
  "{\"rol\":\"asistente\",\"nombre\":\"Rita\",\"apellido\":\"Recepción\",\"fecha_nacimiento\":\"1990-01-01\",\"cedula\":\"HFX001-AS-$SUFIJO\",\"username\":\"hfx001_as_$SUFIJO\",\"turno\":\"matutino\"}"
ASISTENTE_ID="$NUEVO_ID"

TOKEN_ADMIN=$(login "hfx001.admin.$SUFIJO@local.test")
TOKEN_DOCTOR_A=$(login "hfx001.doctor.a.$SUFIJO@local.test")
TOKEN_ASISTENTE=$(login "hfx001.asistente.$SUFIJO@local.test")
[[ -n "$TOKEN_ADMIN" && -n "$TOKEN_DOCTOR_A" && -n "$TOKEN_ASISTENTE" ]] ||
  fallo 'login de actores'

mapfile -t CONSULTAS < <(
  psql "$PGURL" -qAt -v ON_ERROR_STOP=1 <<SQL
insert into public.personas(id,nombre,apellido,fecha_nacimiento,cedula)
values ('$PACIENTE_ID','Paz','Paciente','1995-01-01','HFX001-P-$SUFIJO');
insert into public.pacientes(id,genero) values ('$PACIENTE_ID','femenino');
with c as (
  insert into public.citas(persona_id,doctor_id,fecha_hora,duracion_minutos)
  values ('$PACIENTE_ID','$DOCTOR_A_ID',now()+interval '1 day',30) returning id
) insert into public.consultas(paciente_id,doctor_id,cita_id,fecha,notas)
  select '$PACIENTE_ID','$DOCTOR_A_ID',id,now(),'original A' from c returning id;
with c as (
  insert into public.citas(persona_id,doctor_id,fecha_hora,duracion_minutos)
  values ('$PACIENTE_ID','$DOCTOR_B_ID',now()+interval '2 day',30) returning id
) insert into public.consultas(paciente_id,doctor_id,cita_id,fecha,notas)
  select '$PACIENTE_ID','$DOCTOR_B_ID',id,now(),'original B' from c returning id;
SQL
)
CONSULTA_A="${CONSULTAS[0]:-}"
CONSULTA_B="${CONSULTAS[1]:-}"
[[ -n "$CONSULTA_A" && -n "$CONSULTA_B" ]] || fallo 'preparación clínica local'

codigo=$(curl -s -o /tmp/hfx001_anon.json -w '%{http_code}' \
  -X POST "$API_URL/rest/v1/rpc/finalizar_consulta" \
  -H "apikey: $ANON_KEY" -H 'Content-Type: application/json' \
  -d "{\"p_consulta_id\":\"$CONSULTA_A\"}")
[[ "$codigo" == 401 || "$codigo" == 403 ]] ||
  fallo "anon recibió HTTP $codigo: $(cat /tmp/hfx001_anon.json)"
ok 'anon no ejecuta mutaciones clínicas'

codigo=$(curl -s -o /tmp/hfx001_expirado.json -w '%{http_code}' \
  "$API_URL/rest/v1/consultas?select=id&limit=1" \
  -H "apikey: $ANON_KEY" -H 'Authorization: Bearer token.expirado.invalido')
[[ "$codigo" == 401 ]] || fallo "token inválido recibió HTTP $codigo"
ok 'token inválido/expirado se rechaza antes de RLS'

codigo=$(curl -s -o /tmp/hfx001_asistente.json -w '%{http_code}' \
  -X POST "$API_URL/rest/v1/recetas" \
  -H "apikey: $ANON_KEY" -H "Authorization: Bearer $TOKEN_ASISTENTE" \
  -H 'Content-Type: application/json' -H 'Prefer: return=representation' \
  -d "{\"consulta_id\":\"$CONSULTA_A\",\"doctor_id\":\"$DOCTOR_A_ID\",\"items_receta\":[]}")
[[ "$codigo" == 401 || "$codigo" == 403 ]] ||
  fallo "asistente insertó receta (HTTP $codigo)"
ok 'asistente no receta mediante REST'

respuesta=$(curl -s -X PATCH \
  "$API_URL/rest/v1/consultas?id=eq.$CONSULTA_B&select=id,notas" \
  -H "apikey: $ANON_KEY" -H "Authorization: Bearer $TOKEN_DOCTOR_A" \
  -H 'Content-Type: application/json' -H 'Prefer: return=representation' \
  -d '{"notas":"intrusión REST"}')
[[ "$(jq 'length' <<<"$respuesta")" == 0 ]] ||
  fallo "doctor modificó consulta ajena: $respuesta"
ok 'doctor no modifica consulta ajena mediante REST'

codigo=$(curl -s -o /tmp/hfx001_trigger.json -w '%{http_code}' \
  -X POST "$API_URL/rest/v1/rpc/update_timestamp" \
  -H "apikey: $ANON_KEY" -H "Authorization: Bearer $TOKEN_DOCTOR_A" \
  -H 'Content-Type: application/json' -d '{}')
[[ "$codigo" == 401 || "$codigo" == 403 || "$codigo" == 404 ]] ||
  fallo "función trigger fue invocable (HTTP $codigo)"
ok 'funciones de trigger no son endpoints utilizables'

codigo=$(curl -s -o /tmp/hfx001_documento_publico.json -w '%{http_code}' \
  "$API_URL/storage/v1/object/public/documentos-clinicos/no-existe.pdf")
[[ "$codigo" != 200 ]] ||
  fallo 'el bucket de documentos clínicos sigue sirviendo URLs públicas'
ok 'documentos clínicos no son accesibles por URL pública'

curl -fsS -X POST "$API_URL/rest/v1/rpc/corregir_consulta_ajena" \
  -H "apikey: $ANON_KEY" -H "Authorization: Bearer $TOKEN_ADMIN" \
  -H 'Content-Type: application/json' \
  -d "{\"p_consulta_id\":\"$CONSULTA_B\",\"p_cambios\":{\"notas\":\"corrección REST\"},\"p_motivo\":\"Corrección administrativa REST\"}" >/dev/null

auditoria=$(curl -fsS \
  "$API_URL/rest/v1/auditoria_correcciones_clinicas?consulta_id=eq.$CONSULTA_B&select=autor_original_id,corregido_por" \
  -H "apikey: $ANON_KEY" -H "Authorization: Bearer $TOKEN_ADMIN")
[[ "$(jq -r '.[0].autor_original_id' <<<"$auditoria")" == "$DOCTOR_B_ID" ]] ||
  fallo 'auditoría perdió autor original'
[[ "$(jq -r '.[0].corregido_por' <<<"$auditoria")" == "$ADMIN_ID" ]] ||
  fallo 'auditoría no registró al admin'
ok 'corrección administrativa REST conserva autor y registra actor'

respuesta=$(curl -s "$API_URL/rest/v1/usuarios?select=*" \
  -H "apikey: $ANON_KEY" -H "Authorization: Bearer $TOKEN_ADMIN")
[[ "$(jq -r 'if type=="array" then any(.[]; has("password_hash")) else false end' <<<"$respuesta")" == false ]] ||
  fallo 'PostgREST expuso password_hash'
ok 'ninguna fila de usuarios expone password_hash'

echo 'SMOKE HFX-CLIN-001 COMPLETO · REST ofensivo por rol.'
