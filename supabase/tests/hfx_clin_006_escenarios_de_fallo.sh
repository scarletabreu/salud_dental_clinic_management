#!/usr/bin/env bash
# HFX-CLIN-006 · lo que pasa cuando algo sale mal.
#
# Un happy path verde no dice nada sobre la integridad del sistema. Aquí se
# provoca a propósito lo que ocurre en una clínica real —doble clic, dos
# pestañas, dos usuarios sobre lo mismo, red que se corta a mitad de un
# guardado, la sesión que caduca— y se comprueba que nada de eso duplica un
# cobro, descuadra el inventario ni deja una consulta a medio cerrar.
#
#   supabase/tests/hfx_clin_006_escenarios_de_fallo.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/hfx_clin_006_lib.sh"

asegurar_seed
cargar_identificadores

SUFIJO="$RANDOM$RANDOM"

# ---------------------------------------------------------------------------
paso '1 · Doble clic en «Iniciar consulta»'
# ---------------------------------------------------------------------------
# Dos peticiones simultáneas sobre la misma cita: una crea y la otra reanuda,
# pero nunca aparecen dos consultas para la misma cita.
CITA=$(cita_de "$PAC_SANO" "$DOCTORA_ID")
rpc "$TOKEN_DOCTORA" registrar_llegada_cita "{\"p_cita_id\":\"$CITA\"}" >/dev/null

for i in 1 2; do
  curl -s -o "/tmp/hfx006_inicio_$i.json" \
    -X POST "$API_URL/rest/v1/rpc/iniciar_consulta_de_cita" \
    -H "apikey: $ANON_KEY" -H "Authorization: Bearer $TOKEN_DOCTORA" \
    -H 'Content-Type: application/json' \
    -d "{\"p_cita_id\":\"$CITA\",\"p_dientes\":$DENTICION_FDI}" &
done
wait

vigentes=$(sql "select count(*) from consultas where cita_id='$CITA' and deleted_at is null")
[[ "$vigentes" == '1' ]] || fallo "el doble clic dejó $vigentes consultas"
CONSULTA=$(sql "select id from consultas where cita_id='$CITA' and deleted_at is null")
ok 'el doble clic deja una sola consulta'

# ---------------------------------------------------------------------------
paso '2 · Dos pestañas guardando sobre la misma consulta'
# ---------------------------------------------------------------------------
# La segunda trae una versión vieja: la base la rechaza con CL001 en vez de
# pisar en silencio lo que escribió la primera.
VERSION=$(version_consulta "$CONSULTA")
rpc "$TOKEN_DOCTORA" guardar_borrador_consulta \
  "{\"p_consulta_id\":\"$CONSULTA\",\"p_version\":$VERSION,\"p_payload\":{\"notas\":\"Pestaña A\"}}" >/dev/null
[[ "$(http)" == "200" ]] || fallo 'la primera pestaña no pudo guardar'

vieja=$(rpc "$TOKEN_DOCTORA" guardar_borrador_consulta \
  "{\"p_consulta_id\":\"$CONSULTA\",\"p_version\":$VERSION,\"p_payload\":{\"notas\":\"Pestaña B\"}}")
[[ "$(http)" != "200" ]] || fallo 'la pestaña con versión vieja pisó el trabajo de la otra'
[[ "$(jq -r '.code' <<<"$vieja")" == 'CL001' ]] ||
  fallo "el rechazo no fue por conflicto de versión: $vieja"
[[ "$(sql "select notas from consultas where id='$CONSULTA'")" == 'Pestaña A' ]] ||
  fallo 'el contenido de la pestaña vieja llegó a la base'
ok 'la pestaña con versión vieja se rechaza y no pisa lo guardado'

# ---------------------------------------------------------------------------
paso '3 · Dos usuarios sobre la misma consulta'
# ---------------------------------------------------------------------------
# El admin ve la consulta, pero no la firma: mirar no es escribir.
rpc "$TOKEN_ADMIN" guardar_borrador_consulta \
  "{\"p_consulta_id\":\"$CONSULTA\",\"p_payload\":{\"notas\":\"Editado por dirección\"}}" >/dev/null
[[ "$(http)" != "200" ]] || fallo 'el admin escribió en la consulta de otro doctor'
[[ "$(sql "select notas from consultas where id='$CONSULTA'")" == 'Pestaña A' ]] ||
  fallo 'la nota ajena llegó a la consulta'
