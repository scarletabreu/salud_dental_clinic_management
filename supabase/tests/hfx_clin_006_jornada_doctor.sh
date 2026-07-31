#!/usr/bin/env bash
# HFX-CLIN-006 · jornada de la doctora, con la agenda llena.
#
# Consultas sucesivas sobre pacientes de riesgo distinto: la que se reanuda, la
# que descubre una condición hoy, la que topa con una contraindicación absoluta,
# la que la justifica porque es relativa, la que tiene signos críticos, la
# urgencia sin cita, la que cierra sin tratamiento y la que cierra con
# tratamiento e insumos.
#
#   supabase/tests/hfx_clin_006_jornada_doctor.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/hfx_clin_006_lib.sh"

asegurar_seed
cargar_identificadores

# ---------------------------------------------------------------------------
paso '1 · Ve su agenda y no la de los demás'
# ---------------------------------------------------------------------------
agenda=$(rest "$TOKEN_DOCTORA" GET 'citas?select=id,doctor_id&deleted_at=is.null')
ajenas=$(jq --arg id "$DOCTORA_ID" '[.[] | select(.doctor_id != $id)] | length' <<<"$agenda")
propias=$(jq --arg id "$DOCTORA_ID" '[.[] | select(.doctor_id == $id)] | length' <<<"$agenda")
[[ "$propias" -ge 6 ]] || fallo "la doctora sólo ve $propias citas propias"
[[ "$ajenas" -eq 0 ]] || fallo "la doctora ve $ajenas citas de otro doctor"
ok "ve sus $propias citas y ninguna ajena"

# ---------------------------------------------------------------------------
paso '2 · Primera consulta: cierra sin tratamiento'
# ---------------------------------------------------------------------------
# No toda visita produce factura. Cerrar en blanco tiene que ser posible, o el
# doctor acabará inventando un tratamiento para poder salir de la pantalla.
CITA=$(cita_de "$PAC_SANO" "$DOCTORA_ID")
abrir_consulta "$TOKEN_DOCTORA" "$CITA"
SIN_TRATAMIENTO="$CONSULTA_ID"

VERSION=$(version_consulta "$SIN_TRATAMIENTO")
rpc "$TOKEN_DOCTORA" guardar_borrador_consulta \
  "{\"p_consulta_id\":\"$SIN_TRATAMIENTO\",\"p_version\":$VERSION,\"p_payload\":{\"notas\":\"Revisión sin hallazgos. Control en seis meses.\"}}" >/dev/null
[[ "$(http)" == "200" ]] || fallo "no se pudo anotar la consulta (HTTP $(http))"

VERSION=$(version_consulta "$SIN_TRATAMIENTO")
cierre=$(rpc "$TOKEN_DOCTORA" cerrar_consulta \
  "{\"p_consulta_id\":\"$SIN_TRATAMIENTO\",\"p_version\":$VERSION,\"p_idempotencia_key\":\"cert-doc-sin-$SIN_TRATAMIENTO\"}")
[[ "$(http)" == "200" ]] || fallo "el cierre sin tratamiento falló (HTTP $(http)): $cierre"
[[ "$(sql "select finalizada from consultas where id='$SIN_TRATAMIENTO'")" == 't' ]] ||
  fallo 'la consulta sin tratamiento no se finalizó'
ok 'cierra una consulta sin tratamiento ni pre-factura obligatoria'

# ---------------------------------------------------------------------------
paso '3 · Reanudación: reabrir no duplica'
# ---------------------------------------------------------------------------
CITA=$(cita_de "$PAC_EMBARAZO" "$DOCTORA_ID")
abrir_consulta "$TOKEN_DOCTORA" "$CITA"
EMBARAZO="$CONSULTA_ID"

reanudada=$(rpc "$TOKEN_DOCTORA" iniciar_consulta_de_cita "{\"p_cita_id\":\"$CITA\"}")
[[ "$(jq -r '.estado' <<<"$reanudada")" == 'reanudada' ]] ||
  fallo "el reintento no reanudó: $reanudada"
[[ "$(jq -r '.consulta_id' <<<"$reanudada")" == "$EMBARAZO" ]] ||
  fallo 'la reanudación devolvió otra consulta'
