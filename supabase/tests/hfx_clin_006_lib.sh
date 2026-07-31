#!/usr/bin/env bash
# HFX-CLIN-006 · utilidades compartidas por las jornadas de certificación.
#
# Todo pasa por REST con el JWT de quien lo haría en la clínica: así se ejercen
# de verdad los grants, la RLS y las autorizaciones internas de cada RPC. Nada
# de `set role`, que se salta el JWT y deja pasar cosas que por HTTP fallarían.
#
# Se carga con `source`; no se ejecuta directamente.

API_URL="${API_URL:-http://127.0.0.1:54321}"
PGURL="${PGURL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
PASSWORD_CERT="${PASSWORD_CERT:-Cert-2026!}"

env_supabase() {
  npx supabase status -o env 2>/dev/null | grep "^$1=" | cut -d= -f2- | tr -d '"'
}
ANON_KEY="${ANON_KEY:-$(env_supabase ANON_KEY)}"
SERVICE_ROLE_KEY="${SERVICE_ROLE_KEY:-$(env_supabase SERVICE_ROLE_KEY)}"

COMPROBACIONES=0

fallo() { echo "FALLO · $1" >&2; exit 1; }
ok()    { COMPROBACIONES=$((COMPROBACIONES + 1)); echo "OK   · $1"; }
paso()  { echo; echo "── $1"; }

sql()   { psql "$PGURL" -qAt -c "$1"; }

# Carga el seed si la base todavía no lo tiene. Es idempotente, así que
# ejecutar una jornada dos veces no duplica la agenda.
asegurar_seed() {
  local raiz
  raiz="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  psql "$PGURL" -q -v ON_ERROR_STOP=1 \
    -f "$raiz/hfx_clin_006_seed_certificacion.sql" >/dev/null
}

# `supabase db reset` reinicia el contenedor de Auth con una IP nueva, pero Kong
# no se reinicia y conserva la anterior en su caché de DNS. El resultado es un
# 502 —«An invalid response was received from the upstream server»— que no tiene
# nada que ver con las credenciales y que **no se cura esperando**: hay que
# reiniciar Kong. Sin esto, una jornada lanzada tras un reset falla con «los
# actores no pueden iniciar sesión» y se pierde el rato buscando en el seed.
auth_sana() {
  [[ "$(curl -s -o /dev/null -w '%{http_code}' "$API_URL/auth/v1/health" \
        -H "apikey: $ANON_KEY")" == '200' ]]
}

esperar_auth() {
  local intento
  for intento in 1 2 3 4 5; do
    auth_sana && return 0
    sleep 1
  done

  echo '··· Kong sirve una instancia de Auth que ya no existe; se reinicia.' >&2
  docker restart supabase_kong_supabase >/dev/null 2>&1 ||
    fallo 'Auth no responde y no se pudo reiniciar Kong'

  for intento in $(seq 1 30); do
    auth_sana && return 0
    sleep 1
  done
  fallo 'el servicio de autenticación no respondió tras reiniciar Kong'
}

login() {
  curl -s -X POST "$API_URL/auth/v1/token?grant_type=password" \
    -H "apikey: $ANON_KEY" -H 'Content-Type: application/json' \
    -d "{\"email\":\"$1\",\"password\":\"$PASSWORD_CERT\"}" |
    jq -r '.access_token // empty'
}

# El código HTTP viaja por fichero y no por variable: casi toda llamada se
# escribe como `respuesta=$(rpc ...)`, que corre en una subshell, y una
# asignación hecha allí nunca llega al proceso padre. Una comprobación de
# `$HTTP` leería entonces el código de la llamada *anterior* y daría por buena
# una petición que falló.
HTTP_FILE="${TMPDIR:-/tmp}/hfx006_http.$$"
trap 'rm -f "$HTTP_FILE" "${TMPDIR:-/tmp}"/hfx006_cuerpo.$$' EXIT

# Devuelve el código de la última llamada hecha con `rpc` o `rest`.
http() { cat "$HTTP_FILE" 2>/dev/null || echo '000'; }

_llamar() {
  local salida="${TMPDIR:-/tmp}/hfx006_cuerpo.$$"
  curl -s -o "$salida" -w '%{http_code}' "$@" >"$HTTP_FILE"
  cat "$salida"
}

# rpc <token> <nombre> <json>  → imprime el cuerpo; el código queda en `http`.
rpc() {
  local token="$1" nombre="$2" cuerpo="${3:-{\}}"
  _llamar -X POST "$API_URL/rest/v1/rpc/$nombre" \
    -H "apikey: $ANON_KEY" -H "Authorization: Bearer $token" \
    -H 'Content-Type: application/json' -d "$cuerpo"
}

# rest <token> <método> <ruta> [json] → igual, contra el REST de tablas.
rest() {
  local token="$1" metodo="$2" ruta="$3" cuerpo="${4:-}"
  _llamar -X "$metodo" "$API_URL/rest/v1/$ruta" \
    -H "apikey: $ANON_KEY" -H "Authorization: Bearer $token" \
    -H 'Content-Type: application/json' \
    -H 'Prefer: return=representation' \
    ${cuerpo:+-d "$cuerpo"}
}