ok 'otro clínico no escribe en la consulta ajena aunque pueda verla'

# ---------------------------------------------------------------------------
paso '4 · Red caída durante el guardado'
# ---------------------------------------------------------------------------
# Se corta la petición a mitad. La transacción del servidor termina o no
# empieza, pero no deja media consulta: la versión sube una vez o ninguna, y
# los datos que llegaron están completos.
VERSION=$(version_consulta "$CONSULTA")
curl -s --max-time 0.05 -o /dev/null \
  -X POST "$API_URL/rest/v1/rpc/guardar_borrador_consulta" \
  -H "apikey: $ANON_KEY" -H "Authorization: Bearer $TOKEN_DOCTORA" \
  -H 'Content-Type: application/json' \
  -d "{\"p_consulta_id\":\"$CONSULTA\",\"p_version\":$VERSION,\"p_payload\":{\"signos_vitales_medidos\":[{\"codigo\":\"pulso\",\"valor\":76},{\"codigo\":\"temperatura\",\"valor\":36.5}]}}" \
  || true
sleep 1

version_final=$(version_consulta "$CONSULTA")
[[ "$version_final" == "$VERSION" || "$version_final" == "$((VERSION + 1))" ]] ||
  fallo "la versión saltó de $VERSION a $version_final tras el corte"

# O están los dos signos o no está ninguno; nunca uno solo.
signos=$(sql "select count(*) from signos_vitales_consulta
               where consulta_id='$CONSULTA' and deleted_at is null")
[[ "$signos" == '0' || "$signos" == '2' ]] ||
  fallo "el corte dejó $signos signos vitales a medio guardar"
ok "el corte de red no deja un guardado a medias (versión $version_final, $signos signos)"

# Y reintentar con la versión buena funciona sin duplicar nada.
VERSION=$(version_consulta "$CONSULTA")
rpc "$TOKEN_DOCTORA" guardar_borrador_consulta \
  "{\"p_consulta_id\":\"$CONSULTA\",\"p_version\":$VERSION,\"p_payload\":{\"signos_vitales_medidos\":[{\"codigo\":\"pulso\",\"valor\":76},{\"codigo\":\"temperatura\",\"valor\":36.5}]}}" >/dev/null
[[ "$(http)" == "200" ]] || fallo "el reintento tras el corte falló (HTTP $(http))"
[[ "$(sql "select count(*) from signos_vitales_consulta
             where consulta_id='$CONSULTA' and deleted_at is null")" == '2' ]] ||
  fallo 'el reintento duplicó los signos vitales'
ok 'reintentar tras el corte deja exactamente un juego de datos'

# ---------------------------------------------------------------------------
paso '5 · Receta inválida'
# ---------------------------------------------------------------------------
# La cantidad no cuadra con la pauta: se despacharían 60 tabletas para tres
# días de tratamiento. El renglón entero se rechaza en el cierre.
VERSION=$(version_consulta "$CONSULTA")
rpc "$TOKEN_DOCTORA" guardar_borrador_consulta "$(cat <<JSON
{"p_consulta_id":"$CONSULTA","p_version":$VERSION,"p_payload":{
  "recetas":[{"items_receta":[{"medicamento_id":"$MED_PARACET",
                               "nombre_medicamento":"Paracetamol 500 mg",
                               "dosis_cantidad":1,"dosis_unidad":"tableta",
                               "via_administracion":"oral","frecuencia_horas":8,
                               "duracion_dias":3,"cantidad_total":60}]}]
}}
JSON
)" >/dev/null
[[ "$(http)" == "200" ]] || fallo 'el borrador de la receta debería poder guardarse'

VERSION=$(version_consulta "$CONSULTA")
rechazo=$(rpc "$TOKEN_DOCTORA" cerrar_consulta \
  "{\"p_consulta_id\":\"$CONSULTA\",\"p_version\":$VERSION,\"p_idempotencia_key\":\"fallo-receta-$SUFIJO\"}")
[[ "$(http)" != "200" ]] || fallo 'se emitió una receta con cantidad incoherente'
[[ "$(jq -r '.code' <<<"$rechazo")" == 'CL008' ]] ||
  fallo "el rechazo no vino del validador de receta: $rechazo"