[[ "$(sql "select count(*) from consultas where cita_id='$CITA' and deleted_at is null")" == '1' ]] ||
  fallo 'la cita quedó con más de una consulta'
ok 'reabrir la consulta la reanuda en lugar de duplicarla'

# ---------------------------------------------------------------------------
paso '4 · Signos críticos con condición: la alerta bloquea el cierre'
# ---------------------------------------------------------------------------
# Embarazo + 150/95: dispara COMB_EMBARAZO_SIGNOS, aprobada por el dueño clínico.
VERSION=$(version_consulta "$EMBARAZO")
guardado=$(rpc "$TOKEN_DOCTORA" guardar_borrador_consulta "$(cat <<JSON
{"p_consulta_id":"$EMBARAZO","p_version":$VERSION,"p_payload":{
  "motivo_consulta":"Control de encías",
  "signos_vitales_medidos":[
    {"codigo":"presion_sistolica","valor":150},
    {"codigo":"presion_diastolica","valor":95},
    {"codigo":"pulso","valor":88}]
}}
JSON
)")
[[ "$(http)" == "200" ]] || fallo "el guardado falló (HTTP $(http)): $guardado"
reglas=$(jq -r '[.alertas[].regla] | join(",")' <<<"$guardado")
[[ "$reglas" == *'COMB_EMBARAZO_SIGNOS'* ]] ||
  fallo "no saltó la alerta de embarazo con presión alterada: $reglas"
ok "los signos alterados con embarazo levantan la alerta ($reglas)"

VERSION=$(version_consulta "$EMBARAZO")
rechazo=$(rpc "$TOKEN_DOCTORA" cerrar_consulta \
  "{\"p_consulta_id\":\"$EMBARAZO\",\"p_version\":$VERSION,\"p_idempotencia_key\":\"cert-emb-1\"}")
[[ "$(http)" != "200" ]] || fallo 'se cerró la consulta con una alerta sin resolver'
[[ "$(jq -r '.code' <<<"$rechazo")" == 'CL007' ]] ||
  fallo "el rechazo no vino de la barrera clínica: $rechazo"
ok 'una alerta pendiente impide cerrar la consulta'

documentar_alertas "$TOKEN_DOCTORA" "$EMBARAZO" \
  'Presión tomada en reposo; se difiere el procedimiento electivo y se refiere a su obstetra.'
VERSION=$(version_consulta "$EMBARAZO")
cierre=$(rpc "$TOKEN_DOCTORA" cerrar_consulta \
  "{\"p_consulta_id\":\"$EMBARAZO\",\"p_version\":$VERSION,\"p_idempotencia_key\":\"cert-emb-2\"}")
[[ "$(http)" == "200" ]] || fallo "no se pudo cerrar tras documentar (HTTP $(http)): $cierre"
[[ "$(sql "select justificacion is not null from alertas_clinicas
            where consulta_id='$EMBARAZO' and estado='documentada' limit 1")" == 't' ]] ||
  fallo 'la alerta se cerró sin dejar justificación'
ok 'documentar la decisión clínica desbloquea el cierre y queda por escrito'

# ---------------------------------------------------------------------------
paso '5 · Contraindicación absoluta: no se receta ni con justificación'
# ---------------------------------------------------------------------------
CITA=$(cita_de "$PAC_ALERGICA" "$DOCTORA_ID")
abrir_consulta "$TOKEN_DOCTORA" "$CITA"
ALERGICA="$CONSULTA_ID"

VERSION=$(version_consulta "$ALERGICA")
bloqueo=$(rpc "$TOKEN_DOCTORA" guardar_borrador_consulta "$(cat <<JSON
{"p_consulta_id":"$ALERGICA","p_version":$VERSION,"p_payload":{
  "recetas":[{"indicaciones_generales":"Antibiótico por absceso.",
              "justificacion_contraindicaciones":"El cuadro lo justifica.",
              "items_receta":[{"medicamento_id":"$MED_AMOXI",
                               "nombre_medicamento":"Amoxicilina 500 mg",
                               "dosis_cantidad":1,"dosis_unidad":"cápsula",
                               "via_administracion":"oral","frecuencia_horas":8,
                               "duracion_dias":7,"cantidad_total":21,
                               "justificacion_riesgo":"Se asume el riesgo."}]}]
}}
JSON
)")
[[ "$(http)" != "200" ]] || fallo 'se aceptó un medicamento absolutamente contraindicado'
[[ "$(jq -r '.code' <<<"$bloqueo")" == 'CL010' ]] ||
  fallo "el bloqueo no vino de la contraindicación absoluta: $bloqueo"
