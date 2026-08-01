# Plan de corrección — QA Clínica Salud Dental Integral (1 ago 2026)

Origen: jornada de QA sobre el deploy de producción (31 jul) + 3 reportes directos
(Detalle de Cuenta, Perfiles, visibilidad de diagnósticos/tratamientos). Todos los
defectos fueron investigados en la rama `dev` con evidencia `archivo:línea`; la gran
mayoría existe también aquí, no solo en producción.

## Diagnóstico transversal

Dos causas de fondo explican más de la mitad de los síntomas:

1. **Deriva de esquema en producción.** La instancia remota tiene objetos que el
   repositorio nunca versionó: las vistas `pacientes_seguro`, `personas_seguro`,
   `contactos_seguro`, la tabla `doctor_paciente` y policies de SELECT distintas a
   la línea base (`pacientes_select`, `cuenta_select`, `cuotas_select`,
   `items_cuenta_select`, `pago_select`, `odontograma_select` usan las guardias
   `puede_ver_paciente`/`puede_ver_cuenta`/`puede_ver_consulta` en vez de los tres
   roles planos). El cliente asume el modelo del repo. Evidencia: catálogos pgdelta
   en `supabase/.temp/pgdelta/` y cabecera de
   `supabase/migrations/20260810090000_hfx_clin_011_versionar_guardias_produccion.sql:9-12`.
   Mientras `supabase db diff --linked` no sea vacío, cualquier fix de cliente se
   prueba contra un esquema que el repo no describe.

2. **Modelo de permisos demasiado grueso y sin aplicar en pantalla.** Las
   capacidades existen (`lib/features/auth/domain/capacidades_usuario.dart`) pero:
   (a) varias agrupan permisos que QA exige separar (`gestionarAgendaCompleta`
   mezcla "agendar para mí" con "agendar para todos"; `gestionarCatalogosClinicos`
   mezcla "ver catálogo" con "editarlo"); y (b) **ninguna pantalla de catálogo
   consulta capacidad alguna** — los botones Nuevo/Editar/Eliminar se renderizan
   siempre. El SQL acompaña el hueco: las policies de catálogos permiten
   `es_admin() OR es_doctor()` en INSERT/UPDATE/DELETE.

---

## Inventario de defectos → fase

| # | Defecto (QA / reporte) | Rol | Fase |
|---|---|---|---|
| D1 | Detalle de Cuenta: "Error al obtener las cuotas: Capacidad de caja requerida" | doctor | F1 |
| D2 | Perfiles: "more than one relationship was found for 'admins' and 'doctores'" + error de sección completa | admin/doctor | F1 |
| D3 | Pacientes no cargan: "no relationship between 'pacientes_seguro' and 'persona_contactos'" | admin | F0+F1 |
| D4 | Consultas muestran `Paciente #uuid` en vez del nombre | admin/doctor | F1 |
| D5 | Diagnósticos/tratamientos de la consulta no se ven en paciente, expediente ni PDF | doctor | F2 |
| D6 | Odontograma del expediente/PDF sale vacío ("NO FUNCIONA EL ODONTOGRAMA") | doctor | F2 |
| D7 | "ERROR AL TERMINAR CONSULTA (SALE COMO COMPLETADA)" | doctor | F2 |
| D8 | Doctor puede editar/borrar tratamientos, procedimientos, diagnósticos, medicinas y ver precios | doctor | F3 |
| D9 | Doctor ve "Cuentas por Cobrar" | doctor | F3 |
| D10 | Doctor no puede crear cita que no sea de emergencia | doctor | F3 |
| D11 | Doctor no ve consultas de otros doctores (listado queda vacío al filtrar) | doctor | F3 ⚠️ decisión |
| D12 | Asistente ve citas/consultas de doctores no asignados y puede cambiar estados de cita | asistente | F3 |
| D13 | Asistente no puede abrir/cerrar caja chica | asistente | F3 |
| D14 | Admin con cita agendada no puede iniciar consulta | admin | F3 |
| D15 | "Mis Citas del Día" sin filtro todos-los-doctores / solo-los-míos | admin | F4 |
| D16 | Búsqueda de paciente por cédula no encuentra nada al agendar | admin | F4 |
| D17 | Expediente clínico sin selección de rango de fechas (+ opción del modal ignorada) | doctor | F4 |
| D18 | Botón "Generar Expediente Clínico" aparece cuando no debería | doctor | F4 |
| D19 | Ventana "Equipos" duplicada en el menú | admin | F4 |
| D20 | Admin "que ya tiene consultas dice que no tiene" | admin | F1 (consecuencia de D3/D4 + RLS) |