# Identificadores del seed, resueltos una vez por ejecución.
cargar_identificadores() {
  esperar_auth

  ADMIN_ID=$(sql "select id from personas where cedula='CERT-ADMIN'")
  DOCTORA_ID=$(sql "select id from personas where cedula='CERT-DOCTORA'")
  ASISTENTE_ID=$(sql "select id from personas where cedula='CERT-ASIST'")

  PAC_SANO=$(sql      "select id from personas where cedula='CERT-PAC-001'")
  PAC_EMBARAZO=$(sql  "select id from personas where cedula='CERT-PAC-002'")
  PAC_HIPERTEN=$(sql  "select id from personas where cedula='CERT-PAC-003'")
  PAC_DIABETES=$(sql  "select id from personas where cedula='CERT-PAC-004'")
  PAC_ALERGICA=$(sql  "select id from personas where cedula='CERT-PAC-005'")
  PAC_PEDIATRICO=$(sql "select id from personas where cedula='CERT-PAC-006'")
  PAC_URGENCIA=$(sql  "select id from personas where cedula='CERT-PAC-008'")

  MED_AMOXI=$(sql   "select id from medicinas where nombre='Amoxicilina 500 mg'")
  MED_IBU=$(sql     "select id from medicinas where nombre='Ibuprofeno 400 mg'")
  MED_PARACET=$(sql "select id from medicinas where nombre='Paracetamol 500 mg'")

  TRAT_PROFILAXIS=$(sql "select id from tratamientos where nombre='Profilaxis dental'")
  TRAT_RESINA=$(sql     "select id from tratamientos where nombre='Resina compuesta'")
  TRAT_ENDO=$(sql       "select id from tratamientos where nombre='Endodoncia unirradicular'")

  DIAG_CARIES=$(sql     "select id from diagnosticos where nombre='Caries dental'")
  DIAG_PERIODONT=$(sql  "select id from diagnosticos where nombre='Periodontitis crónica'")

  CONS_ANESTESIA=$(sql "select id from consumibles where nombre='Anestesia lidocaína 2%'")
  CONS_LIMA=$(sql      "select id from consumibles where nombre='Lima endodóntica K-15'")

  COND_EMBARAZO=$(sql "select id from condiciones where nombre='Embarazo'")
  COND_ALERGIA=$(sql  "select id from condiciones where nombre='Alergia a la penicilina'")

  TOKEN_ADMIN=$(login 'cert.admin@cert.local')
  TOKEN_DOCTORA=$(login 'cert.doctora@cert.local')
  TOKEN_ASISTENTE=$(login 'cert.asistente@cert.local')
  [[ -n "$TOKEN_ADMIN" && -n "$TOKEN_DOCTORA" && -n "$TOKEN_ASISTENTE" ]] ||
    fallo 'los tres actores del seed deben poder iniciar sesión'
}

# La cita del seed de un paciente con el doctor indicado.
cita_de() {
  sql "select id from citas
        where persona_id='$1' and doctor_id='$2' and deleted_at is null
        order by fecha_hora limit 1"
}

# La dentición permanente en notación FDI, que es lo que la app manda al abrir
# la consulta: el odontograma nace con sus piezas o no hay dónde colgar un
# hallazgo por diente.
DENTICION_FDI='[{"fdi_code":18},{"fdi_code":17},{"fdi_code":16},{"fdi_code":15},
{"fdi_code":14},{"fdi_code":13},{"fdi_code":12},{"fdi_code":11},
{"fdi_code":21},{"fdi_code":22},{"fdi_code":23},{"fdi_code":24},
{"fdi_code":25},{"fdi_code":26},{"fdi_code":27},{"fdi_code":28},
{"fdi_code":38},{"fdi_code":37},{"fdi_code":36},{"fdi_code":35},
{"fdi_code":34},{"fdi_code":33},{"fdi_code":32},{"fdi_code":31},
{"fdi_code":41},{"fdi_code":42},{"fdi_code":43},{"fdi_code":44},
{"fdi_code":45},{"fdi_code":46},{"fdi_code":47},{"fdi_code":48}]'

# Abre la consulta de una cita: registra la llegada y la inicia. Sin llegada no
# hay consulta —es una decisión de HFX-CLIN-004, no un descuido—.
abrir_consulta() {
  local token="$1" cita="$2" respuesta
  rpc "$token" registrar_llegada_cita "{\"p_cita_id\":\"$cita\"}" >/dev/null
  [[ "$(http)" == "200" ]] || fallo "no se pudo registrar la llegada (HTTP $(http))"
  respuesta=$(rpc "$token" iniciar_consulta_de_cita \
    "{\"p_cita_id\":\"$cita\",\"p_dientes\":$DENTICION_FDI}")
  CONSULTA_ID=$(jq -r '.consulta_id // empty' <<<"$respuesta")
  [[ -n "$CONSULTA_ID" ]] || fallo "no se pudo abrir la consulta: $respuesta"
}

version_consulta() {
  sql "select version from consultas where id='$1'"
}

# Resuelve todas las alertas pendientes de una consulta documentando el motivo.
# Es lo que hace el doctor en pantalla antes de poder cerrar.
documentar_alertas() {
  local token="$1" consulta="$2" justificacion="$3" alerta
  for alerta in $(sql "select id from alertas_clinicas
                        where consulta_id='$consulta' and estado='pendiente'"); do
    rpc "$token" resolver_alerta_clinica \
      "{\"p_alerta_id\":\"$alerta\",\"p_estado\":\"documentada\",\"p_justificacion\":\"$justificacion\"}" \
      >/dev/null
    [[ "$(http)" == "200" ]] || fallo "no se pudo documentar la alerta (HTTP $(http))"
  done
}

resumen() {
  echo
  echo "════════════════════════════════════════════════════════════"
  echo "$1 · $COMPROBACIONES comprobaciones superadas."
  echo "════════════════════════════════════════════════════════════"
}
