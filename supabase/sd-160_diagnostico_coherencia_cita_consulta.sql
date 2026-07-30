-- ============================================================================
--  SD-160 · Diagnóstico de coherencia cita ↔ consulta  (SOLO LECTURA)
--
--  Este script NO modifica datos. Devuelve un conjunto de filas por cada tipo
--  de inconsistencia; el objetivo es que, tras aplicar las correcciones, las
--  cuatro categorías devuelvan cero filas.
--
--  Cómo leerlo: cada bloque devuelve una tabla con la columna `problema` como
--  discriminante, de modo que se puede ejecutar el script completo y ordenar
--  por ella. Se ejecuta con el rol de servicio (bypassa RLS) para ver toda la
--  clínica, no solo lo que vería un doctor.
--
--  Categorías:
--    A. consultas cuya `fecha` no cae el mismo día que su cita
--    B. consultas abiertas cuya cita está cancelada o completada
--    C. citas `completada` sin consulta asociada
--    D. citas `en_consulta` sin consulta abierta (el reverso de B)
--
--  Contexto de la corrupción: hasta SD-160 la consulta nacía con
--  `fecha = now()` (la del clic) en vez de heredar `citas.fecha_hora`. Toda
--  consulta creada desde una cita en un día distinto al agendado aparece en
--  la categoría A.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- A. Fecha de la consulta desalineada del día de su cita.
--    `desfase_dias` da el signo y la magnitud: >0 = la consulta quedó después
--    del día agendado (el caso típico de atender hoy una cita de ayer).
-- ---------------------------------------------------------------------------
select
  'A. fecha de consulta != dia de la cita' as problema,
  c.id                                     as consulta_id,
  c.cita_id,
  c.fecha                                  as consulta_fecha,
  ci.fecha_hora                            as cita_fecha_hora,
  (c.fecha::date - ci.fecha_hora::date)    as desfase_dias,
  c.finalizada,
  ci.estado                                as cita_estado,
  c.created_at                             as consulta_creada_en
from consultas c
join citas ci on ci.id = c.cita_id
where c.deleted_at is null
  and ci.deleted_at is null
  and c.fecha::date <> ci.fecha_hora::date
order by abs(c.fecha::date - ci.fecha_hora::date) desc, c.fecha desc;

-- ---------------------------------------------------------------------------
-- B. Consulta abierta con la cita ya cerrada.
--    Es el síntoma que SD-160 persigue: la agenda dice "Cancelada" mientras la
--    lista de consultas sigue mostrando "En curso".
-- ---------------------------------------------------------------------------
select
  'B. consulta abierta con cita cerrada' as problema,
  c.id                                   as consulta_id,
  c.cita_id,
  ci.estado                              as cita_estado,
  c.fecha                                as consulta_fecha,
  ci.fecha_hora                          as cita_fecha_hora,
  c.doctor_id,
  c.paciente_id
from consultas c
join citas ci on ci.id = c.cita_id
where c.deleted_at is null
  and ci.deleted_at is null
  and c.finalizada is not true
  and ci.estado in ('cancelada', 'completada')
order by ci.fecha_hora desc;

-- ---------------------------------------------------------------------------
-- C. Cita completada sin ninguna consulta.
--
--    DECISIÓN (SD-160): se considera DATO INCONSISTENTE. Una cita solo debe
--    llegar a `completada` por dos caminos, y ambos dejan consulta:
--      · `finalizar_consulta`, que la completa en la misma transacción;
--      · el cierre de una evaluación, que también crea su consulta.
--    Por tanto una cita completada sin consulta significa que alguien la marcó
--    a mano sin atender, o que su consulta se eliminó después. No se corrige
--    automáticamente (no se puede inventar el acto clínico): se detecta aquí y
--    se resuelve caso por caso, devolviendo la cita a un estado no terminal o
--    registrando la consulta que faltó.
-- ---------------------------------------------------------------------------
select
  'C. cita completada sin consulta' as problema,
  ci.id                             as cita_id,
  ci.fecha_hora                     as cita_fecha_hora,
  ci.estado                         as cita_estado,
  ci.doctor_id,
  ci.persona_id,
  ci.motivo,
  ci.updated_at                     as cita_actualizada_en
from citas ci
where ci.deleted_at is null
  and ci.estado = 'completada'
  and not exists (
    select 1
    from consultas c
    where c.cita_id = ci.id
      and c.deleted_at is null
  )
order by ci.fecha_hora desc;

-- ---------------------------------------------------------------------------
-- D. Cita en_consulta sin consulta abierta (reverso de B).
--    O la consulta se cerró sin cerrar la cita —lo que ocurría al reintentar
--    `finalizar_consulta`, que salía por el retorno idempotente antes de
--    completar la cita— o nunca se creó.
-- ---------------------------------------------------------------------------
select
  'D. cita en_consulta sin consulta abierta' as problema,
  ci.id                                      as cita_id,
  ci.fecha_hora                              as cita_fecha_hora,
  ci.doctor_id,
  ci.persona_id,
  (
    select count(*)
    from consultas c
    where c.cita_id = ci.id and c.deleted_at is null
  ) as consultas_asociadas
from citas ci
where ci.deleted_at is null
  and ci.estado = 'en_consulta'
  and not exists (
    select 1
    from consultas c
    where c.cita_id = ci.id
      and c.deleted_at is null
      and c.finalizada is not true
  )
order by ci.fecha_hora desc;

-- ---------------------------------------------------------------------------
-- Resumen: una fila por categoría con su conteo. Útil para verificar de un
-- vistazo que la corrección dejó todo en cero.
-- ---------------------------------------------------------------------------
select 'A. fecha de consulta != dia de la cita' as problema, count(*) as filas
from consultas c join citas ci on ci.id = c.cita_id
where c.deleted_at is null and ci.deleted_at is null
  and c.fecha::date <> ci.fecha_hora::date
union all
select 'B. consulta abierta con cita cerrada', count(*)
from consultas c join citas ci on ci.id = c.cita_id
where c.deleted_at is null and ci.deleted_at is null
  and c.finalizada is not true and ci.estado in ('cancelada', 'completada')
union all
select 'C. cita completada sin consulta', count(*)
from citas ci
where ci.deleted_at is null and ci.estado = 'completada'
  and not exists (
    select 1 from consultas c where c.cita_id = ci.id and c.deleted_at is null
  )
union all
select 'D. cita en_consulta sin consulta abierta', count(*)
from citas ci
where ci.deleted_at is null and ci.estado = 'en_consulta'
  and not exists (
    select 1 from consultas c
    where c.cita_id = ci.id and c.deleted_at is null and c.finalizada is not true
  )
order by problema;
