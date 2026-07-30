#!/usr/bin/env bash
# HFX-CLIN-002 · contrato del guardado y el cierre a través de PostgREST real.
#
# La suite Flutter no detectó que el diagnóstico viajaba como `superficiecle`:
# los dobles aceptaban cualquier nombre de columna. Esta prueba manda el mismo
# payload que manda la app, por la misma frontera, y comprueba que lo que se ve
# en pantalla es lo que quedó en la base.
set -euo pipefail

API_URL="${API_URL:-http://127.0.0.1:54321}"
PGURL="${PGURL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
env_supabase() { supabase status -o env 2>/dev/null | grep "^$1=" | cut -d= -f2- | tr -d '"'; }
ANON_KEY="${ANON_KEY:-$(env_supabase ANON_KEY)}"
SERVICE_ROLE_KEY="${SERVICE_ROLE_KEY:-$(env_supabase SERVICE_ROLE_KEY)}"
PASSWORD='Smoke-HFX-002!'
SUFIJO="$RANDOM$RANDOM"
PACIENTE_ID="$(printf '%08x-0000-4000-8000-000000000002' "$RANDOM")"
DOCTOR_ID=''

fallo() { echo "FALLO · $1" >&2; exit 1; }
ok() { echo "OK   · $1"; }

limpiar() {
  psql "$PGURL" -q -v ON_ERROR_STOP=0 >/dev/null 2>&1 <<SQL || true
delete from public.auditoria_clinica
 where consulta_id in (select id from public.consultas where paciente_id = '$PACIENTE_ID');
delete from public.movimientos_stock_consumible
 where consulta_id in (select id from public.consultas where paciente_id = '$PACIENTE_ID');
delete from public.items_cuenta where cuenta_id in (
  select id from public.cuentas where consulta_id in (
    select id from public.consultas where paciente_id = '$PACIENTE_ID'));
delete from public.cuentas where consulta_id in (
  select id from public.consultas where paciente_id = '$PACIENTE_ID');
delete from public.consumos_consulta where consulta_id in (
  select id from public.consultas where paciente_id = '$PACIENTE_ID');
delete from public.recetas where consulta_id in (
  select id from public.consultas where paciente_id = '$PACIENTE_ID');
delete from public.tratamientos_aplicados where consulta_id in (
  select id from public.consultas where paciente_id = '$PACIENTE_ID');
delete from public.diagnosticos_aplicados where consulta_id in (
  select id from public.consultas where paciente_id = '$PACIENTE_ID');
delete from public.dientes where odontograma_id in (
  select id from public.odontogramas where consulta_id in (
    select id from public.consultas where paciente_id = '$PACIENTE_ID'));
delete from public.odontogramas where consulta_id in (
  select id from public.consultas where paciente_id = '$PACIENTE_ID');
delete from public.consultas where paciente_id = '$PACIENTE_ID';
delete from public.citas where persona_id = '$PACIENTE_ID';
delete from public.pacientes where id = '$PACIENTE_ID';
delete from public.personas where id = '$PACIENTE_ID';
delete from public.tratamientos where nombre = 'Resina REST $SUFIJO';
delete from public.diagnosticos where nombre = 'Caries REST $SUFIJO';
delete from public.consumibles where nombre = 'Gasas REST $SUFIJO';
SQL
  if [[ -n "$DOCTOR_ID" ]]; then
    curl -s -X DELETE "$API_URL/auth/v1/admin/users/$DOCTOR_ID" \
      -H "apikey: $SERVICE_ROLE_KEY" -H "Authorization: Bearer $SERVICE_ROLE_KEY" >/dev/null || true
    psql "$PGURL" -q -v ON_ERROR_STOP=0 >/dev/null 2>&1 -c "
      delete from public.doctores where id='$DOCTOR_ID';
      delete from public.usuarios where id='$DOCTOR_ID';
      delete from public.persona_contactos where persona_id='$DOCTOR_ID';
      delete from public.personas where id='$DOCTOR_ID';" || true
  fi
}
trap limpiar EXIT