---

## Fase 0 — Reconciliar el esquema (prerrequisito de todo lo demás)

**Contexto.** El repo declara `supabase db reset` como bootstrap (HFX-CLIN-000) y
las migraciones como fuente de verdad, pero producción acumuló objetos creados a
mano (Studio) que cambian el comportamiento de PostgREST y de RLS.

**Por qué.** D3 es la prueba directa: el mensaje de error nombra `pacientes_seguro`,
una vista que no existe en ningún SQL del repo ni en ninguna rama de git. La caché
de esquema de PostgREST en producción está resolviendo relaciones contra esa vista,
que no propaga el embed anidado `personas → persona_contactos → contactos`.
Además `doctor_paciente` + `puede_ver_paciente()` recortan lo que ve un doctor
no-admin de una forma que el cliente no conoce (contribuye a D4, D11, D20 y al
detalle de cuenta vacío post-D1).

**Dónde.**
- Catálogos: `supabase/.temp/pgdelta/catalog-xcuvywvltttephakzmwu-*.json` (remoto)
  vs `catalog-local-*.json`.
- Guardias ya versionadas a posteriori:
  `supabase/migrations/20260810090000_hfx_clin_011_versionar_guardias_produccion.sql`.
- `supabase/schema.sql` desfasado (no contiene HFX-CLIN-008 ni
  `iniciar_consulta_de_cita`): dejar claro que NO es referencia.

**Cómo / solución (decidido 1 ago: EL MODELO DE PRODUCCIÓN ES EL OFICIAL).**

El usuario decidió seguir las policies que están en producción, no las de la
línea base del repo. El repo se pone al día y el cliente se adapta al modelo
restrictivo (doctor ve pacientes asignados vía `doctor_paciente`).

1. `supabase db diff --linked` y auditar la deriva completa.
2. **Retirar SOLO las vistas** `pacientes_seguro`/`personas_seguro`/`contactos_seguro`:
   están huérfanas (ninguna policy, función ni código de ninguna rama las
   referencia). Antes del drop, verificación mecánica en producción con
   `pg_depend` + `pg_policies` de que nada depende de ellas; el drop se aborta si
   aparece un dependiente.
3. **Versionar tal cual** `doctor_paciente` + `fn_autoasignar_doctor_paciente` y
   **las policies de producción** (`pacientes_select`, `persona_select`,
   `cuenta_select`, `cuotas_select`, `items_cuenta_select`, `pago_select`,
   `odontograma_select` con sus guardias `puede_ver_*`): migraciones que las
   recrean idénticas para que la base local reproduzca producción. Cero cambios
   de comportamiento en producción en este paso.
4. **Puente para los nombres (nuevo, versionado):** con el modelo restrictivo, un
   doctor que ve todas las consultas (D11) no puede leer los `pacientes` ajenos →
   los listados volverían a `Paciente #uuid`. Se crea una vista mínima de
   directorio (id, nombre, apellido — sin contactos ni datos clínicos), legible
   por todo el personal clínico, al estilo SD-146. Es la versión bien hecha de lo
   que `pacientes_seguro` intentaba ser. Los listados resuelven nombres contra
   ella; la ficha completa del paciente sigue restringida por asignación.
5. `notify pgrst, 'reload schema'` tras aplicar cambios en producción.
6. Regenerar `supabase/schema.sql` de referencia.
7. Gate de salida: `supabase db diff --linked` vacío.

**Consecuencia para el cliente (F1/F3):** las pantallas deben entender el modelo
restrictivo — "no veo la ficha completa de este paciente" es un estado normal
para un doctor no asignado, no un error; los nombres salen del directorio.

**Resultado esperado.** Local y producción describen el mismo esquema; los fixes de
las fases siguientes se prueban contra la realidad. D3 puede quedar resuelto aquí
solo con retirar `pacientes_seguro` (F1 añade el blindaje de cliente igualmente).