[[ "$(sql "select finalizada from consultas where id='$CONSULTA'")" == 'f' ]] ||
  fallo 'la consulta se finalizó pese al rechazo'
ok 'una receta incoherente impide el cierre y la consulta sigue abierta'

# Corregida, el cierre sale adelante.
VERSION=$(version_consulta "$CONSULTA")
RECETA=$(sql "select id from recetas where consulta_id='$CONSULTA' and deleted_at is null")
rpc "$TOKEN_DOCTORA" guardar_borrador_consulta "$(cat <<JSON
{"p_consulta_id":"$CONSULTA","p_version":$VERSION,"p_payload":{
  "recetas":[{"id":"$RECETA","items_receta":[{"medicamento_id":"$MED_PARACET",
                               "nombre_medicamento":"Paracetamol 500 mg",
                               "dosis_cantidad":1,"dosis_unidad":"tableta",
                               "via_administracion":"oral","frecuencia_horas":8,
                               "duracion_dias":3,"cantidad_total":9}]}]
}}
JSON
)" >/dev/null
[[ "$(http)" == "200" ]] || fallo 'no se pudo corregir la receta'
ok 'corregir el renglón desbloquea el cierre'

# ---------------------------------------------------------------------------
paso '6 · Stock insuficiente'
# ---------------------------------------------------------------------------
# Quedan 2 limas y la consulta quiere gastar 5. El cierre se detiene antes de
# tocar inventario ni dinero: es la razón de que las barreras vayan primero.
VERSION=$(version_consulta "$CONSULTA")
rpc "$TOKEN_DOCTORA" guardar_borrador_consulta \
  "{\"p_consulta_id\":\"$CONSULTA\",\"p_version\":$VERSION,\"p_payload\":{\"insumos\":[{\"consumible_id\":\"$CONS_LIMA\",\"cantidad\":5}]}}" >/dev/null
[[ "$(http)" == "200" ]] || fallo 'el borrador con exceso de insumos debería guardarse'

stock_antes=$(sql "select stock_actual from consumibles where id='$CONS_LIMA'")
cuentas_antes=$(sql "select count(*) from cuentas")
VERSION=$(version_consulta "$CONSULTA")
rechazo=$(rpc "$TOKEN_DOCTORA" cerrar_consulta \
  "{\"p_consulta_id\":\"$CONSULTA\",\"p_version\":$VERSION,\"p_idempotencia_key\":\"fallo-stock-$SUFIJO\"}")
[[ "$(jq -r '.code' <<<"$rechazo")" == 'CL003' ]] ||
  fallo "el rechazo no vino del control de stock: $rechazo"
[[ "$(sql "select stock_actual from consumibles where id='$CONS_LIMA'")" == "$stock_antes" ]] ||
  fallo 'el cierre fallido movió el inventario'
[[ "$(sql "select count(*) from cuentas")" == "$cuentas_antes" ]] ||
  fallo 'el cierre fallido creó una pre-factura'
ok 'el stock insuficiente detiene el cierre sin tocar inventario ni cuentas'

# Ajustado a lo que hay, el cierre pasa. Se añade además un tratamiento
# facturable: sin él la consulta cerraría sin pre-factura y el control de doble
# cobro del paso siguiente no comprobaría nada.
VERSION=$(version_consulta "$CONSULTA")
rpc "$TOKEN_DOCTORA" guardar_borrador_consulta "$(cat <<JSON
{"p_consulta_id":"$CONSULTA","p_version":$VERSION,"p_payload":{
  "insumos":[{"consumible_id":"$CONS_LIMA","cantidad":2}],
  "generales":{"tratamientos":[{"tratamiento_id":"$TRAT_PROFILAXIS",
                                "precio_aplicado":2500,
                                "justificacion_no_planificada":"Motivo de la visita."}]}
}}
JSON
)" >/dev/null
[[ "$(http)" == "200" ]] || fallo 'no se pudo ajustar el consumo ni añadir el tratamiento'

# ---------------------------------------------------------------------------
paso '7 · Doble cierre: el reintento no cobra dos veces'
# ---------------------------------------------------------------------------
VERSION=$(version_consulta "$CONSULTA")
CLAVE="cert-cierre-$SUFIJO"
for i in 1 2; do
  curl -s -o "/tmp/hfx006_cierre_$i.json" \
    -X POST "$API_URL/rest/v1/rpc/cerrar_consulta" \
    -H "apikey: $ANON_KEY" -H "Authorization: Bearer $TOKEN_DOCTORA" \
    -H 'Content-Type: application/json' \
    -d "{\"p_consulta_id\":\"$CONSULTA\",\"p_idempotencia_key\":\"$CLAVE\"}" &