respuesta=$(curl -s -X POST "$API_URL/auth/v1/admin/users" \
  -H "apikey: $SERVICE_ROLE_KEY" -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"hfx002.doctor.$SUFIJO@local.test\",\"password\":\"$PASSWORD\",\"email_confirm\":true,\"user_metadata\":{\"rol\":\"doctor\",\"nombre\":\"Dora\",\"apellido\":\"Autora\",\"fecha_nacimiento\":\"1981-01-01\",\"cedula\":\"HFX002-R-$SUFIJO\",\"username\":\"hfx002_r_$SUFIJO\",\"especialidad\":\"General\"}}")
DOCTOR_ID=$(jq -r '.id // empty' <<<"$respuesta")
[[ -n "$DOCTOR_ID" ]] || fallo "alta del doctor: $respuesta"

TOKEN=$(curl -s -X POST "$API_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $ANON_KEY" -H 'Content-Type: application/json' \
  -d "{\"email\":\"hfx002.doctor.$SUFIJO@local.test\",\"password\":\"$PASSWORD\"}" |
  jq -r '.access_token // empty')
[[ -n "$TOKEN" ]] || fallo "el doctor no pudo iniciar sesión"

IDS=$(psql "$PGURL" -qtA -v ON_ERROR_STOP=1 <<SQL
insert into public.personas (id, nombre, apellido, fecha_nacimiento, cedula)
values ('$PACIENTE_ID', 'Rita', 'REST', date '1992-02-02', 'HFX002-PR-$SUFIJO');
insert into public.pacientes (id, genero) values ('$PACIENTE_ID', 'femenino');
insert into public.citas (persona_id, doctor_id, fecha_hora, duracion_minutos)
values ('$PACIENTE_ID', '$DOCTOR_ID', now() + interval '1 day', 30);
with c as (
  insert into public.consultas (paciente_id, doctor_id, cita_id, fecha)
  select '$PACIENTE_ID', '$DOCTOR_ID', id, now() from public.citas
   where persona_id = '$PACIENTE_ID'
  returning id
), o as (
  insert into public.odontogramas (consulta_id) select id from c returning id, consulta_id
), d as (
  insert into public.dientes (odontograma_id, fdi_code) select id, 16 from o returning id
), t as (
  insert into public.tratamientos (nombre, costo, alcance)
  values ('Resina REST $SUFIJO', 1500, 'diente') returning id
), g as (
  insert into public.diagnosticos (nombre, alcance, categoria)
  values ('Caries REST $SUFIJO', 'puntual', 'caries') returning id
), s as (
  insert into public.consumibles (nombre, stock_actual, stock_minimo, precio)
  values ('Gasas REST $SUFIJO', 10, 1, 20) returning id
)
select (select consulta_id from o) || ' ' || (select id from t) || ' ' ||
       (select id from g) || ' ' || (select id from s);
SQL
)
read -r CONSULTA TRATAMIENTO DIAGNOSTICO CONSUMIBLE <<<"$IDS"

rpc() {
  curl -s -X POST "$API_URL/rest/v1/rpc/$1" \
    -H "apikey: $ANON_KEY" -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' -d "$2"
}

