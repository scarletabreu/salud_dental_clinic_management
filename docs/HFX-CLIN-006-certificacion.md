# HFX-CLIN-006 · Informe de certificación del core clínico

Fecha: 2026-07-31.
Rama: `hotfix-clinical-core-release-gate`, derivada de `hotfix` en `1d6dcc2`,
que ya acumulaba los seis tickets anteriores del programa.

**Decisión: se certifica el core clínico y se propone liberar `hotfix`.** El
alcance de esa liberación y sus condiciones están al final del documento.

---

## Cómo se reproduce

```bash
supabase/tests/hfx_clin_006_certificacion.sh
```

Un solo comando ejecuta los catorce gates, reconstruye la base desde cero entre
jornadas y deja la evidencia en `docs/qa/hfx-clin-006/`. Tarda unos 12 minutos.

No admite atajos: `SALTAR_RESET=1` existe sólo para depurar y el propio script
avisa de que en ese modo no certifica nada.

## Resultado de los gates

| Gate | Resultado | Evidencia |
|---|---|---|
| `supabase db reset` desde un clon limpio | ✅ | `db_reset.log` |
| `flutter analyze` | ✅ 0 errores, 0 warnings (139 `info` preexistentes) | `flutter_analyze.log` |
| `flutter test` | ✅ 757 pruebas, 0 rojas | `flutter_test.log` |
| `deno test` (Edge Functions) | ✅ 3 pruebas | `deno_test.log` |
| Suite SQL completa (12 ficheros) | ✅ 93 comprobaciones | `suite_sql.log` |
| Jornada admin-doctor | ✅ 11 comprobaciones | `jornada_admin_doctor.log` |
| Jornada doctor | ✅ 14 comprobaciones | `jornada_doctor.log` |
| Jornada asistente | ✅ 15 comprobaciones | `jornada_asistente.log` |
| Escenarios de fallo y concurrencia | ✅ 16 comprobaciones | `escenarios_de_fallo.log` |
| REST ofensivo (HFX-CLIN-001) | ✅ | `rest_ofensivo.log` |
| Concurrencia de cierre (HFX-CLIN-002) | ✅ | `concurrencia_cierre.log` |
| Contrato REST (HFX-CLIN-002) | ✅ | `contrato_rest.log` |
| Concurrencia de agenda (HFX-CLIN-004) | ✅ | `concurrencia_agenda.log` |
| Jornada E2E (HFX-CLIN-004) | ✅ | `jornada_e2e_004.log` |

La suite Dart sube de 735 a 757: 20 pruebas nuevas de reglas clínicas y 2 de la
sección de ajustes.

---

## El seed de certificación

`supabase/tests/hfx_clin_006_seed_certificacion.sql` levanta una clínica
completa sobre una base recién reseteada: tres actores capaces de iniciar
sesión, ocho pacientes que cubren los perfiles de riesgo del ticket, catálogo
clínico con contraindicaciones absolutas y relativas, inventario holgado y
escaso, y una agenda de siete citas. No contiene ningún dato real: cédulas con
prefijo `CERT`, correos en `cert.local`, nombres ficticios.

Es idempotente, así que ejecutarlo dos veces no duplica la agenda.

Dos decisiones que no se deducen leyéndolo:

- **Los usuarios se crean directamente en `auth.users` con la contraseña ya
  cifrada**, en vez de por la API de administración. Así el seed es un fichero
  SQL autosuficiente y las jornadas sólo tienen que iniciar sesión. La trampa:
  los campos de token deben ir a cadena vacía y no a nulo. Con nulo, GoTrue
  responde un 500 opaco —«Database error querying schema»— que parece un fallo
  de esquema y no lo es.
- **El nombre de las condiciones es contrato, no etiqueta.** El motor de alertas
  las busca con `lower(nombre) like '%embarazo%'`, `'%hipertensión%'` y
  `'%diabetes%'`. Renombrar «Diabetes mellitus tipo 2» a otra cosa apaga
  `COMB_DIABETES_SIGNOS` sin dar ningún error.

## Las jornadas