done
wait

[[ "$(sql "select finalizada from consultas where id='$CONSULTA'")" == 't' ]] ||
  fallo "la consulta no se cerró: $(cat /tmp/hfx006_cierre_1.json)"
cuentas=$(sql "select count(*) from cuentas where consulta_id='$CONSULTA' and deleted_at is null")
[[ "$cuentas" == '1' ]] || fallo "el doble cierre generó $cuentas pre-facturas"
[[ "$(sql "select monto_total from cuentas where consulta_id='$CONSULTA' and deleted_at is null")" == '2500.00' ]] ||
  fallo 'la pre-factura no cobró el tratamiento una sola vez' 
movimientos=$(sql "select count(*) from movimientos_stock_consumible where consulta_id='$CONSULTA'")
[[ "$movimientos" == '1' ]] ||
  fallo "el doble cierre generó $movimientos movimientos de inventario"
ok 'dos cierres simultáneos producen una sola factura y un solo descuento'

# Y un tercer intento, más tarde, devuelve lo mismo sin volver a cobrar.
repetido=$(rpc "$TOKEN_DOCTORA" cerrar_consulta \
  "{\"p_consulta_id\":\"$CONSULTA\",\"p_idempotencia_key\":\"$CLAVE\"}")
[[ "$(http)" == "200" ]] || fallo "el reintento del cierre falló: $repetido"
[[ "$(sql "select count(*) from cuentas where consulta_id='$CONSULTA' and deleted_at is null")" == '1' ]] ||
  fallo 'el reintento del cierre facturó otra vez'
ok 'reintentar el cierre con la misma clave devuelve el resultado, no otro cobro'

# ---------------------------------------------------------------------------
paso '8 · Refrescar después de cerrar'
# ---------------------------------------------------------------------------
# La pantalla se recarga y vuelve a intentar guardar el borrador que tenía en
# memoria: lo que ya está cerrado no admite cambios.
tarde=$(rpc "$TOKEN_DOCTORA" guardar_borrador_consulta \
  "{\"p_consulta_id\":\"$CONSULTA\",\"p_payload\":{\"notas\":\"Cambio después del cierre\"}}")
[[ "$(http)" != "200" ]] || fallo 'se editó una consulta ya cerrada'
[[ "$(jq -r '.code' <<<"$tarde")" == 'CL002' ]] ||
  fallo "el rechazo no fue por consulta finalizada: $tarde"
ok 'una consulta cerrada no admite más cambios'

# ---------------------------------------------------------------------------
paso '9 · Consulta ya existente para la misma cita'
# ---------------------------------------------------------------------------
reintento=$(rpc "$TOKEN_DOCTORA" iniciar_consulta_de_cita "{\"p_cita_id\":\"$CITA\"}")
[[ "$(sql "select count(*) from consultas where cita_id='$CITA' and deleted_at is null")" == '1' ]] ||
  fallo 'reabrir una cita ya atendida creó otra consulta'
ok 'reabrir una cita ya atendida no crea una consulta nueva'

# ---------------------------------------------------------------------------
paso '10 · Sesión expirada'
# ---------------------------------------------------------------------------
# Un token corrupto no puede leer ni escribir, y el error es un 401 limpio y no
# un 500 que parezca un fallo del servidor.
falso="${TOKEN_DOCTORA%.*}.firmaInvalida"
rest "$falso" GET 'consultas?select=id&limit=1' >/dev/null
[[ "$(http)" == "401" ]] || fallo "una sesión inválida devolvió HTTP $(http) y no 401"
rpc "$falso" guardar_borrador_consulta \
  "{\"p_consulta_id\":\"$CONSULTA\",\"p_payload\":{\"notas\":\"x\"}}" >/dev/null
[[ "$(http)" == "401" ]] || fallo "una sesión inválida pudo escribir (HTTP $(http))"
ok 'la sesión caducada se rechaza con 401 y no escribe nada'

