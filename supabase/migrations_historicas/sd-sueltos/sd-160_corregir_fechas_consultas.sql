-- ============================================================================
--  SD-160 · Corrección de datos: realinear consultas.fecha con su cita
--
--  ⚠️ MODIFICA DATOS CLÍNICOS YA ESCRITOS Y NO ES REVERSIBLE sin un respaldo.
--     No se ejecuta como parte de la migración: primero se corre el
--     diagnóstico (sd-160_diagnostico_coherencia_cita_consulta.sql, categoría
--     A) y se decide con esas filas delante si esta corrección procede y en
--     qué alcance.
--
--  Qué corrige:
--    Hasta SD-160 la consulta se guardaba con `fecha = now()` —la del clic— en
--    vez de heredar `citas.fecha_hora`. Como la lista de consultas ordena por
--    `fecha` descendente, una consulta abierta desde una cita de otro día
--    aparecía en un día que no era el de la agenda.
--
--  Qué NO toca:
--    · Consultas sin `cita_id` (walk-in): no hay fecha agendada de la que
--      heredar y su `fecha` es legítima.
--    · `created_at`: es el momento real de apertura. Precisamente por no tener
--      dónde poner ese dato se reutilizaba `fecha` para las dos cosas; ahora
--      cada una vive en su columna y ninguna se pierde.
--
--  Se realinea el timestamp completo, no solo el día: la agenda y la lista
--  ordenan por él y deben coincidir hasta la hora.
--
--  Uso recomendado: ejecutar los pasos 1 y 2 y comparar. El paso 3 va dentro
--  de una transacción explícita para poder abortar si el conteo no cuadra.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- PASO 1 (solo lectura). Qué se va a cambiar, fila por fila.
-- ---------------------------------------------------------------------------
select
  c.id                                  as consulta_id,
  c.fecha                               as fecha_actual,
  ci.fecha_hora                         as fecha_corregida,
  (c.fecha::date - ci.fecha_hora::date) as desfase_dias,
  c.finalizada,
  ci.estado                             as cita_estado
from consultas c
join citas ci on ci.id = c.cita_id
where c.deleted_at is null
  and ci.deleted_at is null
  and c.fecha <> ci.fecha_hora
order by abs(c.fecha::date - ci.fecha_hora::date) desc;

-- ---------------------------------------------------------------------------
-- PASO 2 (solo lectura). Cuántas filas y cuál es el desfase máximo.
-- ---------------------------------------------------------------------------
select
  count(*)                                          as filas_a_corregir,
  max(abs(c.fecha::date - ci.fecha_hora::date))     as desfase_max_dias,
  count(*) filter (where c.fecha::date = ci.fecha_hora::date) as solo_hora_distinta
from consultas c
join citas ci on ci.id = c.cita_id
where c.deleted_at is null
  and ci.deleted_at is null
  and c.fecha <> ci.fecha_hora;

-- ---------------------------------------------------------------------------
-- PASO 3. La corrección. Revisar el conteo devuelto antes del COMMIT.
--
--   begin;
--
--   update consultas c
--      set fecha      = ci.fecha_hora,
--          updated_at = now()
--     from citas ci
--    where ci.id = c.cita_id
--      and c.deleted_at is null
--      and ci.deleted_at is null
--      and c.fecha <> ci.fecha_hora;
--
--   -- Debe devolver 0: si no, algo quedó sin realinear.
--   select count(*)
--   from consultas c join citas ci on ci.id = c.cita_id
--   where c.deleted_at is null and ci.deleted_at is null
--     and c.fecha <> ci.fecha_hora;
--
--   commit;   -- o `rollback;` si el conteo no es 0
-- ---------------------------------------------------------------------------