⚠️ **Seguridad:** tocar policies/objetos de producción pasa por el flujo de
migración manual documentado (nada de `db push`), con confirmación explícita antes
de aplicar cada script en la instancia remota.

---

## Fase 1 — Pantallas bloqueadas (los errores rojos)

### D1 · "Capacidad de caja requerida" en Detalle de Cuenta

- **Contexto:** un doctor abre "Detalle de Cuenta" (desde el paciente o al terminar
  consulta) y la pantalla entera muere.
- **Por qué:** leer cuotas ejecuta primero una **RPC de escritura**.
  `CuotaRepositoryImpl.getCuotasDeCuenta`
  (`lib/features/cuota/data/repositories/cuota_repository_impl.dart:15`) llama
  `marcar_cuotas_vencidas` antes del SELECT. Esa RPC exige
  `es_admin() OR es_asistente()`
  (`supabase/migrations/20260731120000_hfx_clin_001_seguridad_rpc_rls.sql:261-273`)
  y lanza `42501 'Capacidad de caja requerida.'`. El doctor tiene permiso de LEER
  cuotas (`linea_base.sql:3863`) pero el cliente lo obliga a ESCRIBIR.
- **Dónde:** `cuota_repository_impl.dart:15-18`,
  `cuota_remote_datasource_impl.dart:23-28`, guard SQL en `hfx_clin_001:253-289`.
- **Solución:** desacoplar. Sacar `marcarCuotasVencidas` de `getCuotasDeCuenta` y
  ejecutarla solo en los flujos de cobro (admin/asistente), tolerando además un
  `42501` de esa RPC sin abortar la lectura (defensa en profundidad). No relajar el
  guard SQL: es idempotente pero es una escritura contable.
- **Resultado esperado:** cualquier rol con SELECT ve el detalle de cuenta; el
  marcado de vencidas sigue ocurriendo donde se cobra.

### D2 · Perfiles: embed ambiguo + error de sección completa

- **Por qué (embed):** desde HFX-CLIN-001 existe `auditoria_correcciones_clinicas`
  con FK a `doctores` y a `admins` (`hfx_clin_001:341-342`); PostgREST la infiere
  como junction table y ahora hay **dos caminos** `admins↔doctores`. El embed
  `'*, doctores(*, usuarios(...))'`
  (`lib/features/auth/data/repositories/usuario_repository_impl.dart:25-26`) se
  volvió ambiguo. Regresión temporal: HFX-CLIN-000 funcionaba, 001 la rompió.
- **Por qué (sección completa):** `getUsuarios()` corre las tres lecturas
  (doctores/admins/asistentes) dentro de **un solo** `runGuarded`
  (`usuario_repository_impl.dart:115-163`) y el cubit emite `PerfilError` global
  (`personal_perfiles_cubit.dart:13-22`) → pantalla completa de error.
- **Solución:**
  1. Hint de constraint: `doctores!admins_id_doctores_fkey(...)` en
     `usuario_repository_impl.dart:26` (la clave JSON `doctores` no cambia; el
     mapper `admin_model.dart:22` queda intacto).
  2. Aislar fallos: guard por tabla y deserialización por fila; `PerfilLoaded`
     gana una lista de avisos parciales y la UI pinta el error **en la tarjeta del
     perfil afectado**, no en la sección (petición explícita del usuario).
- **Resultado esperado:** Perfiles carga siempre; un perfil corrupto muestra su
  propio error inline y el resto del personal se administra con normalidad.

### D3/D4/D20 · Pacientes no cargan, consultas muestran uuid, "admin sin consultas"

- **Por qué:** son el mismo fallo visto desde tres pantallas.
  `getPacientes()` usa el embed anidado
  (`lib/features/paciente/data/datasources/paciente_remote_datasource.dart:16-18,40-52`)
  que producción no resuelve (D3, deriva F0). El listado de consultas **no embebe
  al paciente**: resuelve nombres con una segunda llamada a `getPacientes()` y
  **traga el error** (`consultas_list_cubit.dart:156-159`, `fold((_) => [])`) →
  todas las filas caen al fallback `'Paciente #$uuid'`
  (`consultas_list_state.dart:68-70`). Con RLS de producción
  (`puede_ver_paciente` + `doctor_paciente`), un doctor sin asignaciones activas
  recibe cero pacientes y cero consultas visibles → "dice que no tiene" (D20).
