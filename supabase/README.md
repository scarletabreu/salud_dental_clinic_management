# 🗄️ Gestión de Base de Datos y Migraciones

Para evitar que la base de datos de producción diverja del código del repositorio,
el proyecto sigue un flujo estricto de control de cambios.

Cualquier miembro del equipo debe poder clonar este repositorio, leer la estructura
y reconstruir una instancia idéntica desde cero.

---

## 📌 Estado actual y línea base

* **`supabase/schema.sql`**: línea base ("Punto Cero") extraída de la instancia real.
  Está desactualizada respecto a la instancia; sirve como punto de partida, no como
  verdad absoluta.
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

1. Ejecutar `supabase/schema.sql` (estructura base).
2. Aplicar las migraciones en orden: `supabase db push --linked`.
