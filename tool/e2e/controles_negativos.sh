#!/usr/bin/env bash
# HFX-QA-105 · Controles negativos por API, con el token real de cada rol.
#
# Paso 5 del plan de QA del 1 ago 2026. Ocultar un botón no es una defensa: lo
# que decide es la RLS. Aquí se intenta, con `curl` y el token de cada rol,
# exactamente lo que la interfaz ya no ofrece, y se exige que la base lo
# rechace.
#
# Se ejecuta contra el stack LOCAL. Nunca contra producción: crea usuarios,
# pacientes y citas.
#
#   tool/e2e/controles_negativos.sh
#
# Complementa a supabase/tests/hfx_qa_103_matriz_permisos_test.sql, que prueba
# lo mismo desde dentro de la base. Los dos hacen falta: el de SQL entra con
# `set role authenticated` y este atraviesa PostgREST, que es el camino real.

set -uo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$RAIZ"

API_URL="${API_URL:-http://127.0.0.1:54321}"
PGURL="${PGURL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
EVIDENCIA="${EVIDENCIA:-$RAIZ/docs/qa/e2e-ui}"
mkdir -p "$EVIDENCIA"

env_supabase() { supabase status -o env 2>/dev/null | grep "^$1=" | cut -d= -f2- | tr -d '"'; }
ANON_KEY="${ANON_KEY:-$(env_supabase ANON_KEY)}"
SERVICE_ROLE_KEY="${SERVICE_ROLE_KEY:-$(env_supabase SERVICE_ROLE_KEY)}"
[[ -n "$ANON_KEY" && -n "$SERVICE_ROLE_KEY" ]] || {
  echo 'FALLO · no se pudieron leer las claves del stack local (¿supabase start?)'
  exit 2
}

PASSWORD='QA105-Negativos!'
SUFIJO="$RANDOM$RANDOM"
PACIENTE_ID="$(printf '%08x-0000-4000-8000-00000000a105' "$RANDOM")"
declare -a USUARIOS=()
FALLOS=0

fallo() { echo "FALLO · $1" >&2; FALLOS=$((FALLOS + 1)); }
ok() { echo "OK    · $1"; }

limpiar() {
  psql "$PGURL" -q -v ON_ERROR_STOP=0 >/dev/null 2>&1 <<SQL || true
delete from public.citas where persona_id = '$PACIENTE_ID';
delete from public.consultas where paciente_id = '$PACIENTE_ID';
delete from public.doctor_paciente where paciente_id = '$PACIENTE_ID';
delete from public.records where paciente_id = '$PACIENTE_ID';
delete from public.pacientes where id = '$PACIENTE_ID';
delete from public.personas where id = '$PACIENTE_ID';
delete from public.tratamientos where nombre = 'QA105 tratamiento $SUFIJO';
SQL
  for uid in "${USUARIOS[@]:-}"; do
    [[ -z "$uid" ]] && continue
    curl -s -X DELETE "$API_URL/auth/v1/admin/users/$uid" \
      -H "apikey: $SERVICE_ROLE_KEY" -H "Authorization: Bearer $SERVICE_ROLE_KEY" >/dev/null || true
    psql "$PGURL" -q -v ON_ERROR_STOP=0 >/dev/null 2>&1 -c "
      delete from public.doctor_asistentes where doctor_id='$uid' or asistente_id='$uid';
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
    -H "apikey: $SERVICE_ROLE_KEY" -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"$email\",\"password\":\"$PASSWORD\",\"email_confirm\":true,\"user_metadata\":$metadata}")
  NUEVO_ID=$(jq -r '.id // empty' <<<"$respuesta")
  [[ -n "$NUEVO_ID" ]] || { echo "FALLO · alta de $email: $respuesta"; exit 2; }
  USUARIOS+=("$NUEVO_ID")
}

login() {
  curl -s -X POST "$API_URL/auth/v1/token?grant_type=password" \
    -H "apikey: $ANON_KEY" -H 'Content-Type: application/json' \
    -d "{\"email\":\"$1\",\"password\":\"$PASSWORD\"}" | jq -r '.access_token // empty'
}