- **Solución:**
  1. Cliente: replicar en `getPacientes()` el patrón de consultas planas que
     `_fetchPacienteModel` ya usa a propósito
     (`paciente_remote_datasource.dart:302-332`) — deja de depender de la
     inferencia de relaciones de PostgREST.
  2. Cliente: en el listado de consultas, embeber el paciente en `_selectConsulta`
     (o resolver nombres con `inFilter('id', ids)`) y **propagar** el fallo de
     nombres en vez de tragarlo.
  3. SQL (F0): los nombres de pacientes no asignados se resuelven contra la
     vista de directorio (F0.4); la ficha completa sigue restringida por
     `doctor_paciente` — eso ahora es comportamiento esperado, no defecto.
- **Resultado esperado:** Pacientes lista lo que el rol puede ver; Consultas
  muestra nombres siempre (vía directorio); si algo falla, se ve un error
  honesto, no un uuid.

---

## Fase 2 — Visibilidad clínica: diagnósticos, tratamientos, odontograma, PDF

**Contexto.** La escritura funciona: `guardar_borrador_consulta`/`cerrar_consulta`
persisten en `tratamientos_aplicados`, `diagnosticos_aplicados` y `dientes`
(HFX-CLIN-002/003). Lo roto es la **lectura y el render**. Cuatro causas
independientes se suman para que "no se vea nada en ningún lado".

### D6a · El odontodiagrama del PDF está vacío por construcción

- **Por qué:** `ExpedientePdfBuilder._objToMap` convierte entidades por duck-typing
  y luego lee `oMap['dientes']`
  (`lib/features/record/presentation/helpers/expediente_pdf_builder.dart:794-854`),
  pero `OdontogramaModel.toJson()` **no emite `dientes`**
  (`odontograma_model.dart:40-51`) y `HistorialPiezas` ni siquiera tiene `toJson`
  (el campo real es `porFdi`). Las 52 piezas evalúan a vacío, siempre. **Nunca ha
  pintado una marca**; ningún test lo cubre.
- **Solución:** eliminar `_objToMap` y leer los campos tipados (`o.dientes`,
  `hp.porFdi`). Añadir test que afirme marcas en el PDF con una consulta sembrada.

### D6b · El odontograma en pantalla solo dibuja 6 entradas de catálogo

- **Por qué:** la proyección exige `clave_odontograma`
  (`proyeccion_odontograma.dart:25-30`) y el catálogo solo la tiene sembrada en 5
  diagnósticos + 1 tratamiento (`migrations_historicas/20260724180000_sd_150...:49-70`).
  Resina, corona, endodoncia, etc. proyectan NULL → descartadas → lienzo en blanco.
- **Solución:** sembrar `clave_odontograma` en el catálogo real (migración de
  UPDATE por nombre/categoría, mapeando cada tratamiento/diagnóstico a una de las
  claves FDI existentes) y/o proyectar una marca genérica ("Otro") cuando falte la
  clave, para que ninguna intervención sea invisible.

### D6c · El detalle de consulta proyecta la evaluación cruda

- **Por qué:** `odontograma_tratamientos_detalle.dart:45-49` pasa
  `odontograma.evaluacion` (solo tejidos blandos, por diseño de
  `evaluacionToJson`, `odontograma.dart:45-47`) en vez de
  `evaluacionProyectada`. Hallazgos siempre vacíos → el "Imprimir Odontodiagrama"
  de esa vista también sale en blanco.
- **Solución:** usar `odontograma.evaluacionProyectada` (una línea) + test golden.

### D5 · Lo registrado "sin pieza" es invisible en todas las lecturas

- **Por qué:** el canal general escribe con `diente_id NULL`
  (`hfx_clin_003:1411-1426,1465-1476`), pero `_selectConsulta` cuelga todo de
  `dientes` (`consulta_remote_datasource_impl.dart:27-33`), el historial por pieza
  usa `dientes!inner` (`:232,:260`) y el PDF recorre `dientes[]`. Nada lee los
  generales. Además la RPC no devuelve sus ids → cada autoguardado los
  soft-borra y reinserta.