Todo pasa por REST con el JWT de quien haría cada acción en la clínica. Nada de
`set role`: eso se salta el JWT y deja pasar cosas que por HTTP fallarían.

**Admin-doctor** (11): identidad clínica completa en todas las capas, agenda
global más la propia, apertura de su consulta, autoría a su nombre, signos
vitales, hallazgo, tratamiento, receta, cierre con pre-factura de RD$ 2 500 y
descuento de inventario, cita completada, receta emitida, regreso a caja,
compras y personal, y línea de tiempo completa.

**Doctor** (14): sólo ve su agenda; cierra una consulta sin tratamiento;
reabrir reanuda en vez de duplicar; embarazo con 150/95 levanta la alerta, que
bloquea el cierre hasta documentarla; la contraindicación absoluta bloquea la
amoxicilina incluso justificada; la alternativa segura cierra con RD$ 12 000 e
inventario descontado; el riesgo relativo exige justificación por medicamento;
la condición descubierta hoy pasa al expediente al cerrar; cuatro reglas
disparan a la vez en el paciente diabético; la urgencia entra con la agenda
llena; la regla pediátrica exige el peso y se apaga al registrarlo; y no puede
firmar la cita de otro doctor.

**Asistente** (15): alta completa en una operación con el correo normalizado,
agenda, rechazo de solape, reprogramación con recálculo del fin, cancelación
registrada, llegada y handoff, urgencia encaminada, y después la otra mitad —no
abre consultas, no escribe en ellas, no las cierra, no lee consultas ni
recetas, no toca el perfil de un doctor— más lo que sí es suyo: la caja.

## Escenarios de fallo

Los 16 provocan a propósito lo que pasa en una clínica real. Los que más
importan:

- **Doble clic en «Iniciar consulta»**: dos peticiones simultáneas dejan una
  sola consulta.
- **Dos pestañas**: la que trae versión vieja recibe `CL001` y no pisa lo
  guardado.
- **Red caída a mitad del guardado**: la petición se corta a los 50 ms. La
  versión sube una vez o ninguna, y los signos vitales están los dos o ninguno
  —nunca uno—. Reintentar no duplica nada.
- **Doble cierre simultáneo**: una factura, un descuento de inventario. Un
  tercer intento con la misma clave devuelve el resultado sin volver a cobrar.
- **Stock insuficiente**: el cierre se detiene *antes* de tocar inventario o
  cuentas. Es la razón de que las barreras clínicas vayan primero en
  `cerrar_consulta`.
- **Repaso final de integridad**: cada cuenta cuadra con sus renglones, ningún
  consumible queda en negativo y ninguna consulta cerrada con tratamiento se
  quedó sin pre-factura, pese a los cortes, rechazos y reintentos del recorrido.

---

## Reglas clínicas: aprobación y gobierno

### Aprobación documentada

El dueño clínico aprobó el 31 jul 2026 los nueve umbrales que HFX-CLIN-003 había
dejado sembrados pero inertes. Una regla sin parámetros no se evalúa
—`hfx_clin_003_evaluar_alertas` filtra por `parametros is not null`—, así que
hasta esta fecha el sistema sabía avisar y no avisaba de nada.

| Regla | Umbral | Severidad / acción |
|---|---|---|
| `SV_PRESION_CRITICA` | sistólica < 90 o > 180 mmHg | crítica / documentar |
| `SV_PULSO_CRITICO` | pulso < 50 o > 120 lpm | crítica / documentar |
| `SV_TEMPERATURA_CRITICA` | temperatura < 35,0 o > 38,5 °C | crítica / documentar |
| `SV_SATURACION_CRITICA` | SpO₂ < 92 % | crítica / referir |
| `SV_DOLOR_SEVERO` | dolor > 7 /10 | advertencia / documentar |
| `PED_PESO_REQUERIDO` | exige peso en menores de 12 años | crítica / documentar |
| `COMB_EMBARAZO_SIGNOS` | embarazo + sistólica > 140 o diastólica > 90 | crítica / documentar |
| `COMB_HIPERTENSION_SIGNOS` | hipertensión + sistólica > 160 o diastólica > 100 | crítica / documentar |
| `COMB_DIABETES_SIGNOS` | diabetes + pulso > 110 o sistólica > 160 | crítica / documentar |