# `%{http_code}` del cuerpo y el cuerpo por separado, para poder explicar el
# fallo cuando lo haya.
peticion() {
  local metodo="$1" ruta="$2" token="$3" cuerpo="${4:-}"
  local args=(-s -o /tmp/qa105_respuesta.json -w '%{http_code}'
              -X "$metodo" "$API_URL/rest/v1/$ruta"
              -H "apikey: $ANON_KEY" -H "Authorization: Bearer $token"
              -H 'Content-Type: application/json' -H 'Prefer: return=representation')
  [[ -n "$cuerpo" ]] && args+=(-d "$cuerpo")
  curl "${args[@]}"
}

detalle() { head -c 300 /tmp/qa105_respuesta.json; }

echo '▶ Creando actores'
crear_usuario "qa105.admin.$SUFIJO@local.test" \
  "{\"rol\":\"admin\",\"nombre\":\"Ada\",\"apellido\":\"Admin\",\"fecha_nacimiento\":\"1980-01-01\",\"cedula\":\"QA105-A-$SUFIJO\",\"username\":\"qa105_a_$SUFIJO\",\"especialidad\":\"General\",\"departamento\":\"Dirección\"}"
ADMIN_ID="$NUEVO_ID"
crear_usuario "qa105.doctor.$SUFIJO@local.test" \
  "{\"rol\":\"doctor\",\"nombre\":\"Dora\",\"apellido\":\"Doctora\",\"fecha_nacimiento\":\"1981-01-01\",\"cedula\":\"QA105-D-$SUFIJO\",\"username\":\"qa105_d_$SUFIJO\",\"especialidad\":\"General\"}"
DOCTOR_ID="$NUEVO_ID"
crear_usuario "qa105.doctor2.$SUFIJO@local.test" \
  "{\"rol\":\"doctor\",\"nombre\":\"Beto\",\"apellido\":\"Ajeno\",\"fecha_nacimiento\":\"1982-01-01\",\"cedula\":\"QA105-D2-$SUFIJO\",\"username\":\"qa105_d2_$SUFIJO\",\"especialidad\":\"General\"}"
DOCTOR_AJENO_ID="$NUEVO_ID"
crear_usuario "qa105.asistente.$SUFIJO@local.test" \
  "{\"rol\":\"asistente\",\"nombre\":\"Clara\",\"apellido\":\"Recepción\",\"fecha_nacimiento\":\"1990-01-01\",\"cedula\":\"QA105-AS-$SUFIJO\",\"username\":\"qa105_as_$SUFIJO\",\"turno\":\"matutino\"}"
ASISTENTE_ID="$NUEVO_ID"

TOKEN_ADMIN=$(login "qa105.admin.$SUFIJO@local.test")
TOKEN_DOCTOR=$(login "qa105.doctor.$SUFIJO@local.test")
TOKEN_ASISTENTE=$(login "qa105.asistente.$SUFIJO@local.test")
[[ -n "$TOKEN_ADMIN" && -n "$TOKEN_DOCTOR" && -n "$TOKEN_ASISTENTE" ]] || {
  echo 'FALLO · no se pudo autenticar a los actores'; exit 2; }
echo '  ✓ actores autenticados'

echo '▶ Sembrando paciente, cita y tratamiento'
SEMILLA=$(psql "$PGURL" -qAt -v ON_ERROR_STOP=1 <<SQL
insert into public.personas(id,nombre,apellido,fecha_nacimiento,cedula)
values ('$PACIENTE_ID','Zoila','Paciente QA105','1995-01-01','QA105-P-$SUFIJO');
insert into public.pacientes(id,genero) values ('$PACIENTE_ID','femenino');
-- La asistente asiste al doctor propio y NO al ajeno: es lo que hace medible
-- el alcance de D12.
insert into public.doctor_asistentes(doctor_id,asistente_id)
values ('$DOCTOR_ID','$ASISTENTE_ID');
insert into public.tratamientos(nombre,costo,alcance)
values ('QA105 tratamiento $SUFIJO', 1500, 'puntual') returning id;
SQL
)
TRATAMIENTO_ID=$(tail -1 <<<"$SEMILLA")

CITAS=$(psql "$PGURL" -qAt -v ON_ERROR_STOP=1 <<SQL
insert into public.citas(persona_id,doctor_id,fecha_hora,duracion_minutos,estado)
values ('$PACIENTE_ID','$DOCTOR_ID',now()+interval '1 day',30,'programada') returning id;
insert into public.citas(persona_id,doctor_id,fecha_hora,duracion_minutos,estado)
values ('$PACIENTE_ID','$DOCTOR_AJENO_ID',now()+interval '2 day',30,'programada') returning id;
SQL
)
CITA_PROPIA=$(sed -n '1p' <<<"$CITAS")
CITA_AJENA=$(sed -n '2p' <<<"$CITAS")
[[ -n "$TRATAMIENTO_ID" && -n "$CITA_PROPIA" && -n "$CITA_AJENA" ]] || {
  echo 'FALLO · no se pudo sembrar el escenario'; exit 2; }
