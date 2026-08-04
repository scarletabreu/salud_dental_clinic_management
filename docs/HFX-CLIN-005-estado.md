# HFX-CLIN-005 · Auditoría, UX, accesibilidad y rendimiento

Fecha de cierre técnico: 2026-07-31.
Rama: `hotfix-clinical-ux-audit`, derivada de `hotfix` en `7b7abe6`.

## Resultado

La consulta ya no puede contar una historia distinta de la del servidor:

- cada hecho clínico y administrativo queda registrado y es consultable como
  una línea de tiempo, con actor, rol, fecha y motivo;
- un guardado que el servidor rechazó no vuelve a pintarse como confirmado, y
  su motivo se queda en pantalla hasta que alguien lo resuelva;
- una consulta cerrada deja de ofrecer edición en vez de avisar sobre un
  borrador que ya no existe;
- el vocabulario es el mismo en el odontograma, la receta, el plan y la
  auditoría;
- el selector de medicinas vuelve a abrirse, las piezas se operan con teclado
  y los diálogos dejan de estirarse en pantallas altas;
- las operaciones clínicas se miden con códigos estables y sin PII.

## La auditoría

`auditoria_clinica` pasó de tres eventos escritos a mano dentro de tres RPC a
una tabla que **llenan los triggers de las tablas de destino**. La diferencia
importa: da igual si el cambio entró por `guardar_borrador_consulta`, por una
corrección administrativa o por REST directo; queda registrado igual. Un rastro
que sólo existe cuando se usa el camino previsto no sirve para auditar.

Cambios de esquema:

- `consulta_id` deja de ser obligatorio y aparece `cita_id`. La llegada del
  paciente es el primer hecho del día y ocurre cuando todavía no hay consulta:
  sin esto, el timeline empezaría por el medio.
- `auditoria_clinica`, `auditoria_correcciones_clinicas` y
  `auditoria_operaciones_admin` pierden `insert/update/delete/truncate` para
  `authenticated` y `anon`.

Eventos que se registran:

| Origen | Eventos |
|---|---|
| `citas` | `cita_creada`, `cita_llegada`, `cita_en_consulta`, `cita_completada`, `cita_cancelada`, `cita_no_asistio`, `cita_reprogramada`, `cita_eliminada` |
| `consultas` | `consulta_guardada` (una por versión confirmada) |
| `diagnosticos_aplicados` | `diagnostico_agregado`, `diagnostico_retirado` |
| `tratamientos_aplicados` | `tratamiento_ejecutado`, `tratamiento_actualizado`, `tratamiento_anulado` |
| `recetas` | `receta_emitida`, `receta_anulada`, `receta_reemplazada` |
| `planes_tratamiento` | `plan_propuesto`, `plan_aceptado`, `plan_rechazado` |
| `consentimientos_plan` | `consentimiento_aceptado`, `consentimiento_rechazado` |
| `alertas_clinicas` | `alerta_emitida` (la resolución ya la firmaba su RPC) |
| `auditoria_correcciones_clinicas` | `correccion_administrativa` |
| RPC previas | `consulta_iniciada`, `consulta_cerrada`, `alerta_resuelta` |

`linea_tiempo_consulta(p_consulta_id)` devuelve los eventos de la consulta y
los de su cita en una sola lectura cronológica, comprueba visibilidad antes de
devolver nada (`CL020`) y resuelve el nombre del actor —y nada más de su
ficha—. La app la consume con una sola llamada: pedir el nombre por evento
sería un N+1 contra `personas`.

### Decisiones que no se deducen del código

- **El borrador de receta no genera evento.** Se reescribe en cada autoguardado
  y llenaría la línea de tiempo de ruido. Lo que se audita es el acto médico:
  emitir, anular, reemplazar.
- **Sin sesión, el evento no inventa autor.** Una migración o un script de
  mantenimiento quedan con `actor_id` nulo y rol `sistema`. Una auditoría que
  atribuye actos a quien no los hizo es peor que una incompleta.
- **`consulta_guardada` sale del salto de `version`**, no de un `insert`
  explícito en la RPC. Así cuenta guardados confirmados y no intentos.

## Estados de persistencia

`ConsultaCerradaEnServidor` es nuevo y separa dos cosas que antes viajaban
juntas como `ConsultaError`: un fallo que se puede reintentar, y un expediente
que ya cerró y donde no hay nada que reintentar.

Dos defectos de origen corregidos:

1. **El cierre fallido pintaba «Guardado».** El `catch` emitía `ConsultaError`
   seguido de un `ConsultaIniciada` limpio, cuyo `guardado` volvía por defecto
   a `alDia`. Justo después de que el cierre se cayera, el chip decía que todo
   estaba en el servidor. Ahora vuelve como `fallido`/`conflicto` con su
   motivo.
2. **El fallo clínico duraba tres segundos.** Era un snackbar. Ahora es un
   aviso que se queda hasta que el usuario lo descarta o hasta que una
   operación posterior confirma, más un aviso dentro del workspace con las
   acciones que lo resuelven («Reintentar ahora», «Recargar lo confirmado»).

## Terminología

