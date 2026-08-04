#!/usr/bin/env bash
# HFX-CLIN-006 · jornada del administrador que también ejerce.
#
# Es la jornada que el programa entero existe para hacer posible: hasta
# HFX-CLIN-000, el administrador quedaba fuera de todo lo clínico aunque el
# dominio lo declara doctor. Aquí atiende su propia cita de principio a fin y
# después vuelve a sus funciones administrativas.
#
#   supabase/tests/hfx_clin_006_jornada_admin_doctor.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/hfx_clin_006_lib.sh"

asegurar_seed
cargar_identificadores

# ---------------------------------------------------------------------------
paso '1 · Inicia sesión y su identidad clínica está completa'
# ---------------------------------------------------------------------------
perfil=$(rest "$TOKEN_ADMIN" GET 'rpc/perfil_actual')
[[ "$(jq -r '.[0].rol' <<<"$perfil")" == 'admin' ]] ||
  fallo "el perfil no se resuelve como admin: $perfil"
[[ "$(jq -r '.[0].especialidad' <<<"$perfil")" != 'null' ]] ||
  fallo 'el admin no tiene especialidad: no es doctor en la base'
[[ "$(sql "select count(*) from doctores where id='$ADMIN_ID'")" == '1' ]] ||
  fallo 'el admin no tiene fila en doctores'
ok 'el administrador es doctor en todas las capas'

# ---------------------------------------------------------------------------
paso '2 · Ve la agenda completa y también la suya'
# ---------------------------------------------------------------------------
agenda=$(rest "$TOKEN_ADMIN" GET 'citas?select=id,doctor_id&deleted_at=is.null')
total=$(jq 'length' <<<"$agenda")
propias=$(jq --arg id "$ADMIN_ID" '[.[] | select(.doctor_id == $id)] | length' <<<"$agenda")
[[ "$total" -ge 7 ]] || fallo "el admin no ve la agenda completa (ve $total citas)"
[[ "$propias" -ge 1 ]] || fallo 'el admin no tiene ninguna cita propia'
ok "ve la agenda completa ($total citas) y tiene $propias propia(s)"

# ---------------------------------------------------------------------------
paso '3 · Abre su consulta'
# ---------------------------------------------------------------------------
CITA=$(cita_de "$PAC_SANO" "$ADMIN_ID")
[[ -n "$CITA" ]] || fallo 'el seed no dejó una cita del admin'

# Sin llegada no hay consulta: el paciente todavía no está.
rpc "$TOKEN_ADMIN" iniciar_consulta_de_cita "{\"p_cita_id\":\"$CITA\"}" >/dev/null
[[ "$(http)" != "200" ]] || fallo 'se abrió una consulta sin registrar la llegada'
ok 'sin llegada registrada no se abre la consulta'

abrir_consulta "$TOKEN_ADMIN" "$CITA"
ok "abre su consulta ($CONSULTA_ID)"

# ---------------------------------------------------------------------------
paso '4 · La autoría clínica es suya, no de un doctor genérico'
# ---------------------------------------------------------------------------
autor=$(sql "select doctor_id from consultas where id='$CONSULTA_ID'")
[[ "$autor" == "$ADMIN_ID" ]] ||
  fallo "la consulta quedó firmada por $autor y no por el admin"
ok 'la consulta queda firmada por el administrador que la atiende'

# ---------------------------------------------------------------------------
paso '5 · Signos vitales, diagnóstico y tratamiento'
# ---------------------------------------------------------------------------
VERSION=$(version_consulta "$CONSULTA_ID")
guardado=$(rpc "$TOKEN_ADMIN" guardar_borrador_consulta "$(cat <<JSON
{"p_consulta_id":"$CONSULTA_ID","p_version":$VERSION,"p_payload":{
  "motivo_consulta":"Profilaxis semestral",
  "signos_vitales_medidos":[
    {"codigo":"presion_sistolica","valor":118},
    {"codigo":"presion_diastolica","valor":76},
    {"codigo":"pulso","valor":72},
    {"codigo":"temperatura","valor":36.6}],
  "generales":{
    "diagnosticos":[{"diagnosis_id":"$DIAG_PERIODONT","severidad":"leve",
                     "origen":"descubierto","notas":"Gingivitis localizada."}],
    "tratamientos":[{"tratamiento_id":"$TRAT_PROFILAXIS","precio_aplicado":2500,
                     "notas":"Profilaxis completa.",
                     "justificacion_no_planificada":"Motivo de la visita."}]},
  "insumos":[{"consumible_id":"$CONS_ANESTESIA","cantidad":1}]
}}
JSON
)")
[[ "$(http)" == "200" ]] || fallo "el guardado falló (HTTP $(http)): $guardado"
[[ "$(jq -r '.alertas | length' <<<"$guardado")" == "0" ]] ||
  fallo "un paciente sano no debería levantar alertas: $(jq -c '.alertas' <<<"$guardado")"