- **Solución:** incluir los generales como colección hermana en `_selectConsulta`,
  quitar el `!inner` (o consultar por `consulta_id`), pintarlos en expediente,
  timeline del paciente (`paciente_detail_page.dart:993-1015` hoy solo pinta
  chips) y PDF; y en SQL, hacer que `hfx_clin_003_aplicar_extras` devuelva los ids
  para que el cliente los selle.

### D7 · "Error al terminar consulta (sale como completada)"

- **Por qué:** `cerrar_consulta` es transaccional; la parcialidad es aparente.
  (a) `terminarEvaluacion` no distingue `ConsultaCerradaFailure`
  (`consulta_cubit.dart:1183-1192`) — un reintento tras timeout muestra error
  genérico sobre una consulta ya cerrada; `terminarConsulta` sí lo maneja
  (`:1098-1106`). (b) Tras cerrar, la app navega a `PreFacturaPage`
  (`efectuar_consulta_page.dart:275-284`) que en producción muere por D1/RLS → el
  usuario percibe "error al terminar" con la cita ya completada.
- **Solución:** tratar `ConsultaCerradaFailure` igual en ambos caminos; D1 y F0
  eliminan el fallo de la pre-factura. Mensaje diferenciado si la consulta cerró
  pero la pre-factura no pudo mostrarse.

**Resultado esperado de la fase:** lo que el doctor registra en la consulta se ve
en el detalle del paciente, el expediente, el historial por pieza, el odontograma
y el PDF; terminar consulta nunca reporta error falso.

---

## Fase 3 — Matriz de permisos por rol

**Contexto.** QA fija la regla de negocio por rol; hoy ni el cliente ni el SQL la
imponen. Cambios en dos capas siempre: la UI oculta, la BD impone.

### D8 · Doctor: catálogos de solo lectura y sin precios

- **Dónde:** cero gating en las 4 pantallas (`tratamiento_screen.dart:159-163`,
  `tratamiento_card.dart:153,166-179`, `medicina_list_page.dart:348-352,1188-1264`,
  `procedimiento_list_page.dart:174-250`, `diagnosos_list_page.dart:186-431`);
  policies `es_admin() OR es_doctor()` + `GRANT ALL` en las 4 tablas
  (`linea_base.sql:4393-4905,4822+`).
- **Solución:** nueva `Capacidad.editarCatalogosClinicos` (admin-only) separada de
  la visibilidad del menú, y `Capacidad.verPreciosTratamiento` (admin, y asistente
  si factura); consumirlas en las 4 pantallas. En SQL, migración que reescribe
  INSERT/UPDATE/DELETE de `tratamientos`, `procedimientos`, `diagnosticos`,
  `medicinas` a solo `es_admin()` — **sin tocar** las `*_aplicados`, que son
  clínicas y del doctor.
- **Resultado esperado:** doctor consulta catálogos sin precios ni botones de
  edición; un UPDATE directo por API muere en RLS.

### D9 · Doctor sin "Cuentas por Cobrar"

- **Dónde:** `shell_destination.dart:72-79` agrupa `cuentasPorCobrar` con
  `pacientes`/`citasDelDia` por nombre de rol; el test lo fija
  (`test/responsive_shell_test.dart:194`).
- **Solución:** gatear por capacidad (`puedeGestionarCaja` o nueva
  `verCuentasPorCobrar` = admin+asistente) y actualizar el test. Aprovechar para
  cerrar la deuda reconocida en `shell_destination.dart:57-60`: `perfiles` sigue
  abierto al doctor pese a que `administrarPersonal` es admin-only.

### D10 · Doctor puede agendar citas normales (en su propia agenda)

- **Dónde:** `mis_citas_del_dia_page.dart:118-160` degrada a urgencia si no tiene
  `puedeGestionarAgendaCompleta` (admin|asistente). El SQL ya permite al doctor
  insertar citas propias (`hfx_clin_001:434-438`).
