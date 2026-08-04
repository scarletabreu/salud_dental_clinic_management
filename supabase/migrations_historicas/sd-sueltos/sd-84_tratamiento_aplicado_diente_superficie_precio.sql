-- ============================================================================
--  SD-84 · Completar TratamientoAplicado: diente, superficie y precio congelado
--  Ejecuta este archivo en el SQL Editor de Supabase (una sola vez).
--
--  Objetivo:
--    Que cada tratamiento aplicado sepa EN QUÉ consulta, diente y superficie se
--    hizo y A QUÉ PRECIO, de modo que la suma de `precio_aplicado` de una
--    consulta dé el monto de la pre-factura (FinalizarConsulta).
--
--  Esquema real (verificado contra la BD):
--    · tratamientos_aplicados.id tiene DEFAULT gen_random_uuid().
--    · El enum `tipo_superficie` es en minúscula (mesial, distal, ...).
--    · Las superficies y dientes ya existen (creados por crear_consulta_completa).
--
--  Columnas que se agregan a `tratamientos_aplicados`:
--    · diente_id      uuid NULL  → diente donde se aplicó. NULL = tratamiento
--                                  general (p. ej. limpieza), no ligado a un diente.
--    · superficie     tipo_superficie NULL → superficie concreta del diente.
--    · precio_aplicado numeric(10,2) → precio COPIADO del catálogo al momento de
--                                  aplicar. Congelado: cambios futuros al catálogo
--                                  NO alteran cuentas ya emitidas.
--    · consulta_id    uuid NULL  → consulta a la que pertenece (facturación).
--    · notas          text NULL  → justificación clínica del tratamiento (HOTFIX-5).
--
--  Decisión sobre los arrays inversos (documentada):
--    · `dientes.tratamientos_aplicados_ids` y `superficies.tratamientos_ids` se
--      MANTIENEN como índice inverso DEPRECADO. La fuente canónica de la relación
--      pasa a ser `tratamientos_aplicados.diente_id` / `.superficie`. No se
--      eliminan aquí porque la app todavía los lee (diente_model,
--      consulta_detalle_cubit); su retiro será un ticket aparte.
-- ============================================================================

alter table tratamientos_aplicados
  add column if not exists diente_id       uuid            null references dientes(id),
  add column if not exists superficie      tipo_superficie null,
  add column if not exists precio_aplicado numeric(10,2)   null,
  add column if not exists consulta_id     uuid            null references consultas(id),
  add column if not exists notas           text            null;

-- Índices para las consultas de facturación (sumar por consulta) e historial
-- (tratamientos por diente).
create index if not exists idx_tratamientos_aplicados_consulta_id
  on tratamientos_aplicados (consulta_id);

create index if not exists idx_tratamientos_aplicados_diente_id
  on tratamientos_aplicados (diente_id);
