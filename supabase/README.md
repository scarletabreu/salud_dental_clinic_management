# 🗄️ Gestión de Base de Datos y Migraciones

Para evitar que la base de datos de producción diverja del código del repositorio,
el proyecto sigue un flujo estricto de control de cambios.

Cualquier miembro del equipo debe poder clonar este repositorio, leer la estructura
y reconstruir una instancia idéntica desde cero.

---

## 📌 Estado actual y línea base

* **`supabase/schema.sql`**: línea base extraída de la instancia real con
  `supabase db dump --linked`. **Refrescada el 25 jul 2026 (SD-135)**: 45 tablas,
  27 tipos, 172 políticas RLS y las funciones/triggers vigentes. Sólo estructura,
  sin datos.
  Está al día con todas las migraciones listadas abajo, así que por sí sola
  reconstruye la base completa.

  > Antes de ese refresco el archivo no definía **ninguna tabla** (sólo extensiones)
  > y era imposible levantar el proyecto desde cero: la primera migración moría con
  > `relation "public.cuotas" does not exist`. Si vuelve a quedar desfasado, se
  > regenera con `supabase db dump --linked -f supabase/schema.sql`.
* **`supabase/migrations/`**: cambios incrementales ordenados cronológicamente a partir
  de la línea base. **Es el único canal válido para cambios de esquema.**
* **`supabase/*.sql` (raíz)**: scripts históricos (`sd-81`, `sd-84`, `sd-96`, …) que se
  ejecutaron a mano antes de adoptar el CLI. Se conservan como registro. **No crear
  nuevos ni reejecutarlos**: varios ya quedaron desfasados respecto a la instancia.

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

Verificado de punta a punta el 25 jul 2026 contra una instancia local limpia:

```bash
supabase start                      # levanta el stack local
export PGURL="postgresql://postgres:postgres@127.0.0.1:54322/postgres"

psql "$PGURL" -q -c "drop schema public cascade; create schema public;
  grant all on schema public to postgres, anon, authenticated, service_role;"

psql "$PGURL" -v ON_ERROR_STOP=1 -f supabase/schema.sql   # 1. estructura completa
psql "$PGURL" -v ON_ERROR_STOP=1 -f supabase/seed.sql     # 2. día de caja de ejemplo
```

`schema.sql` ya incluye todas las migraciones aplicadas hasta su fecha de dump, así
que **no hay que reaplicarlas**. Sólo se aplican las migraciones *posteriores* al
dump, con `supabase db push --linked`.

> ⚠️ **`supabase db reset` no sirve para bootstrapear** este proyecto: aplica las
> migraciones sobre una base vacía y la primera (`sd_103_plan_cuotas`) asume tablas
> que ninguna migración crea. Usa el procedimiento de arriba.
>
> Si aun así reaplicas migraciones sobre `schema.sql`, cuatro fallarán con
> `already exists`: `sd_112_caja_diaria` (el `alter publication ... add table` no es
> idempotente) y las tres de políticas RLS (`create policy` sin `drop policy if
> exists` previo). Es ruido esperado, no un fallo de la base.

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
| `tests/sd_135_plan_tratamiento_test.sql` | Separación evaluación / plan / ejecución (SD-135/SD-138): registrar hallazgos **no** crea tratamiento aplicado ni cuenta; una actividad todavía `propuesto` no se puede ejecutar; una ejecución aceptada completa su actividad planificada; el flujo unificado admite una intervención agregada durante la consulta sin justificación obligatoria y conserva su auditoría; `finalizar_consulta` cobra solo lo ejecutado e ignora lo planificado, y es idempotente. |

```bash
# Contra la base local levantada por el CLI
supabase db reset
psql "$(supabase status -o env | grep DB_URL | cut -d= -f2- | tr -d '"')" \
  -v ON_ERROR_STOP=1 -f supabase/tests/sd_111_trigger_caja_test.sql

# Contra una instancia remota (usar SIEMPRE una de staging, nunca producción)
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/sd_111_trigger_caja_test.sql
```

Salida esperada: seis líneas `NOTICE  OK ...` y un `ROLLBACK` final. Cualquier
`ERROR` es un fallo real del trigger, no del script.

El script **no asume el estado de la base**: si encuentra una caja abierta la cierra
dentro de su propia transacción (el `ROLLBACK` la devuelve intacta), porque si no el
caso 3 —"sin caja abierta el pago se rechaza"— no probaría nada. Por eso se puede
correr con el seed ya cargado, o contra una instancia con la jornada en curso.

> ⚠️ **Ojo con el bootstrap desde cero.** `supabase db reset` sigue sin servir: aplica
> las migraciones sobre una base vacía y la primera (`20260720190000_sd_103_plan_cuotas.sql`)
> muere con `relation "public.cuotas" does not exist`. Usa el procedimiento de
> «Cómo reconstruir la BD desde cero» (cargar `schema.sql` y luego `seed.sql`), que sí
> deja la base completa: verificado el 25 jul 2026 cargando la línea base en una base
> limpia y corriendo `tests/sd_135_plan_tratamiento_test.sql` sobre ella.

### Verificación manual equivalente

Si no hay `psql` a mano, el mismo contrato se comprueba desde la app en cinco pasos:

1. **Sin caja abierta**, cobrar una cuenta desde la pre-factura → debe fallar con
   *"No hay una caja abierta para hoy"* y la cuenta debe quedar sin pago.
2. Abrir la caja con RD$ 5000 → la pantalla muestra esperado RD$ 5000.
3. Cobrar RD$ 1500 → aparece **un solo** movimiento *"Cobro a cuenta"* de RD$ 1500 y el
   esperado sube a RD$ 6500. Si aparecen dos movimientos, hay un trigger duplicado.
4. Registrar un egreso de RD$ 500 → esperado RD$ 6000.
5. Cerrar contando RD$ 5900 → el reporte debe decir **faltante de RD$ 100.00**.
