-- SD-170 · Cerrar los arqueos de días anteriores que quedaron abiertos.
--
-- Desde `audit_002` una caja olvidada ya no bloquea el día siguiente: la
-- unicidad de caja abierta pasó a ser por día civil. El efecto secundario es
-- que esa caja podía quedarse abierta para siempre, porque toda la app resuelve
-- «la caja» como «la caja de hoy» y no existía forma de nombrar otra.
--
-- La app pasa a poder cerrarlas. Esta migración pone lo que la base le debía a
-- esa operación: cuándo se cerró, rastro de quién lo hizo, y la garantía de que
-- un arqueo cerrado no se reescribe.

begin;

-- ---------------------------------------------------------------------------
-- 1. Cuándo se cerró el arqueo
--
-- `fecha` es la de apertura y `updated_at` lo pisa cualquier escritura
-- posterior: no había ningún dato capaz de distinguir un cierre hecho el mismo
-- día de uno hecho tres días después, que es justo lo que este ticket permite.
-- ---------------------------------------------------------------------------
alter table public.cajas
  add column if not exists cerrada_at timestamptz;

comment on column public.cajas.cerrada_at is
  'Instante real del cierre del arqueo. NULL mientras la caja está abierta y '
  'también en las que se cerraron antes de SD-170: ese dato no existía y no se '
  'inventa. La diferencia con `fecha` mide el retraso del arqueo.';

-- ---------------------------------------------------------------------------
-- 2. La tabla viva de cajas no auditaba nada
--
-- `trg_auditoria_caja_diaria` cuelga de `public.cajas_diarias`, que no tiene
-- una sola referencia en la aplicación: la tabla que se usa es `public.cajas`,
-- y sus cierres no dejaban rastro. Un cierre tardío —dinero que se cuadra días
-- después— es precisamente la operación que no puede quedar sin registro.
--
-- `cajas_diarias` se deja como está: retirarla es un trabajo de limpieza de
-- esquema con su propio riesgo, ajeno a este ticket.
-- ---------------------------------------------------------------------------
drop trigger if exists trg_auditoria_caja on public.cajas;
create trigger trg_auditoria_caja
  after insert or delete or update on public.cajas
  for each row execute function public.fn_auditoria_log();

-- ---------------------------------------------------------------------------
-- 3. Un arqueo cerrado no se reescribe ni se reabre
--
-- `tr_validar_pago_caja_abierta` ya impide meter movimientos en una caja
-- cerrada, pero la fila de `cajas` quedaba escribible: dos sesiones viendo el
-- mismo aviso de arqueo pendiente podían cerrarlo las dos, y la segunda pisaba
-- el conteo de la primera sin que nadie se enterara. El cliente manda la
-- condición `cerrada = false` en su UPDATE; esto lo sostiene desde la base,
-- que es donde la regla no depende de qué versión de la app escriba.
--
-- Las observaciones sí se pueden seguir corrigiendo: son una nota, no dinero.
-- ---------------------------------------------------------------------------
create or replace function public.cajas_congelar_arqueo_cerrado()
returns trigger
language plpgsql
set search_path to 'public'
as $$
begin
  if old.cerrada and (
       new.cerrada        is distinct from old.cerrada
    or new.monto_apertura is distinct from old.monto_apertura
    or new.monto_esperado is distinct from old.monto_esperado
    or new.monto_real     is distinct from old.monto_real
    or new.monto_cierre   is distinct from old.monto_cierre
    or new.cerrada_at     is distinct from old.cerrada_at
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'Esa caja ya fue cerrada: su arqueo no se puede reescribir ni reabrir.';
  end if;

  return new;
end;
$$;

drop trigger if exists cajas_congelar_arqueo_cerrado on public.cajas;
create trigger cajas_congelar_arqueo_cerrado
  before update on public.cajas
  for each row execute function public.cajas_congelar_arqueo_cerrado();

commit;