- **Solución:** `Capacidad.agendarCitaPropia` (los tres roles); el diálogo fija y
  bloquea el selector de doctor cuando solo puede agendarse a sí mismo.

### D11 · Doctor y consultas ajenas — DECIDIDO (1 ago): acceso total TEMPORAL

- **Dónde:** `consulta_select USING (es_admin() OR doctor_id = auth.uid())`
  (`hfx_clin_001:478-486`) + `puede_ver_consulta()` propagada a recetas, consumos,
  signos vitales y odontogramas.
- **Decisión:** por ahora el doctor ve **todas** las consultas; es un arreglo
  temporal — Isaac hará la solución definitiva. Implementación: migración que
  relaja `consulta_select` a `es_admin() OR es_doctor()` y añade `es_doctor()` a
  `puede_ver_consulta()` (para que el expediente completo — recetas, consumos,
  signos, odontogramas — también resuelva). **Marcar ambas con comentario
  `-- TEMPORAL (QA 1-ago): revertir cuando Isaac entregue el modelo definitivo`**.
  La escritura sigue restringida al doctor firmante (no se toca `consulta_insert`
  ni las RPC).

### D12 · Asistente: alcance por doctores asignados y sin cambiar estados

- **Dónde:** `citas_select`/`citas_update`/`citas_delete` dan `es_asistente()` sin
  condición (`hfx_clin_001:427-451`); el recorte por `doctor_asistentes` es solo
  cosmético en memoria (`cita_cubit.dart:98-102`) y no existe para consultas; el
  dropdown de estado se pinta para el asistente
  (`mis_citas_del_dia_page.dart:1248,1456-1476`).
- **Solución:** SQL — `citas_select` condicionada a `EXISTS (doctor_asistentes)`,
  y update/delete gobernados por la matriz de estados de abajo (conserva
  `registrar_llegada_cita`, SECURITY DEFINER); vista tipo SD-146 para el mínimo
  administrativo de consultas. Cliente — el dropdown de estado ofrece solo las
  transiciones permitidas al rol, y aplicar `doctorIdsPermitidos` a
  `ConsultasListCubit`.
- **Matriz de estados (decisión 1 ago: cada rol cambia unos estados, el admin
  todos). Propuesta concreta a validar al arrancar F3:**

  | Transición | Admin | Doctor (su cita) | Asistente (doctor asignado) |
  |---|---|---|---|
  | `programada → confirmada` | ✔ | — | ✔ |
  | `programada/confirmada → enEspera` (registrar llegada) | ✔ | ✔ | ✔ |
  | `→ reprogramada` | ✔ | — | ✔ |
  | `→ cancelada` | ✔ | ✔ | ✔ |
  | `→ noAsistio` | ✔ | — | ✔ |
  | `enEspera → enConsulta` (iniciar consulta, vía RPC) | ✔ | ✔ | — |
  | `enConsulta → completada` (cerrar consulta, vía RPC) | ✔ | ✔ | — |

  Racional: el asistente maneja lo administrativo de la agenda; el doctor lo
  clínico de sus propias citas (los estados clínicos ya salen de las RPC, no del
  dropdown); el admin todo. La matriz se impone en la policy `citas_update`
  (por estado origen/destino y rol) y se refleja en el dropdown.

### D13 · Asistente y caja chica

- **Hallazgo:** **no hay ningún gating que excluya a la asistente**, ni en cliente
  (`capacidades_usuario.dart:57-60`: caja = admin|asistente) ni en SQL
  (`authenticated_manage_cajas`, `linea_base.sql:3620-3630`, idéntica en
  producción). Las causas probables del síntoma son otras: (a) errores tragados —
  `caja_diaria_cubit.dart:73-77` hace `catch (_)` y siempre dice "No se pudo
  abrir la caja"; (b) índice único global `cajas_una_abierta_idx`
  (`linea_base.sql:2969`) + `_getCajaAbiertaActual` sin filtro de fecha
  (`caja_diaria_datasource_impl.dart:126-137`): una caja de un día anterior sin
  cerrar bloquea la de hoy; (c) el cierre compara `double != double`
  (`caja_diaria_datasource_impl.dart:63-68`) y aborta con "INCONSISTENCIA".
