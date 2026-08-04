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

El `✗ Jornadas fallidas: doctora admin` del final de `runner.log` es el registro
de V-01, no un fallo del arnés.
