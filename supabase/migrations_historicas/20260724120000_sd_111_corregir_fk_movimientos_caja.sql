-- SD-111 · La aplicación y el trigger registran movimientos contra `cajas`.
--
-- Instalaciones anteriores conservaban la FK hacia la tabla heredada
-- `cajas_diarias`. Esa divergencia hacía que un pago válido revirtiera al
-- intentar insertar su movimiento automático de caja.

alter table public.movimientos_caja
  drop constraint if exists movimientos_caja_caja_diaria_id_fkey;

alter table public.movimientos_caja
  add constraint movimientos_caja_caja_diaria_id_fkey
  foreign key (caja_diaria_id)
  references public.cajas(id)
  on delete cascade;