ok 'la contraindicación absoluta bloquea la receta aunque se justifique'

# ---------------------------------------------------------------------------
paso '6 · Alternativa segura y cierre con tratamiento e insumos'
# ---------------------------------------------------------------------------
stock_antes=$(sql "select stock_actual from consumibles where id='$CONS_ANESTESIA'")
VERSION=$(version_consulta "$ALERGICA")
guardado=$(rpc "$TOKEN_DOCTORA" guardar_borrador_consulta "$(cat <<JSON
{"p_consulta_id":"$ALERGICA","p_version":$VERSION,"p_payload":{
  "motivo_consulta":"Absceso periapical",
  "signos_vitales_medidos":[
    {"codigo":"presion_sistolica","valor":124},
    {"codigo":"presion_diastolica","valor":78},
    {"codigo":"temperatura","valor":37.4}],
  "dientes":[{"fdi_code":46,
    "diagnosticos":[{"diagnosis_id":"$DIAG_CARIES","severidad":"grave",
                     "superficie":"oclusal","origen":"descubierto",
                     "notas":"Caries penetrante."}],
    "tratamientos":[{"tratamiento_id":"$TRAT_ENDO","precio_aplicado":12000,
                     "notas":"Endodoncia en 46.",
                     "justificacion_no_planificada":"Urgencia por absceso."}]}],
  "insumos":[{"consumible_id":"$CONS_ANESTESIA","cantidad":2}],
  "recetas":[{"indicaciones_generales":"Alternativa sin penicilina.",
              "items_receta":[{"medicamento_id":"$MED_PARACET",
                               "nombre_medicamento":"Paracetamol 500 mg",
                               "dosis_cantidad":1,"dosis_unidad":"tableta",
                               "via_administracion":"oral","frecuencia_horas":8,
                               "duracion_dias":5,"cantidad_total":15}]}]
}}
JSON
)")
[[ "$(http)" == "200" ]] || fallo "la alternativa segura falló (HTTP $(http)): $guardado"

documentar_alertas "$TOKEN_DOCTORA" "$ALERGICA" 'Febrícula asociada al absceso; se trata en la consulta.'
VERSION=$(version_consulta "$ALERGICA")
cierre=$(rpc "$TOKEN_DOCTORA" cerrar_consulta \
  "{\"p_consulta_id\":\"$ALERGICA\",\"p_version\":$VERSION,\"p_idempotencia_key\":\"cert-alerg-1\"}")
[[ "$(http)" == "200" ]] || fallo "el cierre falló (HTTP $(http)): $cierre"

monto=$(sql "select monto_total from cuentas where consulta_id='$ALERGICA' and deleted_at is null")
[[ "$monto" == '12000.00' ]] || fallo "la pre-factura suma $monto y no 12000.00"
stock_despues=$(sql "select stock_actual from consumibles where id='$CONS_ANESTESIA'")
[[ "$stock_despues" == "$((stock_antes - 2))" ]] ||
  fallo "el inventario no descontó los dos cartuchos ($stock_antes → $stock_despues)"
ok "cierra con tratamiento (RD\$ $monto) e inventario descontado"

# ---------------------------------------------------------------------------
paso '7 · Riesgo relativo: pasa sólo con justificación propia'
# ---------------------------------------------------------------------------
CITA=$(cita_de "$PAC_HIPERTEN" "$DOCTORA_ID")
abrir_consulta "$TOKEN_DOCTORA" "$CITA"
HIPERTEN="$CONSULTA_ID"

