# HFX-CLIN-007 · Cerrar las escrituras directas y el alta de pacientes

Fecha: 2026-07-31.
Rama: `hotfix`, sobre `d1111ed` (el programa HFX-CLIN-000..006 ya integrado).

Este ticket nace de una auditoría independiente del diff `dev..hotfix` pedida
antes de integrar, y de un E2E de navegador que no existía. Los dos encontraron
cosas que los catorce gates de HFX-CLIN-006 no podían ver.

---

## Por qué la certificación estaba verde y aun así faltaban defectos

Las jornadas de certificación ejercen la frontera REST con el JWT real de cada
rol, que es donde vivían los defectos graves de seguridad. Pero **escriben el
payload a mano**: `hfx_clin_006_jornada_asistente.sh` manda
`"tipo_sangre":"a_positivo"`, ya en la grafía que la base espera. Nunca ejecutan
el código Dart que construye esa petición, así que ningún defecto del cliente
podía aparecer.

La consecuencia general, que conviene recordar más allá de este ticket: **una
prueba sólo demuestra lo que realmente ejecuta**. Una suite que construye la
entrada a mano prueba el servidor, no el cliente.

---

## Defectos corregidos

### 1 · Las RPC eran opcionales: `grant all` de tabla seguía en pie

HFX-CLIN-001 y 002 endurecieron el `execute` de las funciones y reescribieron
las políticas RLS, pero no revocaron los `grant all ... to authenticated` que
arrastraba la línea base. PostgREST expone esas tablas directamente, así que
cada invariante que las RPC defienden era, desde el cliente, evitable.

Verificado contra la base viva antes de tocar nada: `authenticated` conservaba
`INSERT/UPDATE/DELETE` sobre `consultas`, `consumibles` y
`movimientos_stock_consumible`.

- **Inventario.** `authenticated_adjust_stock_consumible` era
  `for insert with check (true)`: cualquier usuario autenticado —incluida una
  asistente, que no tiene capacidad de inventario— podía mover el stock. Peor:
  HFX-CLIN-002 añadió `consulta_id` con índice único y `cerrar_consulta` inserta
  el consumo con `on conflict do nothing`, así que insertando antes una fila con
  ese `consulta_id` y `diferencia = 0` el cierre **saltaba el descuento en
  silencio** — paciente facturado, inventario intacto, asiento de aspecto
  legítimo.
- **Cierre de consulta.** `consulta_update` sólo comprueba
  `doctor_id = auth.uid()`, y un `with check` no distingue qué columna cambió.
  Un doctor podía `PATCH {"finalizada": true}` sobre su consulta: sin cuenta, sin
  descuento, sin barreras clínicas y sin asiento de auditoría. Y al no escribirse
  `cierre_key`, un `cerrar_consulta` posterior devolvía éxito sobre una consulta
  que nunca se facturó.

**Corrección:** privilegios por columna, no un trigger de guarda.
`es_contexto_interno()` es **falso** dentro de una RPC llamada por PostgREST
—`session_user` sigue siendo `authenticator`, como advierte el propio comentario
de HFX-CLIN-001—, de modo que un trigger con esa condición habría bloqueado el
cierre legítimo. Las RPC son `security definer` y pertenecen a `postgres`, así
que los privilegios de `authenticated` no las afectan.

### 2 · El estado del consumible se quedaba congelado

`cerrar_consulta` movía `stock_actual` sin recalcular `estado`: un consumible
consumido hasta cero seguía marcado «disponible» y los avisos de stock bajo
quedaban ciegos. El único sitio que lo recalculaba era el ajuste manual del
administrador.

Se bajó el recálculo a `fn_aplicar_movimiento_stock`, el trigger que aplica cada
movimiento, de modo que toda vía queda cubierta por construcción —incluida
`recibir_compra`, que tenía el mismo hueco—. La migración repara además las
filas ya desalineadas.

### 3 · El botón «Nuevo Paciente» no podía crear un paciente

`PacienteFormPage._save()` llamaba **siempre** a `updatePaciente`. Sin `id`, el
datasource lanza «No se puede actualizar un paciente sin ID»; el aviso salía
como `SnackBar`, se desvanecía a los pocos segundos y la ficha se quedaba
abierta como si no hubiera pasado nada. El formulario ni siquiera tenía modo de
alta: su título sólo contemplaba «Completar ficha clínica» y «Editar paciente».

El único camino que llegaba a `registrar_paciente` era
`nueva_cita_dialog.dart`, al crear un paciente mientras se agenda una cita.

**Corrección:** `_save()` distingue alta de edición; el alta va por
`addPaciente` → `registrar_paciente`, y el título muestra «Nuevo paciente».

### 4 · `tipo_sangre` se persistía con la grafía de Dart

`TipoSangre` no tenía valor de base: se enviaba `name` (camelCase) contra un
enum de Postgres en snake_case.

