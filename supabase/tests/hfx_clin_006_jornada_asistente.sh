#!/usr/bin/env bash
# HFX-CLIN-006 · jornada de recepción.
#
# La asistente sostiene la operación —altas, agenda, reprogramaciones,
# llegadas, caja— y no escribe una sola línea clínica. Las dos mitades importan
# igual: un permiso de menos la deja sin poder trabajar, y uno de más convierte
# el expediente en algo que cualquiera edita.
#
#   supabase/tests/hfx_clin_006_jornada_asistente.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/hfx_clin_006_lib.sh"

asegurar_seed
cargar_identificadores

SUFIJO="$RANDOM$RANDOM"

# ---------------------------------------------------------------------------
paso '1 · Alta de paciente en una sola operación'
# ---------------------------------------------------------------------------
# Ficha, expediente y contacto nacen juntos o no nace nada: media alta deja un
# paciente al que no se puede ni llamar ni atender.
alta=$(rpc "$TOKEN_ASISTENTE" registrar_paciente "$(cat <<JSON
{"p_payload":{
  "nombre":"Noelia","apellido":"Nueva","fecha_nacimiento":"1996-04-04",
  "cedula":"CERT-NUEVA-$SUFIJO","genero":"femenino",
  "contactos":[{"numero_telefono":"(809) 555-$SUFIJO","email":"Noelia.Nueva@Correo.COM"}],
  "record":{"tipo_sangre":"a_positivo"}
}}
JSON
)")
PACIENTE=$(jq -r '.paciente_id // empty' <<<"$alta")
[[ -n "$PACIENTE" ]] || fallo "el alta falló (HTTP $(http)): $alta"

