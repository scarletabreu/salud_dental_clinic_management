# Plan de migración de producción

Fecha del ensayo: 2026-07-31.
Instancia: `xcuvywvltttephakzmwu` («Salud Dental»).

Producción no tiene el núcleo clínico. De las 21 RPC que invoca la aplicación,
**13 no existen allí** —incluida `perfil_actual`, que se llama justo después de
iniciar sesión—, así que el código de `dev` no puede funcionar contra esa base.
La divergencia empezó en `ae847ff`, el primer commit de HFX-CLIN-000.

Este documento recoge lo que hace falta para cerrarla, y lo que se comprobó
antes de proponerlo.

---

## Por qué no basta `db push`

Producción no es «el repo menos las migraciones HFX». Ha derivado por su cuenta:
hay objetos hechos a mano desde el Studio que el repositorio nunca vio. Las
migraciones HFX están escritas contra la línea base del repositorio, de modo que
aplicarlas a ciegas revienta a mitad de camino y deja la base en un estado
intermedio, con los datos reales de la clínica dentro.

Además, el registro de migraciones de ambas partes es disjunto: producción tiene
30 entradas que el repo no tiene (las anteriores al squash de HFX-CLIN-000) y el
repo tiene 13 que producción no tiene. `db push` intentaría aplicar también la
línea base, que recrearía objetos ya existentes.

## El ensayo

`tool/produccion/ensayo_migracion.sh` restaura una copia de seguridad de
producción en el stack local, le aplica el adaptador y las migraciones
pendientes, y se detiene en el primer fallo. Convierte «esperemos que salga
bien» en «ya lo vimos salir bien». Destruye la base local a propósito.

```bash
npx supabase db dump --linked             -f copia/01_schema.sql
npx supabase db dump --linked --data-only -f copia/02_datos.sql
tool/produccion/ensayo_migracion.sh copia/
```

### Lo que encontró

1. **`recetas.estado` es un enum en producción y texto en el repo.** Producción
   llegó al formato nuevo de recetas por otra vía y lo resolvió con un enum
   `estado_receta` de tres etiquetas (`activa`, `anulada`, `reemplazada`).
   HFX-CLIN-002 necesita cuatro y hace `update ... set estado = 'emitida'`, que
   contra ese enum falla con «invalid input value for enum estado_receta».

   Lo resuelve `supabase/produccion/01_adaptar_a_linea_base.sql`, convirtiendo
   la columna a texto. El primer intento fue **ampliar** el enum, que parecía
   menos invasivo: las migraciones pasaban y luego dos suites fallaban con
   «operator does not exist: estado_receta = text», porque las RPC comparan
   `estado` contra variables `text`. Habría quedado una producción que migra
   bien y falla al usarse, que es peor que fallar al migrar.

2. **Dos cédulas repetidas entre pacientes vivos.** HFX-CLIN-004 impone unicidad
   de cédula normalizada y se niega a hacerlo mientras haya colisiones.
   **Requiere una decisión humana**; ver abajo.

3. Dos artefactos del propio ensayo, ya resueltos en el script: el volcado de
   datos choca con los buckets de Storage que el stack local ya tiene, y aborta
   antes de llegar a los `setval`, dejando toda secuencia en 1.

### Estado del ensayo

Con el adaptador y simulando la decisión de las cédulas:

- Las 11 migraciones aplican limpias sobre los datos reales.
- Las 13 suites SQL pasan contra la réplica ya migrada.
- Los datos quedan intactos: 15 personas, 10 pacientes, 82 citas, 47 consultas,
  26 cuentas, 23 pagos, 10 recetas — idéntico a antes de migrar.
- Las 13 RPC que faltaban existen.

---

## Lo que falta: las cédulas repetidas

Son **personas distintas compartiendo cédula**, no fichas duplicadas de la misma
persona. La cédula se compara normalizada, así que `402-1832135-0` y
`40218321350` colisionan.

| Cédula | Nombre | Nacimiento | Citas | Consultas | Cuentas |
|---|---|---|---|---|---|
| 402-1832135-0 | Jake Abreu | 2023-08-17 | 0 | 0 | 0 |
| 40218321350 | Leonardo Abreu | 2000-01-01 | 0 | 0 | 0 |
| 402-1838236-0 | Alberto Garcia | 2006-01-01 | 15 | 5 | 2 |
| 40218382360 | ELias De la cruz | 2005-01-01 | 47 | 28 | 16 |

El segundo par es el delicado: **ambas fichas tienen historia clínica y cuentas
reales**. Nada de esto se puede resolver automáticamente sin arriesgar el
expediente de alguien, así que queda para el dueño de los datos.

Opciones, sin recomendación técnica porque la respuesta es clínica:

- Corregir la cédula equivocada en una de cada par. Es lo que sugieren los
  nombres y fechas de nacimiento distintos.
- Unificar las fichas, si resultan ser la misma persona. Implica decidir qué
  pasa con citas, consultas y cuentas de la ficha que se retire.
- Retirar la ficha sobrante, viable sólo en el primer par: las dos están vacías.

---

## Procedimiento propuesto, cuando las cédulas estén resueltas

```bash
# 1 · Copia fresca, inmediatamente antes. Es la red de seguridad.
npx supabase db dump --linked             -f copia/01_schema.sql
npx supabase db dump --linked --data-only -f copia/02_datos.sql

# 2 · Repetir el ensayo con esa copia, ya sin parche de simulación.
tool/produccion/ensayo_migracion.sh copia/

# 3 · Sólo si el ensayo sale verde: adaptador contra producción.
psql "$URL_PRODUCCION" -v ON_ERROR_STOP=1 -f supabase/produccion/01_adaptar_a_linea_base.sql

# 4 · Declarar aplicadas las dos de la línea base, que producción ya tiene.
npx supabase migration repair --status applied 20260725000000 20260725000100

# 5 · Aplicar las 11 pendientes.
npx supabase db push
```

El paso 2 no es ceremonia: la copia del paso 1 refleja el estado real del
momento, y una clínica en funcionamiento cambia entre un ensayo y el siguiente.

### Verificación posterior

- Que las 13 RPC existan.
- Que los recuentos de personas, citas, consultas, cuentas y pagos coincidan con
  los de la copia.
- Iniciar sesión con un usuario real y abrir una consulta de principio a fin.

### Si algo sale mal

La copia del paso 1 permite restaurar. Conviene decidir **antes** de empezar en
qué ventana horaria se hace: durante los pasos 3 a 5 la base queda en un estado
intermedio y la clínica no debería estar usándola.
