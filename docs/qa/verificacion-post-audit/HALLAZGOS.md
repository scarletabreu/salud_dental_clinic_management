# Verificación post-audit por la interfaz · 3-4 ago 2026

Recorrido real de la aplicación (navegador headless contra el stack local)
después de la corrección del audit del 2 ago 2026 (PR #137, merge `4b4efd5`).
Se conducen las tres jornadas —doctora, asistente y admin— pulsando los mismos
botones que pulsa la clínica.

Arneses: `integration_test/verif_{doctor,asistente,admin}_test.dart`.
Runner: `tool/e2e/verificacion_post_audit.sh`.
Preparación de datos: `supabase/tests/e2e_agenda_hoy_overlay.sql`.

---

## V-01 · **BLOQUEANTE** — El doctor no puede abrir la consulta de un paciente que nunca ha atendido

**Qué se ve.** La doctora entra en «Mis Citas del Día», registra la llegada del
paciente y pulsa «Iniciar consulta». La pantalla que abre se queda en un
indicador de carga permanente, **sin un solo texto, sin mensaje de error y sin
salida**. No hay forma de atender a ese paciente desde la interfaz.

**Por qué.** Cadena de tres piezas que se muerden la cola:

1. `pacientes_select` exige `puede_ver_paciente(id)`, que para un doctor que no
   es admin pide una fila **activa** en `doctor_paciente`
   (`supabase/migrations/20260810090000_hfx_clin_011_versionar_guardias_produccion.sql:23`).
2. Esa fila sólo la crea `fn_autoasignar_doctor_paciente`, un trigger
   `AFTER INSERT` de **`consultas`**. Antes de la primera consulta no existe.
3. `EfectuarConsultaPage` lee `pacientes` **antes** de crear la consulta:
   `_verificarRegistro()` → `PacienteCubit.isPaciente` →
   `esPersonaSinFichaClinica` (`paciente_remote_datasource.dart:254`), que hace
   `select id from pacientes where id = …`. La RLS devuelve vacío, el cliente
   concluye «esta persona no tiene ficha clínica», intenta crearla y el INSERT
   muere con `42501`. `_registroIncompleto` queda en `true` y
   `_pacienteParaForm` en `null`, que es justo la rama que pinta un
   `CircularProgressIndicator` y nada más
   (`efectuar_consulta_page.dart:112-135`).

Sin consulta no hay fila de acceso, y sin fila de acceso no hay consulta.

**Evidencia (token real de `cert_doctora`, stack local):**

```
GET  /rest/v1/personas?id=eq.<sara>   → [{"id":"…","nombre":"Sara"}]
GET  /rest/v1/pacientes?id=eq.<sara>  → []
POST /rest/v1/pacientes {"id":"<sara>",…}
     → {"code":"42501","message":"new row violates row-level security policy for table \"pacientes\""}
POST /rest/v1/rpc/iniciar_consulta_de_cita {"p_cita_id":"…"}
     → {"estado":"creada","cita_estado":"en_consulta","consulta_id":"…"}
```

La última línea es la clave: **la RPC sí funciona** (es `SECURITY DEFINER`), y
en cuanto se ejecuta el trigger crea la fila `doctor_paciente`. El bloqueo es
exclusivamente la comprobación previa del cliente.

**Alcance.** No lo introdujo la corrección del audit: la regla viene de
HFX-CLIN-011 (10 ago), que versionó una guardia que **ya estaba en producción**.
Afecta a todo doctor que no sea admin y a todo paciente que no haya atendido
antes — es decir, a cada paciente nuevo. El admin-doctor no lo sufre
(`es_admin()` tiene su propia rama) y por eso las jornadas anteriores, hechas
con `cert_admin`, nunca lo tocaron.

**Soluciones posibles** (por orden de menor riesgo):

1. Que `puede_ver_paciente` acepte también al doctor con una **cita** de ese
   paciente (`exists (select 1 from citas where persona_id = p_paciente_id and
   doctor_id = auth.uid() and estado not in ('cancelada'))`). Es la relación que
   ya autoriza `iniciar_consulta_de_cita`.
2. Que el cliente deje de decidir con una lectura que la RLS puede vaciar: usar
   una RPC `SECURITY DEFINER` para «¿esta persona tiene ficha clínica?».
3. Como mínimo, que la pantalla **muestre el fallo** en vez de dejar el
   indicador girando: hoy un `42501` en esta ruta es indistinguible de una red
   lenta.

Para poder ejercitar el resto de la jornada, el overlay del arnés siembra las
filas de `doctor_paciente` — con un comentario que dice explícitamente que tapa
este defecto y que debe retirarse cuando se corrija.

---

## V-02 · ~~Observación~~ **CORREGIDO** — «Cuentas por Cobrar» sigue sin ruta al cobro

La pantalla lista las cuentas y sus balances, pero ninguna tarjeta navega a
ningún sitio: `cuentas_por_cobrar_page.dart` no tiene un solo `Navigator.push`
hacia `PreFacturaPage`. Los dos únicos accesos al cobro son el resumen
financiero de la ficha del paciente (`paciente_detail_page.dart:259`) y el
cierre de la consulta (`efectuar_consulta_page.dart:305`).

Quien cobra entra por «Cuentas por Cobrar» —es el módulo que lleva ese nombre—
y desde ahí no puede cobrar. No es un defecto de datos ni de permisos; es una
ruta que falta.

**Corregido el 4 ago 2026**, después de escrito este informe:

- `7b54c47` — la tarjeta abre el detalle de la cuenta (`_abrirCuenta` →
  `PreFacturaPage`) y recarga la lista al volver; además la fila se titula con
  el nombre del paciente en vez de «Consulta #c16563b9», que era la otra mitad
  del problema: se veía el balance sin saber a quién llamar.
- `cadfdf3` — el resumen económico de la consulta ofrece «Ver detalle de la
  cuenta», el segundo camino que faltaba.
- `12e14a6` y `cbc975a` — el cobro se oculta a quien la base no deja cobrar, y
  recepción —que sí cobra— puede emitir el recibo aunque la RLS de `consultas`
  le niegue la consulta.

---

## Estado al cierre de la verificación

| Hallazgo | Estado |
|---|---|
| V-01 · doctor no admin no puede abrir la consulta de un paciente nuevo | **abierto** — sin migración que relaje `puede_ver_paciente`; el overlay del arnés sigue tapándolo |
| V-02 · «Cuentas por Cobrar» sin ruta al cobro | **corregido** (`7b54c47`, `cadfdf3`) |

Precisión sobre `runner.log`: los `✗` que quedaron registrados **no** son V-01
—el overlay lo tapa con las filas de `doctor_paciente`, así que la jornada de la
doctora lo atraviesa—. Fueron dos artefactos del propio arnés, ya corregidos:

- `pumpAndSettle` agotaba su plazo (el workspace siempre tiene una animación o
  una petición en vuelo). Aunque se capturase el `throw`, la binding ya había
  anotado la excepción y la corrida moría en «Multiple exceptions (3) were
  detected», que se lee como defecto de la aplicación y es del arnés.
- La jornada del admin entera superaba los **20 minutos** que
  `integration_test` le da al driver para devolver el resultado: terminaba todo
  su trabajo —el cobro y la compra quedaban escritos en la base— y la corrida
  moría igual, en un `DriverError: request_data`. Por eso va partida en
  `verif_admin_test.dart` (expediente, PDF y cobro) y
  `verif_admin_compras_test.dart` (arqueo y compras).

---

## Lo que quedó comprobado por la interfaz

Cada línea se verificó pulsando los botones y se confirmó después en la base
(`tool/e2e/verificacion_post_audit.sql`).

**Consulta (frente 1 del audit)** — llegada → evaluación → odontograma →
diagnóstico → tratamiento → receta → cierre, tres veces y con dos consultas
abiertas a la vez:

- Las tres consultas cierran (`finalizada = true`) y su fecha es la del día en
  la zona de la clínica, no `now()` a ciegas.
- Los signos vitales dejan **8 filas estructuradas** por consulta en
  `signos_vitales_consulta`, no sólo el `jsonb` (F1-06).
- El tratamiento se guarda con su precio congelado (RD$3,200.00) y el
  diagnóstico de la pieza 16 sobrevive al cierre y al historial.
- Reanudar la consulta de Hugo desde «Consultas» no filtra nada de Sara ni de
  Ana: cada expediente conserva sólo sus piezas.
- La amoxicilina en la paciente alérgica a la penicilina queda **bloqueada** por
  contraindicación absoluta; la clindamicina pasa.

**Facturación y caja (frente 2)**

- La pre-factura cobra el tratamiento aplicado: `cuenta.total = 3,200.00`, no
  cero (F2-02).
- El método de pago elegido se persiste tal cual: `pago … via tarjeta_debito`
  (F2-03).
- El cobro entra en el arqueo del día: `movimientos_caja · ingreso 3,200.00 ·
  Cobro a cuenta` (S10/F2-04).
- Con la caja del día anterior **sin cerrar**, la pantalla lo avisa y deja abrir
  la de hoy igualmente (F2-01).

**Inventario y compras (audit_001)**

- Registrar una compra y recibirla funciona de punta a punta: la compra queda
  `recibida`, el stock sube por el libro de movimientos
  (`movimiento_stock.compra_recibida 0 → 10`) y el egreso entra en caja
  (`egreso 1,900.00 · Pago por recepción de compra #…`). Antes de la corrección
  esto respondía `23514` en cada clic, también en producción (I1).

**Agenda y roles (frente 3 + matriz de permisos)**

- Una cita cancelada no ofrece «Registrar llegada».
- El grafo de estados de la base rechaza `en_espera → confirmada`.
- La asistente ve la agenda de los doctores que asiste, registra llegadas, da de
  alta pacientes y agenda citas; **no** tiene «Consultas», «Inventario» ni
  «Perfiles`, y ninguna cita le ofrece «Iniciar consulta».
- El diálogo de nueva cita rechaza una fecha/hora ya pasada.

**Expediente impreso**

- El PDF del expediente con odontograma se genera y se pinta en la
  previsualización.

## Observaciones menores

- `items_receta` (la tabla) sigue vacía: los renglones viven en el `jsonb`
  `recetas.items_receta`. Es F4-04 del audit, aceptada («no hay pérdida para la
  app»), pero cualquier reporte que lea la tabla concluirá que no hay
  medicamentos recetados.
- El inicio de sesión falló dos veces de ~15 con el mismo usuario y contraseña
  correctos (el dashboard no llegó en 45 s; por REST el token se emitía sin
  problema en el mismo momento). No pude caracterizarlo; queda anotado.