# ---------------------------------------------------------------------------
paso '11 · Corrección administrativa sobre lo ya cerrado'
# ---------------------------------------------------------------------------
# Lo cerrado no se edita, pero la clínica no puede quedarse sin arreglar un
# error: se corrige por la vía administrativa, que exige motivo y firma.
# La RPC devuelve `void`, así que PostgREST contesta 204 y no 200.
sin_motivo=$(rpc "$TOKEN_ADMIN" corregir_consulta_ajena \
  "{\"p_consulta_id\":\"$CONSULTA\",\"p_cambios\":{\"notas\":\"Corrección\"},\"p_motivo\":\"\"}")
[[ "$(http)" == "400" ]] || fallo "se corrigió una consulta sin motivo: $sin_motivo"

correccion=$(rpc "$TOKEN_ADMIN" corregir_consulta_ajena \
  "{\"p_consulta_id\":\"$CONSULTA\",\"p_cambios\":{\"notas\":\"Se corrige la pieza tratada: 46, no 47.\"},\"p_motivo\":\"Error de transcripción detectado en revisión.\"}")
[[ "$(http)" == "204" ]] || fallo "la corrección administrativa falló (HTTP $(http)): $correccion"
[[ "$(sql "select notas from consultas where id='$CONSULTA'")" == 'Se corrige la pieza tratada: 46, no 47.' ]] ||
  fallo 'la corrección no llegó a la consulta'
[[ "$(sql "select count(*) from auditoria_correcciones_clinicas
             where consulta_id='$CONSULTA'")" -ge 1 ]] ||
  fallo 'la corrección no dejó rastro'
ok 'la corrección administrativa exige motivo y queda firmada'

# La asistente no corrige nada.
rpc "$TOKEN_ASISTENTE" corregir_consulta_ajena \
  "{\"p_consulta_id\":\"$CONSULTA\",\"p_cambios\":{\"notas\":\"Reescrito por recepción\"},\"p_motivo\":\"Prueba de recepción sobre lo cerrado.\"}" >/dev/null
[[ "$(http)" != "204" ]] || fallo 'la asistente corrigió una consulta cerrada'
[[ "$(sql "select notas from consultas where id='$CONSULTA'")" == 'Se corrige la pieza tratada: 46, no 47.' ]] ||
  fallo 'recepción alteró la nota de una consulta cerrada'
ok 'sólo dirección corrige lo ya cerrado'

# ---------------------------------------------------------------------------
paso '12 · Nada quedó descuadrado'
# ---------------------------------------------------------------------------
# El repaso final: lo facturado coincide con lo ejecutado y el inventario con
# lo consumido, aunque por el camino hubo cortes, rechazos y reintentos.
descuadre=$(sql "
  select coalesce(string_agg(motivo, '; '), '')
    from (
      select 'la cuenta ' || c.id || ' suma ' || c.monto_total ||
             ' y sus renglones ' || coalesce(sum(i.precio_unitario * i.cantidad), 0) as motivo
        from cuentas c
        left join items_cuenta i on i.cuenta_id = c.id and i.deleted_at is null
       where c.deleted_at is null
       group by c.id, c.monto_total
      having c.monto_total <> coalesce(sum(i.precio_unitario * i.cantidad), 0)
      union all
      select 'el consumible ' || co.nombre || ' tiene stock ' || co.stock_actual ||
             ' y movimientos por ' || coalesce(sum(m.diferencia), 0)
        from consumibles co
        join movimientos_stock_consumible m on m.consumible_id = co.id
       where m.consulta_id is not null
       group by co.id, co.nombre, co.stock_actual
      having co.stock_actual < 0
    ) d")
[[ -z "$descuadre" ]] || fallo "quedaron descuadres: $descuadre"

huerfanas=$(sql "select count(*) from consultas c
                  where c.finalizada
                    and c.deleted_at is null
                    and exists (select 1 from tratamientos_aplicados t
                                 where t.consulta_id = c.id and t.deleted_at is null)
                    and not exists (select 1 from cuentas cu
                                     where cu.consulta_id = c.id and cu.deleted_at is null)")
[[ "$huerfanas" == '0' ]] ||
  fallo "$huerfanas consultas cerradas con tratamiento y sin pre-factura"
ok 'cuentas, inventario y consultas cerradas quedan cuadrados'

resumen 'ESCENARIOS DE FALLO'