- **Solución:** propagar el error real (quitar los `catch (_)`), manejar la caja
  abierta de un día anterior (ofrecer cerrarla o cierre administrativo) y comparar
  balances con tolerancia/decimal fijo. Reproducir el escenario exacto en F5.

### D14 · Admin no puede iniciar su consulta

- **Por qué:** dos gates — estado `enEspera` y `doctor_id == auth.uid()` — con
  **tres pantallas incoherentes**: la lista exige ambos
  (`mis_citas_del_dia_page.dart:1519-1530`, `capacidades_sesion.dart:28-33`), la
  vista timeline solo mira estado (`timeline_view.dart:454-459`) y
  `siguiente_paciente_card.dart:145` no mira ninguno. Si la llegada no se registra
  (`programada → enEspera` no existe en el grafo, `estado_cita.dart:52-58`; solo
  el botón "Registrar llegada" la produce), "Iniciar consulta" es inalcanzable y
  la RPC devuelve `CL015`.
- **Solución:** unificar el gating en un único helper usado por las tres vistas;
  hacer visible/obvio "Registrar llegada" para la cita propia del admin; mensaje
  de la RPC (`CL015`, `42501`) mostrado tal cual en vez de botón mudo. (Si el
  negocio quisiera que el admin firme por otros doctores, sería cambio SQL —
  fuera de alcance salvo confirmación.)

**Resultado esperado de la fase:** cada rol ve y puede exactamente lo que la
matriz de QA define, impuesto por RLS y reflejado por la UI; los tests de shell y
de capacidades fijan la matriz.

---

## Fase 4 — Funcionalidad faltante y limpieza de navegación

| Ítem | Dónde | Solución | Resultado |
|---|---|---|---|
| D16 búsqueda por cédula | `persona_remote_datasource_impl.dart:30`: el `or()` solo incluye `nombre,apellido` | añadir `cedula.ilike`, normalizando guiones (`001-1391820-5` ≡ `00113918205`) y escapando el término | la promesa del hint "Nombre, apellido o cédula" se cumple |
| D15 filtro de doctor en agenda | `CitaCubit` sin filtro mutable (`cita_cubit.dart:22-35`); `_ControlBar` sin widget (`mis_citas_del_dia_page.dart:392-459`) | `doctorIdFiltro` separado del techo de seguridad + chips como en `consultas_list_page.dart:357-377`, visibles para admin | admin alterna "todos" / "solo míos" / por doctor |
| D17 rango de fechas en expediente | modal sin selector (`generar_expediente_modal.dart:144-174`); corpus decidido antes (`paciente_detail_page.dart:161-177`); bug extra: `_opcionSeleccionada` nunca se pasa a `ExpedientePage.navegar` (`:213-223`) — la opción con/sin odontograma del modal es decorativa | `showDateRangePicker` en el modal, propagar `DateTimeRange?` y `formatoInicial` hasta el builder del PDF | el PDF cubre el rango elegido y respeta la opción elegida |
| D18 botón Generar Expediente | `paciente_detail_page.dart:139-161`: con `historialNoDisponible` el botón se pinta igual y muere en SnackBar | incluir `historialNoDisponible` en la condición de render | no se ofrecen acciones imposibles |
| D19 Equipos duplicado | destino de primer nivel (`dashboard_shell.dart:214-226,292-298`) + pestaña en Inventario (`inventario_page.dart:33-76`) | eliminar el destino de primer nivel y **añadir `SuplidorCubit` a `InventarioPage`** (hoy solo provee `EquipoCubit`; sin él, "Registrar mantenimiento" revienta — es el bug SD-124) | una sola entrada de Equipos, dentro de Inventario, funcional |

---

## Fase 5 — Prueba E2E de punta a punta (la ejecuto yo, conduciendo la app)

**Contexto.** El repo ya tiene el arnés: `tool/e2e/jornada_ui.sh` conduce la app
real con `flutter drive` + chromedriver headless contra el stack local de
Supabase, con seed de certificación y evidencia en `docs/qa/e2e-ui/`. Se amplía
`integration_test/jornada_ui_test.dart` para cubrir la jornada completa de los
tres roles y cada defecto corregido.

**Guion (cada paso deja captura + log como evidencia):**