completo=$(sql "select (select count(*) from pacientes where id='$PACIENTE')
                     + (select count(*) from records where paciente_id='$PACIENTE')
                     + (select count(*) from persona_contactos where persona_id='$PACIENTE')")
[[ "$completo" == '3' ]] ||
  fallo "el alta no dejó ficha, expediente y contacto (suma $completo)"
ok 'da de alta al paciente completo en una sola operación'

# El correo se normaliza: buscar por correo no puede depender de mayúsculas.
correo=$(sql "select c.email from contactos c
                join persona_contactos pc on pc.contacto_id = c.id
               where pc.persona_id='$PACIENTE'")
[[ "$correo" == 'noelia.nueva@correo.com' ]] ||
  fallo "el correo no se normalizó: $correo"
ok 'el contacto queda normalizado, no como lo tecleó recepción'

# ---------------------------------------------------------------------------
paso '2 · Agenda: reservar, reprogramar y cancelar'
# ---------------------------------------------------------------------------
manana=$(sql "select to_char(date_trunc('day', now()) + interval '1 day 14 hours',
                             'YYYY-MM-DD\"T\"HH24:MI:SSOF')")
nueva=$(rest "$TOKEN_ASISTENTE" POST 'citas' \
  "{\"persona_id\":\"$PACIENTE\",\"doctor_id\":\"$DOCTORA_ID\",\"fecha_hora\":\"$manana\",\"duracion_minutos\":30,\"estado\":\"confirmada\",\"motivo\":\"Primera visita\"}")
CITA=$(jq -r '.[0].id // empty' <<<"$nueva")
[[ -n "$CITA" ]] || fallo "recepción no pudo agendar (HTTP $(http)): $nueva"
ok 'agenda una cita nueva'

# El solapamiento lo impide la base, no la pantalla.
solapada=$(rest "$TOKEN_ASISTENTE" POST 'citas' \
  "{\"persona_id\":\"$PAC_SANO\",\"doctor_id\":\"$DOCTORA_ID\",\"fecha_hora\":\"$manana\",\"duracion_minutos\":30,\"estado\":\"confirmada\"}")
[[ "$(http)" != "201" ]] || fallo 'la base aceptó dos citas solapadas del mismo doctor'
ok 'la base rechaza una cita que se solapa con otra del mismo doctor'

# Reprogramar mueve la hora y nada más. El grafo de estados no admite volver de
# `confirmada` a `programada`: una cita ya confirmada por el paciente no
# "desconfirma" porque se cambie de hueco.
reprogramada=$(sql "select to_char(date_trunc('day', now()) + interval '1 day 15 hours',
                                   'YYYY-MM-DD\"T\"HH24:MI:SSOF')")
rest "$TOKEN_ASISTENTE" PATCH "citas?id=eq.$CITA" \
  "{\"fecha_hora\":\"$reprogramada\"}" >/dev/null
[[ "$(http)" == "200" ]] || fallo "no se pudo reprogramar (HTTP $(http))"
[[ "$(sql "select to_char(fin, 'HH24:MI') from citas where id='$CITA'")" == '15:30' ]] ||
  fallo 'el fin de la cita no se recalculó al moverla'
ok 'reprograma la cita y su hora de fin se recalcula sola'

# Una cancelación se registra; la cita no desaparece de la historia.
OTRA=$(cita_de "$PAC_DIABETES" "$DOCTORA_ID")
rest "$TOKEN_ASISTENTE" PATCH "citas?id=eq.$OTRA" \
  '{"estado":"cancelada"}' >/dev/null
[[ "$(http)" == "200" ]] || fallo "no se pudo cancelar (HTTP $(http))"
[[ "$(sql "select estado from citas where id='$OTRA'")" == 'cancelada' ]] ||
  fallo 'la cancelación no quedó registrada'
ok 'cancela una cita y la cancelación queda registrada'

# ---------------------------------------------------------------------------
paso '3 · Llegada y handoff al doctor'
# ---------------------------------------------------------------------------
# La llegada es un hecho clínico: alguien afirma que el paciente está presente.
# Es la frontera entre lo que hace recepción y lo que hace el doctor.
CITA_SANO=$(cita_de "$PAC_SANO" "$DOCTORA_ID")
rpc "$TOKEN_ASISTENTE" registrar_llegada_cita "{\"p_cita_id\":\"$CITA_SANO\"}" >/dev/null
[[ "$(http)" == "200" ]] || fallo "recepción no pudo marcar la llegada (HTTP $(http))"
[[ "$(sql "select estado from citas where id='$CITA_SANO'")" == 'en_espera' ]] ||
  fallo 'la llegada no dejó la cita en espera'
ok 'registra la llegada y deja la cita lista para el doctor'

recogida=$(rpc "$TOKEN_DOCTORA" iniciar_consulta_de_cita "{\"p_cita_id\":\"$CITA_SANO\"}")
[[ "$(jq -r '.estado' <<<"$recogida")" == 'creada' ]] ||
  fallo "el doctor no pudo recoger el handoff: $recogida"
[[ "$(sql "select estado from citas where id='$CITA_SANO'")" == 'en_consulta' ]] ||
  fallo 'la cita no pasó a en_consulta'
ok 'el doctor recoge el handoff y la cita pasa a en consulta'

# ---------------------------------------------------------------------------
paso '4 · Encamina una urgencia sin atenderla'
# ---------------------------------------------------------------------------
urgencia=$(rpc "$TOKEN_ASISTENTE" registrar_cita_emergencia \
  "{\"p_paciente_id\":\"$PAC_URGENCIA\",\"p_doctor_id\":\"$DOCTORA_ID\",\"p_motivo\":\"Llega sangrando\"}")
CITA_URG=$(jq -r '.cita_id // empty' <<<"$urgencia")
[[ -n "$CITA_URG" ]] || fallo "recepción no pudo encaminar la urgencia: $urgencia"
ok 'registra una urgencia y se la asigna a un doctor'

# ---------------------------------------------------------------------------
paso '5 · No escribe clínica: ni propia ni ajena'
# ---------------------------------------------------------------------------
rpc "$TOKEN_ASISTENTE" iniciar_consulta_de_cita "{\"p_cita_id\":\"$CITA_URG\"}" >/dev/null
[[ "$(http)" != "200" ]] || fallo 'la asistente abrió una consulta'
ok 'no puede abrir una consulta ni siquiera de la urgencia que encaminó'

CONSULTA=$(jq -r '.consulta_id' <<<"$recogida")
rpc "$TOKEN_ASISTENTE" guardar_borrador_consulta \
  "{\"p_consulta_id\":\"$CONSULTA\",\"p_payload\":{\"notas\":\"Escrito por recepción.\"}}" >/dev/null
[[ "$(http)" != "200" ]] || fallo 'la asistente escribió en una consulta abierta'
ok 'no puede escribir en la consulta que atiende el doctor'

rpc "$TOKEN_ASISTENTE" cerrar_consulta \
  "{\"p_consulta_id\":\"$CONSULTA\",\"p_idempotencia_key\":\"asis-$SUFIJO\"}" >/dev/null
[[ "$(http)" != "200" ]] || fallo 'la asistente cerró una consulta'
ok 'no puede cerrar una consulta'

# ---------------------------------------------------------------------------
paso '6 · No lee el expediente clínico'
# ---------------------------------------------------------------------------
# Es privacidad por rol, no desconfianza: recepción trabaja con el teléfono y la
# agenda, no con el historial médico.
consultas=$(rest "$TOKEN_ASISTENTE" GET 'consultas?select=id,notas')
visibles=$(jq 'length' <<<"$consultas")
[[ "$visibles" == '0' ]] ||
  fallo "la asistente lee $visibles consultas clínicas"
recetas=$(rest "$TOKEN_ASISTENTE" GET 'recetas?select=id')
[[ "$(jq 'length' <<<"$recetas")" == '0' ]] ||
  fallo 'la asistente lee las recetas de los pacientes'
ok 'no lee consultas ni recetas'

# ---------------------------------------------------------------------------
paso '7 · Caja: lo suyo sí lo hace'
# ---------------------------------------------------------------------------
caja=$(rest "$TOKEN_ASISTENTE" GET 'cajas?select=id&cerrada=is.false&limit=1')
[[ "$(http)" == "200" ]] || fallo "la asistente no puede consultar la caja (HTTP $(http))"
CAJA=$(jq -r '.[0].id // empty' <<<"$caja")
[[ -n "$CAJA" ]] || fallo 'el seed no dejó una caja abierta'

movimiento=$(rest "$TOKEN_ASISTENTE" POST 'movimientos_caja' \
  "{\"caja_diaria_id\":\"$CAJA\",\"tipo\":\"ingreso\",\"monto\":1500,\"descripcion\":\"Cobro de consulta (certificación)\"}")
[[ "$(http)" == "201" ]] || fallo "la asistente no pudo registrar un cobro: $movimiento"
ok 'registra un movimiento de caja, que es su trabajo'

# ---------------------------------------------------------------------------
paso '8 · No administra al personal'
# ---------------------------------------------------------------------------
intento=$(rest "$TOKEN_ASISTENTE" PATCH "doctores?id=eq.$DOCTORA_ID" \
  '{"especialidad":"Cambiada por recepción"}')
[[ "$(sql "select especialidad from doctores where id='$DOCTORA_ID'")" == 'Endodoncia' ]] ||
  fallo 'la asistente cambió el perfil de un doctor'
ok 'no puede modificar el perfil profesional de un doctor'

resumen 'JORNADA ASISTENTE'