VERSION=$(version_consulta "$HIPERTEN")
sin_justificar=$(rpc "$TOKEN_DOCTORA" guardar_borrador_consulta "$(cat <<JSON
{"p_consulta_id":"$HIPERTEN","p_version":$VERSION,"p_payload":{
  "recetas":[{"items_receta":[{"medicamento_id":"$MED_IBU",
                               "nombre_medicamento":"Ibuprofeno 400 mg",
                               "dosis_cantidad":1,"dosis_unidad":"tableta",
                               "via_administracion":"oral","frecuencia_horas":8,
                               "duracion_dias":3,"cantidad_total":9}]}]
}}
JSON
)")
[[ "$(http)" != "200" ]] || fallo 'se aceptó un riesgo relativo sin justificar'
[[ "$(jq -r '.code' <<<"$sin_justificar")" == 'CL011' ]] ||
  fallo "el rechazo no vino del riesgo relativo: $sin_justificar"

VERSION=$(version_consulta "$HIPERTEN")
justificado=$(rpc "$TOKEN_DOCTORA" guardar_borrador_consulta "$(cat <<JSON
{"p_consulta_id":"$HIPERTEN","p_version":$VERSION,"p_payload":{
  "recetas":[{"items_receta":[{"medicamento_id":"$MED_IBU",
                               "nombre_medicamento":"Ibuprofeno 400 mg",
                               "dosis_cantidad":1,"dosis_unidad":"tableta",
                               "via_administracion":"oral","frecuencia_horas":8,
                               "duracion_dias":3,"cantidad_total":9,
                               "justificacion_riesgo":"Presión controlada con enalapril; pauta corta de 3 días y control a la semana."}]}]
}}
JSON
)")
[[ "$(http)" == "200" ]] || fallo "la justificación no desbloqueó la receta: $justificado"
ok 'el riesgo relativo exige justificación por medicamento, no una nota global'

# ---------------------------------------------------------------------------
paso '8 · Condición descubierta hoy: pasa al expediente al cerrar'
# ---------------------------------------------------------------------------
VERSION=$(version_consulta "$HIPERTEN")
descubierta=$(rpc "$TOKEN_DOCTORA" guardar_borrador_consulta "$(cat <<JSON
{"p_consulta_id":"$HIPERTEN","p_version":$VERSION,"p_payload":{
  "signos_vitales_medidos":[
    {"codigo":"presion_sistolica","valor":132},
    {"codigo":"presion_diastolica","valor":84}],
  "condiciones_detectadas":[
    {"condicion_id":"$COND_ALERGIA","severidad":"severa",
     "notas":"Refiere erupción tras amoxicilina en 2024.",
     "incorporar_al_expediente":true}]
}}
JSON
)")
[[ "$(http)" == "200" ]] || fallo "no se registró la condición descubierta: $descubierta"

documentar_alertas "$TOKEN_DOCTORA" "$HIPERTEN" 'Cifras dentro de su rango habitual.'
VERSION=$(version_consulta "$HIPERTEN")
rpc "$TOKEN_DOCTORA" cerrar_consulta \
  "{\"p_consulta_id\":\"$HIPERTEN\",\"p_version\":$VERSION,\"p_idempotencia_key\":\"cert-hip-1\"}" >/dev/null
[[ "$(http)" == "200" ]] || fallo "el cierre falló (HTTP $(http))"