`SV_RANGO_IMPOSIBLE` y `SV_DIASTOLICA_MAYOR_SISTOLICA` ya estaban aprobadas
desde HFX-CLIN-003 y no cambian.

A partir de aquí, **una alerta pendiente impide cerrar la consulta** hasta que
el doctor la confirme o documente la decisión clínica.

### Los umbrales dejan de vivir en una migración

A petición del dueño, los umbrales se editan desde **Configuración → Reglas
clínicas**, no con un despliegue. Un umbral clínico es una decisión médica, y
obligar a tocar el repositorio para moverlo es la garantía más segura de que se
quede desactualizado.

- `publicar_regla_clinica(codigo, parametros, severidad, accion, nota)` crea una
  versión nueva y **retira la anterior**. Si las dos quedaran aprobadas, el motor
  evaluaría el mismo código dos veces y el doctor vería la alerta duplicada con
  dos umbrales distintos.
- Las alertas ya emitidas guardan `regla_codigo` y `regla_version`, así que
  siguen explicándose con la regla que las emitió. Revisar una consulta de hace
  un mes no muestra un motivo que entonces no existía.
- `retirar_regla_clinica(codigo, motivo)` no borra: el histórico se conserva.
- Reenviar el formulario sin cambios devuelve `sin_cambios: true` y no versiona.
  La pantalla lo dice en vez de fingir un guardado.
- La validación de parámetros vive en la base (`CL030`) y la pantalla la repite
  antes de enviar. Lo segundo es comodidad; lo primero es lo que nadie se salta.

---

## Defectos encontrados y corregidos durante la certificación

Los cinco salieron de ejecutar los gates, no de leer código.

**1 · `catalogo_signos_vitales` era escribible por cualquier usuario con sesión.**
Era la única tabla de `public` sin RLS y sin políticas, y conservaba el
`grant all` del esquema. De sus mínimos y máximos depende `SV_RANGO_IMPOSIBLE`:
vaciarla no da error, apaga la barrera en silencio. Ahora tiene RLS, se lee y no
se escribe desde el cliente. La comprobación de que ninguna tabla se queda sin
RLS forma parte de la evidencia (`estado_base.txt`).

**2 · El rastro de la edición de reglas no cabía donde iba a ir.**
`auditoria_operaciones_admin` referencia `admins` en `actor_id` y su política
exige `es_admin()`. Una doctora que no fuera administradora habría hecho fallar
la escritura del rastro y, con ella, la edición entera. La prueba SQL lo destapó
al primer intento. Editar un umbral es gobierno clínico y no una operación
administrativa, así que tiene su propia tabla, `auditoria_reglas_clinicas`, con
FK a `usuarios` y lectura para quien ejerce.

**3 · La prueba SQL de HFX-CLIN-003 dependía de que las reglas llegaran sin
aprobar.** Al aprobarlas, su premisa dejó de sostenerse. La prueba trata sobre
*cómo* una regla entra en vigor, así que ahora retira los umbrales de fábrica al
empezar —dentro de su transacción, que se revierte— y usa una regla propia. Ya
no depende de con qué estado venga la instalación.

**4 · `hfx_clin_002_contrato_rest.sh` llevaba roto desde HFX-CLIN-003 y
HFX-CLIN-004, sin que nadie lo notara.** Tres cosas a la vez: creaba un
tratamiento de pieza completa y le mandaba superficie (`CL012`), enviaba un
renglón de receta con sólo el nombre del medicamento (`CL008` en el cierre) e
insertaba la cita en `programada`, desde donde el grafo de estados ya no permite
llegar a `completada` (`CL016`). Ninguna de las tres es un fallo del producto:
son un test que se quedó atrás. Es exactamente el motivo por el que este ticket
existe —un gate que nadie ejecuta no es un gate—.

