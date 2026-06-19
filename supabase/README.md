\# 🗄️ Gestión de Base de Datos y Migraciones



Para evitar que la base de datos de producción diverja con el código del repositorio, a partir de ahora se implementa un flujo estricto de control de cambios. 



Cualquier miembro del equipo debe poder clonar este repositorio, leer la estructura y reconstruir una instancia idéntica desde cero.



\---



\## 📌 Estado Actual y Línea Base



\*   \*\*`supabase/schema.sql`\*\*: Contiene la "verdad absoluta" de la base de datos (tablas, tipos, funciones, triggers). Es la línea base o "Punto Cero" extraído directamente de la instancia real.

\*   \*\*`supabase/migrations/`\*\*: Carpeta que almacena los cambios incrementales ordenados cronológicamente a partir de la línea base.



\---



\## 🚀 La Regla de Oro (Políticas del Repositorio)



> 🛑 \*\*PROHIBIDO\*\* hacer cambios estructurales directamente desde el Dashboard o el SQL Editor de Supabase en producción sin su correspondiente archivo de migración en el repositorio.

>

> \*\*Ningún cambio de base de datos se aprueba si no viene con su archivo de migración en el mismo Pull Request (PR).\*\* Las ramas de `HOTFIX-1`, `HOTFIX-2`, `HOTFIX-4`, etc., deben nacer bajo esta convención.



\---



\## 📁 Convención de Migraciones



Cualquier cambio posterior a la línea base debe crearse dentro de `supabase/migrations/` usando la estructura `NNN\_descripcion\_corta.sql` (en estricto orden alfanumérico):



\*   `001\_crear\_consulta\_completa.sql`

\*   `002\_agregar\_notas\_consultas.sql`

\*   `003\_hotfix\_indices\_uuid.sql`



\*Nota: Procura escribir los scripts de migración de forma idempotente (ej. usar `ALTER TABLE ... ADD COLUMN IF NOT EXISTS ...`) para evitar fallos si se ejecutan en instancias que ya contaban parcialmente con el cambio.\*



\---



\## 🛠️ Cómo reconstruir la BD desde cero



Si necesitas levantar una instancia limpia o local, ejecuta los archivos en este estricto orden:



1\.  Ejecutar el contenido completo de `supabase/schema.sql` (creará la estructura base).

2\.  Ejecutar secuencialmente los scripts dentro de `supabase/migrations/` (`001`, `002`, `003`...).