echo '  ✓ escenario sembrado'

echo
echo '▶ D8 · el doctor no escribe el catálogo'

codigo=$(peticion PATCH "tratamientos?id=eq.$TRATAMIENTO_ID" "$TOKEN_DOCTOR" '{"costo":99999}')
# RLS sobre un UPDATE no lanza 403: filtra las filas y devuelve 200 con lista
# vacía. Lo que se comprueba es que NO cambió nada.
COSTO=$(psql "$PGURL" -qAt -c "select costo from public.tratamientos where id='$TRATAMIENTO_ID'")
if [[ "${COSTO%%.*}" == '1500' ]]; then
  ok "el doctor no cambió el precio (HTTP $codigo, costo sigue en $COSTO)"
else
  fallo "el doctor cambió el precio a $COSTO (HTTP $codigo)"
fi

codigo=$(peticion POST 'tratamientos' "$TOKEN_DOCTOR" \
  "{\"nombre\":\"QA105 intruso $SUFIJO\",\"costo\":1,\"alcance\":\"puntual\"}")
if [[ "$codigo" == 40* ]]; then
  ok "el doctor no crea tratamientos (HTTP $codigo)"
else
  fallo "el doctor creó un tratamiento (HTTP $codigo): $(detalle)"
fi

codigo=$(peticion DELETE "tratamientos?id=eq.$TRATAMIENTO_ID" "$TOKEN_DOCTOR")
EXISTE=$(psql "$PGURL" -qAt -c "select count(*) from public.tratamientos where id='$TRATAMIENTO_ID'")
if [[ "$EXISTE" == '1' ]]; then
  ok "el doctor no borra del catálogo (HTTP $codigo)"
else
  fallo "el doctor borró un tratamiento del catálogo (HTTP $codigo)"
fi

codigo=$(peticion PATCH "tratamientos?id=eq.$TRATAMIENTO_ID" "$TOKEN_ADMIN" '{"costo":1600}')
COSTO=$(psql "$PGURL" -qAt -c "select costo from public.tratamientos where id='$TRATAMIENTO_ID'")
if [[ "${COSTO%%.*}" == '1600' ]]; then
  ok 'control positivo: el admin sí edita el catálogo'
else
  fallo "el admin NO pudo editar el catálogo (HTTP $codigo, costo $COSTO)"
fi

echo
echo '▶ D12 · alcance y estados de la asistente'

VISIBLES=$(curl -s "$API_URL/rest/v1/citas?select=id&id=eq.$CITA_AJENA" \
  -H "apikey: $ANON_KEY" -H "Authorization: Bearer $TOKEN_ASISTENTE" | jq 'length')
if [[ "$VISIBLES" == '0' ]]; then
  ok 'la asistente no ve la cita de un doctor que no asiste'
else
  fallo "la asistente vio $VISIBLES cita(s) de un doctor que no asiste"
fi

VISIBLES=$(curl -s "$API_URL/rest/v1/citas?select=id&id=eq.$CITA_PROPIA" \
  -H "apikey: $ANON_KEY" -H "Authorization: Bearer $TOKEN_ASISTENTE" | jq 'length')
if [[ "$VISIBLES" == '1' ]]; then
  ok 'control positivo: la asistente sí ve la del doctor que asiste'
else
  fallo 'la asistente no ve la cita del doctor que asiste'
fi

# `en_espera` es legal en el grafo desde `programada`, así que lo que decide es
# la matriz de roles.
codigo=$(peticion PATCH "citas?id=eq.$CITA_PROPIA" "$TOKEN_ASISTENTE" '{"estado":"en_espera"}')
ESTADO=$(psql "$PGURL" -qAt -c "select estado from public.citas where id='$CITA_PROPIA'")
if [[ "$ESTADO" == 'en_espera' ]]; then
  ok 'la asistente sí registra la llegada (administrativo)'
else
  fallo "la asistente no pudo registrar la llegada (HTTP $codigo, estado $ESTADO)"
fi