| Antes | Ahora | Por qué |
|---|---|---|
| «Aplicado» / «Completado» | «Ejecutado» / «Ejecutado y cerrado» | Es como se llama en la cuenta y en la línea de tiempo |
| «Terminado» (chip de la pieza) | «Ejecutado» | Mismo vocabulario en los tres ejes |
| «Realizado en esta consulta» | «Registrado como ejecución en esta consulta» | Aparecía sobre un chip que decía «En proceso» |
| Procedencia «Ejecutado» | «Ejecutado hoy» | Compartía rótulo con el estado dentro del mismo panel |
| «Reemitir / Corregir Receta» en la primera emisión | «Emitir receta médica» hasta que exista una emitida | Reemitir es corregir un papel que el paciente ya tiene |

`marca.ejecucionCerrada` sustituye a la comparación `marca.estado != 'Terminado'`
que había en `panel_detalle_pieza`: una etiqueta de pantalla no es una API, y
al cambiarla se llevó por delante al que la comparaba a mano.

## Accesibilidad y defectos visuales

- **Selector de medicinas.** El fondo de la hoja era un `BoxDecoration` sobre
  el `Material` transparente de la hoja modal: el framework abortaba el frame
  con una aserción de `ListTile` y el selector no llegaba a verse. Ahora el
  fondo lo pone el propio `Material`.
- **Piezas del odontograma.** Eran un `GestureDetector`: sólo existían para el
  ratón. Con `FocusableActionDetector` entran en el recorrido de tabulación y
  responden a Enter y espacio. Abrir la pieza es el primer paso para anotar un
  hallazgo; si sólo se podía con el ratón, el recorrido con teclado se cortaba
  ahí.
- **Diálogos.** `AppDialog` ya acotaba el ancho; ahora también el alto (620 px
  o lo que quepa, lo que sea menor) y el contenido hace scroll. `RecetaFormDialog`
  deja sus 650 px fijos —que se salían de un teléfono— y pasa a `AppDialog`.
- **Riesgo sin depender del color.** Los avisos y la línea de tiempo llevan
  icono además de tono.

## Rendimiento y métricas

`MetricasClinicas` mide agenda, apertura, guardado, cierre y línea de tiempo.
Su contrato es negativo por construcción: no existe ningún campo donde quepa un
UUID, una cédula, un nombre o una nota. Sólo operación, duración, resultado,
código de error estable, bytes y número de solicitudes.

Un guardado que no lleva nada ya no sale a la red. La comparación es por
identidad de la `Consulta` confirmada: como cada edición construye una
instancia nueva, sólo puede sobrar un guardado, nunca faltar uno. Se registra
como `omitida`, que distingue «no había nada que mandar» de «la red va lenta».

### Lo que no se hizo, y por qué

**No se implementó el envío incremental por pieza.** El contrato del payload
(HFX-CLIN-002, versión 1) dice que una clave presente describe el conjunto
completo deseado, y `hfx_clin_002_aplicar_borrador` sólo recorre las piezas que
recibe. Omitir una pieza «vacía» haría que retirar el último tratamiento de una
pieza no lo borrara nunca: el servidor no se enteraría. Hacerlo bien exige una
versión 2 del payload que distinga «esta pieza no cambió» de «esta pieza quedó
vacía», y eso es un cambio de contrato servidor+cliente que no cabe en este
ticket. Queda anotado para HFX-CLIN-006 o para un ticket propio.

## Hallazgo lateral: SIGSEGV con `SET ROLE anon`

Escribiendo las pruebas SQL apareció esto, y conviene que quede escrito porque
volverá a morder:

En la imagen local de Supabase (PostgreSQL de `supabase/postgres`), una sesión
**superusuario** que hace `set local role anon` y llama a una función sobre la
que no tiene privilegio **tumba el backend con SIGSEGV** en vez de devolver
`42501`. Se reproduce con cualquier función sin grant para `anon`; reinicia el
servidor y corta todas las conexiones, así que una suite SQL que lo haga queda
inservible a partir de ahí.

**No es alcanzable por la API.** La misma llamada por REST con la anon key
responde `401 {"code":"42501"}` y la base sigue viva; PostgREST se conecta como
`authenticator` y ahí no ocurre. Es una trampa del arnés de pruebas, no un
agujero del producto.

Por eso la prueba 10 de este ticket comprueba los grants de `anon` en el
catálogo (`has_function_privilege`) en vez de llamar a la función, que es lo
mismo que ya hacía HFX-CLIN-001.

## Validación ejecutada

- `supabase db reset` desde cero: aplica las 10 migraciones sin intervención.
- `supabase/tests/hfx_clin_005_auditoria_test.sql`: 11 comprobaciones.
- Suites SQL anteriores tras el reset, para descartar regresión de los
  triggers: 000 (9), 001 (6), 002 (12), 003 (13), 004 (14), SD-111 (6),
  SD-146 (8), SD-135 y SD-169 sin errores.
- `flutter analyze`: sin errores; 9 warnings y 130 infos, todos preexistentes.
- `flutter test`: suite completa en verde.

## Criterios de aceptación

- [x] No hay estado clínico visible como confirmado si el servidor lo rechazó.
- [x] No se puede seguir editando después del cierre.
- [x] Terminología consistente en todas las pantallas.
- [x] Timeline refleja acciones clínicas y administrativas.
- [x] Sin excepciones Flutter durante el recorrido.
- [x] Modales funcionan en todos los viewports definidos.
- [x] Acciones críticas son accesibles por teclado y lector.
- [x] Autoguardado no duplica ni pierde cambios.
- [x] No existen N+1 identificados en agenda/consulta.
- [x] Métricas no contienen PII.
