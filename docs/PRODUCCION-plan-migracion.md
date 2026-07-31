# Migración de producción · EJECUTADA

Fecha del ensayo y de la ejecución: 2026-07-31.
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

Con el adaptador y la corrección de cédulas, sin simulaciones:

- Las 11 migraciones aplican limpias sobre los datos reales.
- Las 13 suites SQL pasan contra la réplica ya migrada.
- Los datos quedan intactos: 15 personas, 10 pacientes, 82 citas, 47 consultas,
  26 cuentas, 23 pagos, 10 recetas — idéntico a antes de migrar.
- Las 13 RPC que faltaban existen.

---

## Las cédulas repetidas: resueltas

Eran **personas distintas compartiendo cédula**, no fichas duplicadas de la
misma persona. La cédula se compara normalizada, así que `402-1832135-0` y
`40218321350` colisionaban.

Decisión del dueño de los datos (31 jul 2026): son datos de prueba, pero **no se
borra ninguna ficha**. Se corrige la cédula equivocada de una de cada par y se le
asigna una nueva válida, en `supabase/produccion/02_resolver_cedulas_repetidas.sql`.

| Persona | Cédula anterior | Cédula nueva | Citas | Consultas |
|---|---|---|---|---|
| Alberto Garcia | 402-1838236-0 | **402-9000001-3** | 15 | 5 |
| ELias De la cruz | 40218382360 | *(sin cambio)* | 47 | 28 |
| Leonardo Abreu | 40218321350 | **402-9000002-1** | 0 | 0 |
| Jake Abreu | 402-1832135-0 | *(sin cambio)* | 0 | 0 |

En el primer par, la cédula equivocada era la de Alberto. En el segundo ninguna
ficha tiene actividad, así que el criterio fue cuál mueve menos: Jake está
registrado como paciente y Leonardo sólo existe como usuario.

Las cédulas nuevas se generaron con el mismo algoritmo que valida la aplicación
(`isValidCedula`: módulo 10 de la JCE) y se comprobó que no chocan con ninguna
existente.

**No se tocó ninguna otra cédula.** Producción tiene varias inválidas
—`666-6666666-6`, `99999999999999`, `121-1212121-1`, `00120000000`— pero son
únicas y no bloquean nada. Corregirlas sería reescribir datos sin que nadie lo
haya pedido; queda anotado por si algún día interesa.

---

## Procedimiento ejecutado

```bash
# 1 · Copia fresca, inmediatamente antes. Es la red de seguridad.
npx supabase db dump --linked             -f copia/01_schema.sql
npx supabase db dump --linked --data-only -f copia/02_datos.sql

# 2 · Repetir el ensayo con esa copia, ya sin parche de simulación.
tool/produccion/ensayo_migracion.sh copia/

# 3 · Sólo si el ensayo sale verde: adaptador y corrección de datos.
psql "$URL_PRODUCCION" -v ON_ERROR_STOP=1 -f supabase/produccion/01_adaptar_a_linea_base.sql
psql "$URL_PRODUCCION" -v ON_ERROR_STOP=1 -f supabase/produccion/02_resolver_cedulas_repetidas.sql

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

---

## Ejecución (31 jul 2026)

Copia previa: `backups/salud_dental/20260731-190728-premigracion` (esquema,
datos y el registro de migraciones remoto antes de tocarlo).

`db push` se negó al primer intento: el registro remoto tenía 30 entradas
anteriores al squash que el repositorio no conoce. Se marcaron como
`reverted` —operación de metadatos: no revierte nada del esquema— y el
registro quedó reconciliado. Es la deuda que dejó HFX-CLIN-000.

Resultado: las 11 migraciones aplicadas, y los recuentos idénticos a la copia
previa (15 personas, 10 pacientes, 3 doctores, 82 citas, 47 consultas, 26
cuentas, 23 pagos, 10 recetas, 17 tratamientos). Las 13 RPC que faltaban
existen.

### Lo que apareció al verificar: dos tablas sin RLS

El gate estructural de la certificación comprueba que ninguna tabla de `public`
quede sin RLS o sin políticas, pero **lo hace contra la base local**. Una tabla
que sólo existe en producción le es invisible, y había dos.

`auditoria_log` —creada a mano en el Studio, no está en el repositorio— tenía
RLS desactivado y `authenticated` con `select`. Guarda `to_jsonb(OLD)` y
`to_jsonb(NEW)` de cada fila auditada: 271 registros con imágenes completas de
citas, consultas, cuentas y pagos, legibles por cualquier sesión de la
aplicación. `items_receta`, tabla legada que la aplicación ya no consulta,
tenía RLS activado sin ninguna política.

Ambas cerradas en `20260808090000_hfx_clin_009_rls_tablas_derivadas.sql`, sin
borrar una sola fila. La migración lleva dentro su propia comprobación, para
que la verificación viaje con el esquema en lugar de depender de un gate que
mira otra base.

**Conviene recordarlo:** un gate que audita la base local no dice nada sobre la
deriva de producción. Verificar la instancia remota después de migrar no es
ceremonia; fue lo que destapó la fuga.
