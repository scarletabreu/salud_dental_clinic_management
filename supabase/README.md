# 🗄️ Gestión de Base de Datos y Migraciones

Para evitar que la base de datos de producción diverja del código del repositorio,
el proyecto sigue un flujo estricto de control de cambios.

Cualquier miembro del equipo debe poder clonar este repositorio, leer la estructura
y reconstruir una instancia idéntica desde cero.

---

## 📌 Estado actual y línea base

* **`supabase/migrations/`**: el canal válido para cambios de esquema, y desde
  HFX-CLIN-000 (31 jul 2026) también el bootstrap. `supabase db reset` reconstruye
  el proyecto entero sin intervención manual:

  * `20260725000000_linea_base.sql` — esquema `public` completo, resultado de
    aplicar en orden las 25 migraciones anteriores sobre la instancia validada;
  * `20260725000100_linea_base_objetos_no_public.sql` — lo que un dump de esquema
    no trae y sólo vivía en la instancia: los buckets de Storage
    (`documentos-clinicos`, `fotos-pacientes`), sus políticas y la publicación de
    realtime de `movimientos_caja`;
  * las migraciones `2026073109…` del propio HFX-CLIN-000.

* **`supabase/migrations_historicas/`**: las 25 migraciones anteriores al squash.
  **No se borraron ni se aplican**: quedan como registro de cómo se llegó a la
  línea base. Antes de este cambio no reconstruían nada —la primera asumía tablas
  que ninguna creaba y otras cuatro abortaban con `already exists`—, que es
  justamente por lo que se squashearon.

* **`supabase/schema.sql`**: dump de referencia regenerado desde la base migrada.
  Sirve para leer la estructura y para diffs; **ya no es el camino de bootstrap**.
  Si queda desfasado se regenera con `supabase db dump --linked -f supabase/schema.sql`.

* **`supabase/*.sql` (raíz)**: scripts históricos (`sd-81`, `sd-84`, `sd-96`, …) que se
  ejecutaron a mano antes de adoptar el CLI. Se conservan como registro. **No crear
  nuevos ni reejecutarlos**: varios ya quedaron desfasados respecto a la instancia.

> ⚠️ **Sincronía con la instancia remota.** El squash dejó el historial local sin
> correspondencia con `supabase_migrations.schema_migrations` de la instancia.
> Antes del próximo `db push` hay que hacer un `supabase migration repair`
> marcando la línea base como aplicada. **No se ha tocado nada remoto**, y no debe
> tocarse sin decisión explícita.

---

## 🚀 La regla de oro

> 🛑 **PROHIBIDO** hacer cambios estructurales desde el Dashboard o el SQL Editor sin su
> archivo de migración correspondiente en el repositorio.
>
> **Ningún cambio de base de datos se aprueba si no viene con su archivo de migración en
> el mismo Pull Request.**

El riesgo no es teórico. Postgres **no reemplaza** una función cuando cambia el tipo de
un parámetro: crea una sobrecarga nueva. Editar una RPC en el SQL Editor con una firma
distinta a la versionada deja dos candidatas y PostgREST responde
`Could not choose the best candidate function` en cada llamada de la app.
Lo mismo aplica a triggers duplicados sobre la misma tabla.

---

## 📁 Convención de migraciones

El nombre debe seguir el patrón del CLI: `<timestamp>_descripcion_corta.sql`
(`YYYYMMDDHHmmss`). Los archivos que no lo cumplan son ignorados por
`supabase migration list` / `db push`.

```bash
supabase migration new descripcion_corta   # crea el archivo con timestamp
```

Escribe los scripts de forma idempotente (`add column if not exists`,
`drop trigger if exists`, `create or replace function`) para que puedan aplicarse sobre
instancias que ya tengan el cambio parcialmente.

Al **reemplazar** una función existente cambiando la firma, incluye siempre el
`drop function if exists <nombre>(<tipos_viejos>);` antes del `create or replace`.

---

## ✅ Verificar que la instancia y el repositorio coinciden

```bash
supabase migration list --linked     # las columnas local/remote deben coincidir
```

Auditoría rápida de los duplicados que rompen PostgREST:

```sql
-- Funciones con más de una sobrecarga en public
select p.proname, count(*), string_agg(pg_get_function_identity_arguments(p.oid), ' | ')
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public'
 group by p.proname having count(*) > 1;

-- Triggers por tabla (busca dos triggers que hagan lo mismo)
select c.relname, t.tgname, p.proname
  from pg_trigger t
  join pg_class c on c.oid = t.tgrelid
  join pg_proc  p on p.oid = t.tgfoid
  join pg_namespace n on n.oid = c.relnamespace
 where n.nspname = 'public' and not t.tgisinternal
 order by c.relname;
```