1. **Preparación:** `supabase db reset` (valida F0: la línea base contiene todo),
   seed de certificación + overlay de login, arranque headless.
2. **Jornada ADMIN:** login → Perfiles carga (D2) y un perfil corrupto sembrado
   muestra error inline sin tumbar la sección → Pacientes lista (D3) → crear
   paciente → agendar cita normal buscando **por cédula** (D16) → filtro de
   doctores en agenda (D15) → registrar llegada → iniciar consulta propia (D14) →
   ver que Equipos aparece una sola vez y "Registrar mantenimiento" funciona
   (D19) → catálogos con botones de edición visibles (control positivo D8).
3. **Jornada DOCTOR:** login → menú sin "Cuentas por Cobrar" ni Perfiles (D9) →
   catálogos sin Nuevo/Editar/Eliminar ni precios (D8) → agendar cita normal
   propia (D10) → registrar llegada → iniciar consulta → registrar diagnósticos y
   tratamientos por pieza **y generales** → cerrar consulta sin error falso (D7)
   → Detalle de Cuenta carga (D1) → detalle del paciente: timeline con
   tratamientos y diagnósticos (D5), odontograma con marcas (D6) → generar PDF
   con rango de fechas y verificar que el odontodiagrama trae marcas (D6a, D17;
   aserción sobre el contenido del PDF, no solo el título) → Consultas muestra
   nombres de pacientes (D4) y el alcance de consultas ajenas según la decisión
   D11.
4. **Jornada ASISTENTE:** login → agenda solo con doctores asignados (D12) → sin
   dropdown de cambio de estado (D12) → abrir caja, registrar cobro, cerrar caja
   (D13), incluyendo el escenario "caja de ayer quedó abierta" → Cuentas por
   Cobrar accesible (control positivo D9).
5. **Controles negativos por API:** con el token de cada rol, intentos directos
   de UPDATE a catálogos (doctor), cambio de estado de cita (asistente) y lectura
   de consulta ajena — todos deben morir en RLS, no solo en UI.
6. **Cierre:** suite completa (`flutter test`), `flutter analyze` limpio,
   `supabase db diff --linked` vacío, evidencia consolidada en
   `docs/qa/e2e-ui/` con un resumen de qué defecto validó cada paso.

**Resultado esperado.** Los 20 defectos del inventario tienen un paso E2E que los
valida en verde sobre la app real, con evidencia archivada; ninguna regresión en
la suite.

---

## Orden, ramas y riesgos

- **Orden:** F0 → F1 → F2 → F3 → F4 → F5. F1 puede empezar en paralelo a F0 (sus
  fixes de cliente no dependen del diff), pero no se valida contra producción
  hasta cerrar F0.
- **Ramas:** una por fase desde `dev` (`HFX-QA-100-esquema`, `HFX-QA-101-pantallas`,
  `HFX-QA-102-visibilidad-clinica`, `HFX-QA-103-permisos-roles`,
  `HFX-QA-104-funcionalidad`, `HFX-QA-105-e2e`), integradas por PR a `dev`.
- **Decisiones (estado al 1 ago):**
  1. **D11 — decidido:** el doctor ve todas las consultas, temporal; Isaac hará
     el modelo definitivo. Migración marcada como TEMPORAL.
  2. **D12 — decidido el principio** (cada rol cambia ciertos estados, admin
     todos); la matriz concreta propuesta está en D12 y se valida al arrancar F3.
  3. **Deriva de producción — decidido (1 ago):** el modelo de producción es el
     oficial. Se versionan tal cual sus policies + `doctor_paciente` + trigger;
     se retiran solo las vistas `*_seguro` huérfanas (verificación de
     dependencias previa al drop); se añade la vista de directorio de nombres
     para reconciliar el modelo restrictivo con D11. El cliente se adapta al
     modelo restrictivo.
- **Riesgos:** (a) aplicar migraciones en producción — siempre con el flujo manual
  y confirmación previa; (b) endurecer RLS puede romper flujos no cubiertos por QA
  — por eso los controles negativos de F5; (c) el seed de certificación no crea
  los usuarios de QA (`pruebaadmin`, etc.) — el overlay de login del arnés ya lo
  resuelve para local.