en_expediente=$(sql "select count(*) from record_condicion rc
                       join records r on r.id = rc.record_id
                      where r.paciente_id='$PAC_HIPERTEN'
                        and rc.condicion_id='$COND_ALERGIA' and rc.activo")
[[ "$en_expediente" == '1' ]] ||
  fallo 'la condición descubierta hoy no llegó al expediente al cerrar'
ok 'lo descubierto en consulta se incorpora al expediente en el cierre'

# ---------------------------------------------------------------------------
paso '9 · Signos críticos aislados en el paciente diabético'
# ---------------------------------------------------------------------------
CITA=$(cita_de "$PAC_DIABETES" "$DOCTORA_ID")
abrir_consulta "$TOKEN_DOCTORA" "$CITA"
DIABETES="$CONSULTA_ID"

VERSION=$(version_consulta "$DIABETES")
criticos=$(rpc "$TOKEN_DOCTORA" guardar_borrador_consulta "$(cat <<JSON
{"p_consulta_id":"$DIABETES","p_version":$VERSION,"p_payload":{
  "signos_vitales_medidos":[
    {"codigo":"presion_sistolica","valor":186},
    {"codigo":"presion_diastolica","valor":98},
    {"codigo":"pulso","valor":124},
    {"codigo":"saturacion_o2","valor":90}]
}}
JSON
)")
reglas=$(jq -r '[.alertas[].regla] | sort | join(",")' <<<"$criticos")
for esperada in SV_PRESION_CRITICA SV_PULSO_CRITICO SV_SATURACION_CRITICA COMB_DIABETES_SIGNOS; do
  [[ "$reglas" == *"$esperada"* ]] || fallo "falta la alerta $esperada: $reglas"
done
ok "cuatro reglas aprobadas disparan a la vez ($reglas)"

# ---------------------------------------------------------------------------
paso '10 · Emergencia sin cita, atendida por la propia doctora'
# ---------------------------------------------------------------------------
urgencia=$(rpc "$TOKEN_DOCTORA" registrar_cita_emergencia \
  "{\"p_paciente_id\":\"$PAC_URGENCIA\",\"p_motivo\":\"Traumatismo con avulsión\"}")
CITA_URG=$(jq -r '.cita_id // empty' <<<"$urgencia")
[[ -n "$CITA_URG" ]] || fallo "no se pudo registrar la urgencia: $urgencia"
[[ "$(sql "select es_emergencia from citas where id='$CITA_URG'")" == 't' ]] ||
  fallo 'la urgencia no quedó marcada como tal'

# La urgencia entra aunque la agenda esté llena: no se le exige un hueco libre.
abierta=$(rpc "$TOKEN_DOCTORA" iniciar_consulta_de_cita "{\"p_cita_id\":\"$CITA_URG\"}")
[[ "$(jq -r '.estado' <<<"$abierta")" == 'creada' ]] ||
  fallo "no se pudo atender la urgencia: $abierta"
ok 'la urgencia se registra y se atiende aunque la agenda esté llena'

# ---------------------------------------------------------------------------
paso '11 · Paciente pediátrico: el peso es obligatorio en la consulta'
# ---------------------------------------------------------------------------
CITA=$(cita_de "$PAC_PEDIATRICO" "$DOCTORA_ID")
abrir_consulta "$TOKEN_DOCTORA" "$CITA"
PEDIATRICO="$CONSULTA_ID"

VERSION=$(version_consulta "$PEDIATRICO")
sin_peso=$(rpc "$TOKEN_DOCTORA" guardar_borrador_consulta \
  "{\"p_consulta_id\":\"$PEDIATRICO\",\"p_version\":$VERSION,\"p_payload\":{\"signos_vitales_medidos\":[{\"codigo\":\"temperatura\",\"valor\":36.8}]}}")
reglas=$(jq -r '[.alertas[].regla] | join(",")' <<<"$sin_peso")
[[ "$reglas" == *'PED_PESO_REQUERIDO'* ]] ||
  fallo "no se exigió el peso del paciente pediátrico: $reglas"

VERSION=$(version_consulta "$PEDIATRICO")
con_peso=$(rpc "$TOKEN_DOCTORA" guardar_borrador_consulta \
  "{\"p_consulta_id\":\"$PEDIATRICO\",\"p_version\":$VERSION,\"p_payload\":{\"signos_vitales_medidos\":[{\"codigo\":\"temperatura\",\"valor\":36.8},{\"codigo\":\"peso\",\"valor\":26}]}}")
reglas=$(jq -r '[.alertas[].regla] | join(",")' <<<"$con_peso")
[[ "$reglas" != *'PED_PESO_REQUERIDO'* ]] ||
  fallo "la alerta del peso sigue viva tras registrarlo: $reglas"
ok 'la regla pediátrica exige el peso y se apaga al registrarlo'

# ---------------------------------------------------------------------------
paso '12 · No firma por otro doctor'
# ---------------------------------------------------------------------------
# Ver la agenda no es poder atenderla; la doctora no abre la cita del admin.
CITA_ADMIN=$(cita_de "$PAC_SANO" "$ADMIN_ID")
rpc "$TOKEN_DOCTORA" iniciar_consulta_de_cita "{\"p_cita_id\":\"$CITA_ADMIN\"}" >/dev/null
[[ "$(http)" != "200" ]] || fallo 'la doctora abrió la consulta de otro doctor'
ok 'no puede atender ni firmar la cita de otro doctor'

resumen 'JORNADA DOCTOR'