---

## 🛠️ Cómo reconstruir la BD desde cero

Verificado de punta a punta el 31 jul 2026 (HFX-CLIN-000) contra el stack local:

```bash
supabase start     # levanta el stack local
supabase db reset  # migraciones + seed, sin parches manuales
```

Eso deja la base completa —esquema, buckets de Storage, realtime, el trigger
`on_auth_user_created` y el seed de caja— y es lo que corre en la validación del
ticket. No hay que cargar `schema.sql` a mano ni reaplicar nada.

---

## 🌱 Seeds

`supabase/seed.sql` deja **un día de caja completo**: la caja de ayer cerrada con un
faltante de RD$ 120.00 y la caja de hoy abierta con ingresos y egresos mezclados
(esperado RD$ 27 349.75). Sirve para abrir la pantalla de caja y ver el cierre real
sin cobrar a mano.

Es idempotente: si ya existe una caja con la fecha de hoy, no inserta nada. Y ese
27 349.75 está duplicado a propósito en
`test/features/caja_diaria/cerrar_caja_test.dart`: si el seed y las pruebas dejan de
coincidir, es que el cálculo contable se movió en un solo lado.

---

## 🧪 Pruebas de base de datos

Los triggers y las RPC no los cubre la suite de Flutter. `supabase/tests/` guarda
scripts SQL **auto-verificantes**: corren dentro de una transacción que se revierte,
así que no dejan datos, y abortan con `ERROR` si el contrato se rompe.

| Script | Qué verifica |
|---|---|
| `tests/sd_111_trigger_caja_test.sql` | `pagos_registrar_ingreso_caja`: un pago `completado` genera **un** ingreso en la caja abierta de hoy; un pago pendiente no la toca; sin caja abierta el pago se rechaza (P0001) y no se persiste; la caja de ayer no habilita el cobro de hoy; no revivió el trigger duplicado `tr_pago_a_movimiento_caja`. |
| `tests/sd_169_paciente_inactivo_test.sql` | `cancelar_citas_paciente_inactivo` (SD-169): pasar un paciente a inactivo **no falla** (antes moría con `42703`) y cancela sus citas futuras vivas (`programada`, `confirmada`, `en_espera`); deja intactas las `en_consulta`, las pasadas, las terminales y las de otros pacientes; la cita con **consulta abierta** ni se cancela ni aborta la baja (regla de SD-160); reactivar o reenviar el mismo `estatus` no vuelve a barrer la agenda. |
| `tests/sd_135_plan_tratamiento_test.sql` | Separación evaluación / plan / ejecución (SD-135/SD-138): registrar hallazgos **no** crea tratamiento aplicado ni cuenta; una actividad todavía `propuesto` no se puede ejecutar; una ejecución aceptada completa su actividad planificada; el flujo unificado admite una intervención agregada durante la consulta sin justificación obligatoria y conserva su auditoría; `finalizar_consulta` cobra solo lo ejecutado e ignora lo planificado, y es idempotente. |
| `tests/hfx_clin_000_identidad_admin_doctor_test.sql` | Identidad admin-doctor (HFX-CLIN-000): el alta de **admin** crea `usuarios` + `doctores` + `admins` con el UUID de Auth (antes `personas.id` era aleatorio y toda la RLS `id = auth.uid()` fallaba); la de **doctor** no crea fila de admin y la de **asistente** no otorga identidad clínica; un alta con campos obligatorios inválidos se revierte entera; la FK `admins.id → doctores.id` está activa; `perfil_actual()` devuelve el contrato de cada rol y nunca una contraseña; el admin aparece en `get_active_doctors()` y puede firmar su propia consulta; `anon` no ejecuta ninguna de las dos funciones. |
| `tests/sd_146_cita_actividades_test.sql` | Vínculo cita ↔ actividades planificadas (SD-146): una cita puede cubrir varias actividades del plan de **su** paciente; `trg_validar_cita_item_plan` rechaza la actividad de otro paciente, la retirada del plan (`deleted_at`) y la ya rechazada/cancelada/completada; `resumen_actividades_cita` devuelve nombre del tratamiento y pieza FDI; `actividades_agendables_paciente` excluye lo rechazado y lo retirado; el **asistente** —que es quien agenda y no puede leer `items_plan_tratamiento`— sí lee las vistas y gestiona los vínculos; borrar la cita se lleva los suyos. |
| `tests/hfx_clin_001_seguridad_rpc_rls_test.sql` | Matriz ofensiva de RPC y RLS (HFX-CLIN-001): `anon` sin grants ni identidad, funciones base fuera del alcance de `authenticated`, asistente sin escritura clínica, doctor sin acceso a lo ajeno y corrección administrativa auditada. |
| `tests/hfx_clin_002_cierre_transaccional_test.sql` | Persistencia y cierre transaccional (HFX-CLIN-002): una cita no admite dos consultas vigentes; el borrador guarda, identifica y versiona en una operación; una versión obsoleta no escribe nada; un guardado fallido no borra la receta persistida; stock insuficiente revierte el cierre entero; el cierre confirma consulta, cita, stock, cuenta y receta a la vez; reintentarlo es idempotente; una consulta cerrada no se edita y su receta emitida solo se anula; una evaluación sin ejecución cierra sin cobrar; el doctor ajeno no guarda ni cierra; `anon` no alcanza ninguna de las dos RPC. |