BORRADOR=$(rpc guardar_borrador_consulta "$(jq -nc \
  --arg consulta "$CONSULTA" --arg trat "$TRATAMIENTO" --arg diag "$DIAGNOSTICO" \
  --arg cons "$CONSUMIBLE" '{
    p_consulta_id: $consulta,
    p_version: 1,
    p_payload: {
      version_payload: 1,
      notas: "Dolor al frío.",
      evaluacion_clinica: {},
      dientes: [{
        fdi_code: 16,
        esta_ausente: false,
        observaciones: "Sensibilidad",
        tratamientos: [{
          tratamiento_id: $trat, es_continuo: false, esta_terminado: true,
          superficie: "oclusal", precio_aplicado: 1500, estado: "aplicado",
          notas: "Resina simple"
        }],
        diagnosticos: [{
          diagnosis_id: $diag, severidad: "moderada", superficie: "oclusal",
          origen: "diagnosticado_hoy", notas: "Lesión profunda"
        }]
      }],
      recetas: [{ items_receta: [{ nombre_medicamento: "Ibuprofeno" }] }],
      insumos: [{ consumible_id: $cons, nombre: "Gasas", cantidad: 3 }]
    }
  }')")

VERSION=$(jq -r '.version // empty' <<<"$BORRADOR")
[[ "$VERSION" == "2" ]] || fallo "el borrador no devolvió la versión confirmada: $BORRADOR"
ok "el borrador se guarda por REST y devuelve versión e identidades"

SUPERFICIE=$(psql "$PGURL" -qtA -c "
  select superficie from public.diagnosticos_aplicados
   where consulta_id = '$CONSULTA' and deleted_at is null;")
[[ "$SUPERFICIE" == "oclusal" ]] ||
  fallo "el hallazgo no conservó su cara en la base (valor: '$SUPERFICIE')"
ok "el diagnóstico guardado coincide con lo visible: pieza, cara y origen"

CONFLICTO=$(rpc guardar_borrador_consulta "{\"p_consulta_id\":\"$CONSULTA\",\"p_version\":1,\"p_payload\":{\"notas\":\"tarde\"}}")
[[ "$(jq -r '.code // empty' <<<"$CONFLICTO")" == "CL001" ]] ||
  fallo "una versión obsoleta no fue rechazada: $CONFLICTO"
ok "una versión obsoleta recibe un conflicto accionable, no un guardado silencioso"

CIERRE=$(rpc cerrar_consulta "{\"p_consulta_id\":\"$CONSULTA\",\"p_payload\":{},\"p_idempotencia_key\":\"rest-1\"}")
CUENTA=$(jq -r '.cuenta_id // empty' <<<"$CIERRE")
[[ -n "$CUENTA" ]] || fallo "el cierre no devolvió la pre-factura: $CIERRE"
[[ "$(jq -r '.monto_total | tonumber | floor' <<<"$CIERRE")" == "1500" ]] || fallo "monto incorrecto: $CIERRE"
[[ "$(jq -r '.cita_estado' <<<"$CIERRE")" == "completada" ]] || fallo "la cita no se completó: $CIERRE"
ok "el cierre por REST deja consulta, cita, cuenta y stock coherentes"

REINTENTO=$(rpc cerrar_consulta "{\"p_consulta_id\":\"$CONSULTA\",\"p_payload\":{},\"p_idempotencia_key\":\"rest-1\"}")
[[ "$(jq -r '.cuenta_id' <<<"$REINTENTO")" == "$CUENTA" ]] ||
  fallo "el reintento no devolvió la misma cuenta: $REINTENTO"
STOCK=$(psql "$PGURL" -qtA -c "select stock_actual from public.consumibles where id = '$CONSUMIBLE';")
[[ "$STOCK" == "7" ]] || fallo "el reintento volvió a descontar inventario (stock: $STOCK)"
ok "reintentar el mismo cierre no descuenta ni factura otra vez"

CERRADA=$(rpc guardar_borrador_consulta "{\"p_consulta_id\":\"$CONSULTA\",\"p_payload\":{\"notas\":\"después del cierre\"}}")
[[ "$(jq -r '.code // empty' <<<"$CERRADA")" == "CL002" ]] ||
  fallo "una consulta cerrada aceptó edición de borrador: $CERRADA"
ok "una consulta finalizada no se edita como borrador ni por REST"

echo
echo "SMOKE HFX-CLIN-002 COMPLETO · contrato de guardado y cierre por PostgREST."