codigo=$(peticion PATCH "citas?id=eq.$CITA_PROPIA" "$TOKEN_ASISTENTE" '{"estado":"en_consulta"}')
ESTADO=$(psql "$PGURL" -qAt -c "select estado from public.citas where id='$CITA_PROPIA'")
if [[ "$ESTADO" != 'en_consulta' ]]; then
  ok "la asistente no pone una cita en consulta (HTTP $codigo, sigue en $ESTADO)"
else
  fallo 'la asistente puso una cita en_consulta por API'
fi

echo
echo '▶ D12 · estados que el doctor no cambia'

codigo=$(peticion PATCH "citas?id=eq.$CITA_PROPIA" "$TOKEN_DOCTOR" '{"estado":"no_asistio"}')
ESTADO=$(psql "$PGURL" -qAt -c "select estado from public.citas where id='$CITA_PROPIA'")
if [[ "$ESTADO" != 'no_asistio' ]]; then
  ok "el doctor no marca la inasistencia (HTTP $codigo, sigue en $ESTADO)"
else
  fallo 'el doctor marcó no_asistio por API'
fi

codigo=$(peticion PATCH "citas?id=eq.$CITA_AJENA" "$TOKEN_DOCTOR" '{"estado":"cancelada"}')
ESTADO=$(psql "$PGURL" -qAt -c "select estado from public.citas where id='$CITA_AJENA'")
if [[ "$ESTADO" != 'cancelada' ]]; then
  ok "el doctor no toca la cita de otro doctor (HTTP $codigo, sigue en $ESTADO)"
else
  fallo 'el doctor canceló la cita de otro doctor'
fi

echo
echo '▶ D11 (TEMPORAL) · la lectura de consultas ajenas está abierta'

CONSULTA_AJENA=$(psql "$PGURL" -qAt -v ON_ERROR_STOP=1 -c "
  insert into public.consultas(paciente_id,doctor_id,fecha,motivo_consulta)
  values ('$PACIENTE_ID','$DOCTOR_AJENO_ID',now(),'Consulta ajena QA105')
  returning id")

VISIBLES=$(curl -s "$API_URL/rest/v1/consultas?select=id&id=eq.$CONSULTA_AJENA" \
  -H "apikey: $ANON_KEY" -H "Authorization: Bearer $TOKEN_DOCTOR" | jq 'length')
if [[ "$VISIBLES" == '1' ]]; then
  ok 'el doctor lee la consulta de otro doctor (decisión D11, temporal)'
else
  fallo 'la decisión D11 dice que el doctor lee cualquier consulta, y no la vio'
fi

codigo=$(peticion PATCH "consultas?id=eq.$CONSULTA_AJENA" "$TOKEN_DOCTOR" '{"notas":"intruso"}')
NOTAS=$(psql "$PGURL" -qAt -c "select coalesce(notas,'') from public.consultas where id='$CONSULTA_AJENA'")
if [[ "$NOTAS" != 'intruso' ]]; then
  ok "leer no es firmar: no escribió sobre la consulta ajena (HTTP $codigo)"
else
  fallo 'el doctor escribió sobre una consulta que no es suya'
fi

echo
echo '▶ D9/D13 · el doctor no llega al dinero'

codigo=$(peticion POST 'rpc/marcar_cuotas_vencidas' "$TOKEN_DOCTOR" \
  "{\"p_cuenta_id\":\"00000000-0000-4000-8000-000000000000\"}")
if [[ "$codigo" == 40* ]]; then
  ok "el doctor no ejecuta marcar_cuotas_vencidas (HTTP $codigo)"
else
  fallo "el doctor ejecutó una RPC de caja (HTTP $codigo): $(detalle)"
fi

echo
echo '▶ HFX-CLIN-009 · la bitácora sigue cerrada al cliente'
codigo=$(peticion GET 'auditoria_log?select=id&limit=1' "$TOKEN_ADMIN")
if [[ "$codigo" == 40* ]]; then
  ok "ni el admin lee auditoria_log por la API (HTTP $codigo)"
else
  fallo "auditoria_log quedó legible por la API (HTTP $codigo): $(detalle)"
fi

echo
if [[ "$FALLOS" -eq 0 ]]; then
  echo '✓ Todos los controles negativos se comportaron como debe.'
else
  echo "✗ $FALLOS control(es) negativo(s) fallaron."
fi
exit "$FALLOS"