Conviene ser exacto sobre su alcance, porque a primera vista parece peor de lo
que era:

- En **escritura** era un defecto **latente**. El único llamador vivo
  (`nueva_cita_dialog`) usa `RecordModel.empty()`, cuyo tipo es `desconocido`
  —la única etiqueta que se escribe igual en ambas grafías—, así que ese flujo
  funcionaba.
- En **lectura** era un defecto **activo**: `RecordModel.fromJson` comparaba
  contra `name`, de modo que todo expediente guardado como `o_positivo` se
  degradaba en silencio a `desconocido` al mostrarlo.
- Al corregir el defecto 3, el latente pasó a activo: el borrador de alta trae
  `TipoSangre.oPositivo` fijado (`pacientes_page.dart`) y ahora sí alcanza la
  RPC, que lo habría rechazado con `22P02` tumbando la transacción entera.

Se añadió `dbValue` (snake_case) y `desdeDb()`, que acepta también la grafía
vieja para no degradar fichas ya guardadas. De paso, `bloodType` mostraba
«OPOSITIVO» en el panel del paciente y en el PDF del expediente; ahora muestra
«O+».

### 5 · El gate de `flutter analyze` daba un falso verde

`analyze_limpio` contaba con `grep -cE '^\s+(error|warning) •'`, pero
`flutter analyze` **sangra las líneas de `info` y no las de `warning`**. El gate
contaba cero mientras el análisis reportaba nueve, y el informe de HFX-CLIN-006
documentaba «139 info» cuando eran 130 info y 9 warnings.

Se ancló la expresión con sangría opcional y se corrigieron los nueve warnings
—imports muertos, casts innecesarios, un método sin referenciar y una precarga
de logo que nunca llegaba al PDF—. Ahora son 0 errores, 0 warnings y 129 info.

---

## Cobertura nueva

- `supabase/tests/hfx_clin_007_escrituras_directas_test.sql` · 4 comprobaciones:
  las columnas de cierre no son escribibles y las clínicas sí; el libro de
  inventario sólo lo escriben las RPC; el estado del consumible sigue a su stock
  en las dos direcciones; y las nueve etiquetas de `TipoSangre.dbValue` son
  válidas —con la comprobación inversa de que el camelCase sigue siendo
  rechazado, para que la prueba no deje de demostrar nada si alguien relaja el
  enum—.
- `test/features/record/tipo_sangre_persistencia_test.dart` · 8 pruebas que
  fijan el contrato entre los dos enums por ambos lados.
- **E2E de navegador** (`tool/e2e/jornada_ui.sh`,
  `integration_test/jornada_ui_test.dart`): arranca `main()` de verdad contra el
  stack local, inicia sesión, recorre destinos y **da de alta un paciente por el
  formulario**. El runner comprueba después en SQL que la ficha existe y que su
  expediente nació con `o_positivo`.

Esa última comprobación no es adorno: en una iteración el E2E dio «All tests
passed» sin haber escrito ningún paciente. Un E2E que no verifica el efecto real
puede pasar sobre un flujo que no hace nada.

---

## Cómo se ejecuta

```bash
supabase/tests/hfx_clin_006_certificacion.sh   # 14 gates, ~12 min
tool/e2e/jornada_ui.sh                         # E2E de navegador, headless
```

El E2E corre headless con chromium y chromedriver: no abre ventana ni roba el
foco. Requiere el overlay `supabase/tests/e2e_ui_login_overlay.sql`, que reescribe
el correo de los actores a `<usuario>@saluddental.com` porque la pantalla de
login no pide correo sino usuario y compone el dominio de forma fija. Es seguro
aplicarlo después del alta: `handle_new_user` no copia el correo a ninguna tabla
de `public`.

---

## Limitaciones y lo que queda fuera

1. **El E2E conduce un solo rol**, `cert_admin`. Se eligió porque dar de alta un
   paciente es capacidad de admin o asistente (SD-149: el doctor trabaja el
   expediente clínico, no la ficha administrativa) y porque el admin es doctor en
   todas las capas desde HFX-CLIN-000. La separación de roles sigue
   demostrándose por REST, que es donde está completa.
2. **`consumibles` conserva `insert` y `delete` para `authenticated`.** Se acotó
   el `update` por columna para blindar `stock_actual` y `estado`; endurecer el
   alta y la baja de consumibles a sólo admin es una decisión de producto que no
   se tomó aquí.
3. **La ficha de alta llega con la fecha de nacimiento puesta en hoy**, porque el
   borrador nace con `DateTime.now()`. La validación «Debe seleccionar la fecha
   de nacimiento» no puede dispararse nunca y es fácil guardar a alguien nacido
   hoy sin notarlo. No se tocó: es un cambio de comportamiento del formulario.
4. **Nada de esto se ha aplicado a ninguna instancia remota.** Antes de un
   `db push` sigue pendiente el `supabase migration repair` que dejó el squash de
   HFX-CLIN-000.