**5 · Regresión propia en la pantalla de configuración.** Añadir la sección de
reglas rompió seis pruebas responsive, que montaban `ConfiguracionPage` sin
sesión, y produjo un desbordamiento de 46 px a 320 px con el texto al doble. Lo
primero se arregló completando el arnés —en la app siempre hay sesión—; lo
segundo, con un `Wrap` en la cabecera de cada fila.

### Un problema del entorno, no del producto

**Kong cachea la IP del contenedor de Auth.** `supabase db reset` reinicia Auth
con una IP nueva y Kong no se entera, así que todo inicio de sesión devuelve un
502 —«An invalid response was received from the upstream server»— que **no se
cura esperando**. Una jornada lanzada justo después de un reset fallaba con «los
actores no pueden iniciar sesión» y hacía buscar el problema en el seed.
`hfx_clin_006_lib.sh` lo detecta y reinicia Kong.

---

## Estado de la base certificada

Diez migraciones, con su hash en `docs/qa/hfx-clin-006/estado_base.txt`. La de
este ticket:

```
d3793b500a006a9b  20260805090000_hfx_clin_006_reglas_clinicas_editables.sql
```

Once reglas clínicas en vigor, todas con umbral. Ninguna tabla de `public` sin
RLS ni sin políticas.

## Criterios de aceptación del ticket

- [x] `supabase db reset` funciona desde un clon limpio.
- [x] `flutter analyze` está limpio (0 errores, 0 warnings).
- [x] Toda la suite Flutter está verde (757/757).
- [x] Toda la suite SQL está verde (93 comprobaciones, 12 ficheros).
- [x] Pruebas REST por rol están verdes.
- [x] Edge Functions están verificadas.
- [x] Admin-doctor completa su jornada.
- [x] Doctor completa su jornada.
- [x] Asistente completa su jornada.
- [x] Escenarios de fallo no corrompen datos.
- [x] No quedan P0 o P1 del informe original.
- [x] Reglas clínicas tienen aprobación documentada.
- [x] Existe informe de certificación.

---

## Limitaciones conocidas

Ninguna bloquea la certificación, pero conviene tenerlas por escrito.

1. **No hay E2E de navegador.** Las jornadas ejercen la frontera REST con los
   tokens reales de cada rol, que es donde vivían los defectos del informe
   original, pero nadie ha pulsado los botones. La cobertura de la interfaz es
   la suite de widgets.
2. **Todo se certifica contra el stack local.** No se ha tocado ninguna
   instancia remota, ni debe hacerse sin la decisión explícita del dueño. Antes
   de un `db push` sigue pendiente el `supabase migration repair` que dejó el
   squash de HFX-CLIN-000.
3. **El contrato del payload de borrador sigue en v1.** Cada clave presente se
   interpreta como el conjunto completo deseado, así que no cabe el envío
   incremental por pieza. Está descrito en HFX-CLIN-005 y no ha cambiado.
4. **Las urgencias siguen fuera del control de solapamiento**, por decisión de
   HFX-CLIN-004: atender a alguien que ya está sangrando no puede exigir
   inventar un hueco libre.
5. **`flutter analyze` arrastra 139 `info`**, la mayoría `withOpacity`
   deprecado. Son preexistentes y no forman parte de este ticket.
6. **La aprobación de los umbrales no lleva UUID de firmante.** Se registró como
   decisión de la clínica como institución, con la fuente documentada en la
   migración. Toda edición posterior hecha desde la aplicación sí queda firmada
   con el UUID de quien la hizo.

## Decisión

**Se certifica.** Una base vacía se reconstruye desde el repositorio y permite
completar una jornada clínica entera sin un solo parche manual. Admin, doctor y
asistente hacen exactamente sus funciones y ninguno hace las del otro. Frente a
doble clic, dos pestañas, dos usuarios, red cortada y reintentos, el sistema
conserva la integridad clínica, financiera y de inventario, y ningún fallo queda
oculto.

Se propone liberar `hotfix` con los siete tickets del programa integrados.

Esta decisión **no autoriza** por sí sola integrar `hotfix` en `dev`,
desplegarlo ni aplicarlo a ninguna instancia remota: eso es una decisión
posterior e independiente del dueño, tal como establece el plan.