ok 'guarda signos vitales normales, hallazgo y tratamiento sin alertas'

# ---------------------------------------------------------------------------
paso '6 · Emite una receta segura'
# ---------------------------------------------------------------------------
VERSION=$(version_consulta "$CONSULTA_ID")
receta=$(rpc "$TOKEN_ADMIN" guardar_borrador_consulta "$(cat <<JSON
{"p_consulta_id":"$CONSULTA_ID","p_version":$VERSION,"p_payload":{
  "recetas":[{"indicaciones_generales":"Tomar con alimentos.",
              "items_receta":[{"medicamento_id":"$MED_PARACET",
                               "nombre_medicamento":"Paracetamol 500 mg",
                               "dosis_cantidad":1,"dosis_unidad":"tableta",
                               "via_administracion":"oral",
                               "frecuencia_horas":8,"duracion_dias":3,
                               "cantidad_total":9}]}]
}}
JSON
)")
[[ "$(http)" == "200" ]] || fallo "la receta no se guardó (HTTP $(http)): $receta"
ok 'emite una receta sin conflictos'

# ---------------------------------------------------------------------------
paso '7 · Cierra la consulta y aparece la pre-factura'
# ---------------------------------------------------------------------------
stock_antes=$(sql "select stock_actual from consumibles where id='$CONS_ANESTESIA'")
VERSION=$(version_consulta "$CONSULTA_ID")
cierre=$(rpc "$TOKEN_ADMIN" cerrar_consulta "$(cat <<JSON
{"p_consulta_id":"$CONSULTA_ID","p_version":$VERSION,
 "p_idempotencia_key":"cert-admin-$CONSULTA_ID",
 "p_metodo_pago":"contado","p_nota":"Cobro en recepción."}
JSON
)")
[[ "$(http)" == "200" ]] || fallo "el cierre falló (HTTP $(http)): $cierre"

[[ "$(sql "select finalizada from consultas where id='$CONSULTA_ID'")" == 't' ]] ||
  fallo 'la consulta no quedó finalizada'
cuenta=$(sql "select id from cuentas where consulta_id='$CONSULTA_ID' and deleted_at is null")
[[ -n "$cuenta" ]] || fallo 'el cierre no generó la pre-factura'
monto=$(sql "select monto_total from cuentas where id='$cuenta'")
[[ "$monto" == '2500.00' ]] || fallo "la pre-factura suma $monto y no 2500.00"

stock_despues=$(sql "select stock_actual from consumibles where id='$CONS_ANESTESIA'")
[[ "$stock_despues" == "$((stock_antes - 1))" ]] ||
  fallo "el inventario no bajó ($stock_antes → $stock_despues)"
ok "cierra, factura RD\$ $monto y descuenta el insumo consumido"

# ---------------------------------------------------------------------------
paso '8 · La cita queda completada y la receta emitida'
# ---------------------------------------------------------------------------
[[ "$(sql "select estado from citas where id='$CITA'")" == 'completada' ]] ||
  fallo 'la cita no pasó a completada al cerrar la consulta'
[[ "$(sql "select estado from recetas where consulta_id='$CONSULTA_ID' and deleted_at is null")" == 'emitida' ]] ||
  fallo 'la receta se quedó en borrador tras el cierre'
ok 'la cita queda completada y la receta emitida'

# ---------------------------------------------------------------------------
paso '9 · Vuelve a sus funciones administrativas'
# ---------------------------------------------------------------------------
# Ejercer no le quita lo administrativo: sigue viendo caja, compras y personal.
caja=$(rest "$TOKEN_ADMIN" GET 'cajas?select=id&limit=1')
[[ "$(http)" == "200" ]] || fallo "el admin perdió el acceso a caja (HTTP $(http))"
compras=$(rest "$TOKEN_ADMIN" GET 'compras?select=id&limit=1')
[[ "$(http)" == "200" ]] || fallo "el admin perdió el acceso a compras (HTTP $(http))"
usuarios=$(rest "$TOKEN_ADMIN" GET 'usuarios?select=id&limit=1')
[[ "$(http)" == "200" ]] || fallo "el admin perdió el acceso a personal (HTTP $(http))"
ok 'conserva caja, compras y personal después de ejercer'

# ---------------------------------------------------------------------------
paso '10 · La jornada queda auditada de principio a fin'
# ---------------------------------------------------------------------------
linea=$(rpc "$TOKEN_ADMIN" linea_tiempo_consulta "{\"p_consulta_id\":\"$CONSULTA_ID\"}")
eventos=$(jq -r '[.[].evento] | join(",")' <<<"$linea")
for esperado in cita_llegada consulta_iniciada consulta_cerrada receta_emitida; do
  [[ "$eventos" == *"$esperado"* ]] ||
    fallo "la línea de tiempo no registra '$esperado': $eventos"
done
ok 'la línea de tiempo recoge llegada, apertura, receta y cierre'

resumen 'JORNADA ADMIN-DOCTOR'