```bash
# Contra la base local levantada por el CLI: todas las suites de una pasada
supabase db reset
PGURL="postgresql://postgres:postgres@127.0.0.1:54322/postgres"
for t in supabase/tests/*.sql; do psql "$PGURL" -v ON_ERROR_STOP=1 -f "$t"; done

# Contra una instancia remota (usar SIEMPRE una de staging, nunca producción)
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/sd_111_trigger_caja_test.sql
```

Salida esperada: las líneas `NOTICE  OK ...` de cada script y un `ROLLBACK` final.
Cualquier `ERROR` es un fallo real del contrato, no del script.

El script **no asume el estado de la base**: si encuentra una caja abierta la cierra
dentro de su propia transacción (el `ROLLBACK` la devuelve intacta), porque si no el
caso 3 —"sin caja abierta el pago se rechaza"— no probaría nada. Por eso se puede
correr con el seed ya cargado, o contra una instancia con la jornada en curso.

### Smoke de sesión por rol

`tests/hfx_clin_000_smoke_login_agenda.sh` recorre contra el stack **local** el
mismo camino que el navegador: alta por Auth (que dispara `handle_new_user`),
login con contraseña de los tres roles, `perfil_actual()`, `get_active_doctors()`
y la lectura de `citas`. Comprueba además que el admin sale agendable, que
ninguna respuesta trae `password_hash` y que `anon` no ejecuta nada. Crea sus
usuarios con un sufijo aleatorio y los borra al terminar; no toca ninguna
instancia remota.

```bash
supabase db reset
./supabase/tests/hfx_clin_000_smoke_login_agenda.sh
```

> ✅ **Bootstrap desde cero.** Desde HFX-CLIN-000 el `supabase db reset` de arriba
> deja la base lista para correr todas las suites: verificado el 30 jul 2026 sobre
> una base recién reconstruida.

### Cierre clínico: concurrencia y contrato REST

Dos comprobaciones de HFX-CLIN-002 no caben en una prueba SQL, porque una
transacción no puede observarse a sí misma desde fuera:

```bash
supabase db reset
./supabase/tests/hfx_clin_002_concurrencia.sh   # dos conexiones cerrando a la vez
./supabase/tests/hfx_clin_002_contrato_rest.sh  # el payload de la app por PostgREST
```

La primera abre dos sesiones reales: la segunda espera el bloqueo y se encuentra
el cierre ya hecho, de modo que solo hay una cuenta, un movimiento de stock y una
cita completada. La segunda manda por REST el mismo payload que manda Flutter y
comprueba contra la base que el hallazgo conservó su cara —el defecto
`superficiecle` no lo detectaba ningún doble— y que reintentar el cierre no
vuelve a descontar ni a facturar.

### Verificación manual equivalente

Si no hay `psql` a mano, el mismo contrato se comprueba desde la app en cinco pasos:

1. **Sin caja abierta**, cobrar una cuenta desde la pre-factura → debe fallar con
   *"No hay una caja abierta para hoy"* y la cuenta debe quedar sin pago.
2. Abrir la caja con RD$ 5000 → la pantalla muestra esperado RD$ 5000.
3. Cobrar RD$ 1500 → aparece **un solo** movimiento *"Cobro a cuenta"* de RD$ 1500 y el
   esperado sube a RD$ 6500. Si aparecen dos movimientos, hay un trigger duplicado.
4. Registrar un egreso de RD$ 500 → esperado RD$ 6000.
5. Cerrar contando RD$ 5900 → el reporte debe decir **faltante de RD$ 100.00**.
