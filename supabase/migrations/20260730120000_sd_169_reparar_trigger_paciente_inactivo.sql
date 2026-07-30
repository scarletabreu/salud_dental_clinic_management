-- ============================================================================
--  SD-169 · Reparar el trigger que cancela las citas de un paciente inactivo
--
--  `cancelar_citas_paciente_inactivo()` nunca se versionó como migración: vivía
--  solo dentro del volcado `supabase/schema.sql`, así que ni el renombrado del
--  enum de SD-81 ni el de la columna de `citas` la arrastraron. Su cuerpo
--  apuntaba a `citas.paciente_id` (la columna es `persona_id`), y plpgsql
--  resuelve los nombres al ejecutar, no al crear: el error solo aparecía al
--  disparar el trigger. Resultado medido en la instancia:
--
--      UPDATE personas SET estatus = 'inactivo' WHERE id = <persona activa>;
--      → ERROR 42703: column "paciente_id" does not exist
--
--  No era una degradación parcial. `tr_paciente_inactivo_cancela_citas` es
--  AFTER UPDATE OF estatus, la excepción sube y aborta la transacción entera:
--  desactivar un paciente era imposible. Y como la app manda `estatus` en cada
--  `update` de persona (persona_remote_datasource_impl.dart), editar a un
--  paciente ya inactivo fallaba por el mismo camino.
--
--  Esta migración reescribe la función completa (no se puede parchear un cuerpo
--  plpgsql) y recrea el trigger, para que a partir de aquí viajen con el resto
--  del esquema. Es idempotente.
-- ============================================================================

create or replace function public.cancelar_citas_paciente_inactivo()
returns trigger
language plpgsql
set search_path to 'public'
as $$
begin
  -- Solo la TRANSICIÓN a inactivo cancela. La app manda `estatus` en cada
  -- update de persona, así que sin esta comprobación un simple cambio de
  -- teléfono en un paciente ya inactivo volvería a barrer su agenda.
  if new.estatus = 'inactivo'::estatus_persona
     and old.estatus is distinct from new.estatus
  then
    update citas
       set estado     = 'cancelada'::estado_cita,
           updated_at = now()
     where persona_id = new.id
       and deleted_at is null
       and fecha_hora > now()
       -- Estados vivos y anteriores a la atención. `en_consulta` queda fuera a
       -- propósito: si al paciente lo están atendiendo ahora mismo, un cambio
       -- administrativo no le cierra la cita por debajo. Los terminales
       -- (completada, cancelada, no_asistio, no_asistida) tampoco se tocan.
       and estado in (
             'programada'::estado_cita,
             'confirmada'::estado_cita,
             'en_espera'::estado_cita
           )
       -- Regla de SD-160: no existe cita cancelada con consulta abierta. Sin
       -- este filtro chocaríamos contra
       -- `tr_bloquear_cancelacion_con_consulta_abierta`, cuyo P0001 volvería a
       -- abortar la desactivación del paciente: cambiaríamos un fallo
       -- permanente por uno intermitente y mucho peor de diagnosticar.
       --
       -- Decisión: esas citas se dejan VIVAS, no se silencian ni se marcan.
       -- Su consulta está en curso; la cierra el flujo clínico, que es quien
       -- sabe qué se hizo. Desactivar al paciente no puede reescribir un acto
       -- clínico en marcha.
       and not exists (
             select 1
             from consultas c
             where c.cita_id = citas.id
               and c.deleted_at is null
               and c.finalizada is not true
           );
  end if;
  return new;
end;
$$;

comment on function public.cancelar_citas_paciente_inactivo() is
  'SD-169: al pasar una persona a inactivo, cancela sus citas futuras todavía '
  'vivas (programada, confirmada, en_espera). Excluye en_consulta y las citas '
  'con consulta abierta, que se dejan activas para que las cierre el flujo '
  'clínico (regla de SD-160).';

-- El trigger tampoco estaba versionado: se recrea para que una base
-- reconstruida desde las migraciones lo tenga.
drop trigger if exists tr_paciente_inactivo_cancela_citas on public.personas;

create trigger tr_paciente_inactivo_cancela_citas
  after update of estatus on public.personas
  for each row
  execute function public.cancelar_citas_paciente_inactivo();
