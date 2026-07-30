# Reparar el trigger que cancela las citas de un paciente inactivo

Detectado el 29 jul 2026 al cerrar SD-160. Verificado contra la instancia real
(`xcuvywvltttephakzmwu`), no solo contra `supabase/schema.sql`.

> **Resuelto en SD-169** (30 jul 2026). La función se reescribió versionada en
> `supabase/migrations/20260730120000_sd_169_reparar_trigger_paciente_inactivo.sql`,
> `supabase/schema.sql` quedó alineado y el camino completo lo cubre
> `supabase/tests/sd_169_paciente_inactivo_test.sql`.
> **Pendiente de aplicar en la instancia**: la migración todavía no se ha
> ejecutado en `xcuvywvltttephakzmwu`, así que ahí desactivar un paciente sigue
> fallando con `42703`.

## Lo que hay

La función `public.cancelar_citas_paciente_inactivo()`, colgada del trigger
`tr_paciente_inactivo_cancela_citas` (`AFTER UPDATE OF estatus ON personas`),
está escrita contra un esquema que no existe. Su cuerpo hace:

```sql
UPDATE public.citas
   SET estado = 'cancelada'
 WHERE paciente_id = NEW.id      -- ← la columna se llama persona_id
   AND fecha_hora > now()
   AND estado = 'pendiente';     -- ← el enum estado_cita no tiene 'pendiente'
```

Dos defectos independientes en cuatro líneas:

1. **`citas.paciente_id` no existe.** La tabla usa `persona_id` (ver
   `supabase/schema.sql`, definición de `citas`). Postgres solo resuelve los
   nombres de columna al ejecutar el cuerpo, así que el error no aparece al
   crear la función: aparece cuando el trigger dispara.
2. **`'pendiente'` no es un valor de `estado_cita`.** Es un resto anterior a la
   migración de SD-81, que renombró ese estado a `programada`
   (`supabase/sd-81_estados_cita.sql`). Aunque la columna se llamara bien, el
   `WHERE` no casaría con ninguna fila.

**Consecuencia medida:** como el trigger es `AFTER UPDATE` y la excepción sube,
**desactivar un paciente falla por completo**. Comprobado en la instancia:

```
UPDATE personas SET estatus = 'inactivo' WHERE id = <cualquier persona activa>;
→ ERROR 42703: column "paciente_id" does not exist
```

No es una degradación parcial: la funcionalidad «marcar paciente inactivo» está
caída, y con ella cualquier flujo de la app que escriba `personas.estatus`.

Hay un segundo problema de diseño, ya latente: si la función se arreglara tal
cual, cancelaría citas **saltándose la regla de SD-160** que prohíbe cancelar
una cita con su consulta abierta. El trigger
`tr_bloquear_cancelacion_con_consulta_abierta` (añadido en
`20260729120000_sd_160_coherencia_cita_consulta.sql`) lo abortaría con
`P0001`, y ese error volvería a romper la desactivación del paciente. Es decir:
arreglar solo los dos nombres cambia un fallo permanente por un fallo
intermitente, difícil de diagnosticar.

Por qué no se vio antes: la función no está versionada como migración propia.
Vive en `supabase/schema.sql` (volcado de la instancia) y nadie la ejecutó desde
que SD-81 renombró el enum. Es el mismo patrón de drift que ya documenta
`supabase/README.md`.

## Lo que se debe hacer

Una migración nueva en `supabase/migrations/`, idempotente, que reescriba la
función completa (no se puede parchear un cuerpo plpgsql) con estos cambios:

1. **Corregir la columna:** `WHERE persona_id = NEW.id`.

2. **Corregir el estado:** cancelar las citas que todavía no ocurrieron y no
   están en un estado terminal, en vez de comparar contra `'pendiente'`. Lo
   correcto es un `IN` explícito sobre los estados no terminales y previos a la
   atención:
   ```sql
   AND estado IN ('programada', 'confirmada', 'en_espera')
   ```
   `en_consulta` queda deliberadamente fuera: si el paciente está siendo
   atendido ahora mismo, esa cita no se cancela por un cambio administrativo.

3. **Respetar la regla de SD-160 sin romper la desactivación.** Excluir del
   `UPDATE` las citas que tengan una consulta abierta, para no chocar contra
   `tr_bloquear_cancelacion_con_consulta_abierta`:
   ```sql
   AND NOT EXISTS (
     SELECT 1 FROM consultas c
     WHERE c.cita_id = citas.id
       AND c.deleted_at IS NULL
       AND c.finalizada IS NOT TRUE
   )
   ```
   Decidir y dejar escrito en el comentario de la función qué pasa con esas
   citas excluidas. La recomendación es **no** silenciarlas: dejarlas activas y
   que el flujo clínico las cierre, ya que su consulta está en curso.

4. **Añadir `deleted_at IS NULL`** al `UPDATE`: hoy tocaría citas borradas
   lógicamente.

5. **Poner `updated_at = now()`**, que la versión actual no actualiza, y fijar
   `SET search_path TO 'public'` como hacen las funciones nuevas del repo.

6. **Alinear `supabase/schema.sql`** con la definición corregida, para que el
   volcado deje de propagar la versión rota.

Verificación mínima antes de cerrar:

- Desactivar un paciente **sin** citas futuras: no falla.
- Desactivar un paciente **con** citas futuras en `programada`/`confirmada`/
  `en_espera`: no falla y esas citas quedan `cancelada`.
- Desactivar un paciente con una cita cuya **consulta está abierta**: no falla,
  y esa cita concreta **no** se cancela.
- Reactivar el paciente (`estatus = 'activo'`): el trigger no toca nada.
- Un test que cubra el camino completo, dado que hoy no hay ninguno: es la razón
  por la que el defecto sobrevivió a la migración de SD-81.

## Lo que se espera

Marcar un paciente como inactivo vuelve a funcionar, que hoy es imposible. Al
hacerlo, sus citas futuras que aún no han empezado pasan a `cancelada` de forma
automática, liberando la agenda del odontólogo sin intervención manual.

Las citas cuya consulta está en curso se respetan: no se cancelan por la espalda
y no hacen fallar la desactivación. Ninguna operación administrativa sobre
`personas` puede volver a abortar por un trigger que apunta a columnas
inexistentes, y la regla de SD-160 —no hay cita cancelada con consulta abierta—
se sigue cumpliendo también por este camino, que hoy era una puerta trasera.

La meta de fondo es cerrar el drift: la función deja de existir solo dentro de un
volcado y pasa a estar versionada como migración, de modo que el siguiente
renombrado de un enum o de una columna la arrastre con el resto del esquema en
vez de dejarla rota y en silencio hasta que alguien dispare el trigger.
