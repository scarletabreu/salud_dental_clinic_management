-- ============================================================================
--  Datos de arranque para desarrollo. Los carga `supabase db reset`
--  (ver `sql_paths` en supabase/config.toml).
--
--  SD-119 · Un día de caja completo, para poder abrir la app y ver la pantalla
--  de caja con movimientos reales sin tener que cobrar a mano:
--
--    · Ayer  → caja CERRADA con un faltante de RD$ 120.00 (el caso que la
--              clínica necesita ver bien pintado en el reporte de cierre).
--    · Hoy   → caja ABIERTA con ingresos y egresos mezclados.
--              Esperado = 5000 + 24 400.25 - 2050.50 = RD$ 27 349.75
--
--  Ese 27 349.75 es el mismo número que verifican las pruebas de Dart
--  (`test/features/caja_diaria/cerrar_caja_test.dart`): si el seed y las
--  pruebas dejan de coincidir, una de las dos copias del cálculo se movió.
--
--  El seed es idempotente: si ya existe una caja para hoy no vuelve a insertar.
--  No toca `pacientes`, `cuentas` ni `pagos`; el camino pago → ingreso lo cubre
--  `supabase/tests/sd_111_trigger_caja_test.sql`.
-- ============================================================================

do $seed$
declare
  v_zona constant text := 'America/Santo_Domingo';
  v_hoy  constant date := (now() at time zone v_zona)::date;
  v_caja_ayer uuid;
  v_caja_hoy  uuid;
begin
  if exists (
    select 1 from public.cajas
     where (fecha at time zone v_zona)::date = v_hoy
  ) then
    raise notice 'SD-119 seed: ya hay una caja para hoy, no se inserta nada.';
    return;
  end if;

  -- --------------------------------------------------------------------------
  -- Ayer: jornada cerrada con faltante. Apertura 5000, ingresos 12 300,
  -- egresos 1500 → esperado 15 800; se contaron 15 680 → diferencia -120.00.
  -- --------------------------------------------------------------------------
  insert into public.cajas (
    fecha, monto_apertura, monto_esperado, monto_real, monto_cierre,
    cerrada, observaciones
  ) values (
    (v_hoy - 1)::timestamptz + time '08:30',
    5000, 15800, 15680, 15680,
    true, 'Faltante de RD$ 120.00. Se revisa el arqueo de la tarde.'
  ) returning id into v_caja_ayer;

  insert into public.movimientos_caja (caja_diaria_id, tipo, monto, descripcion, fecha)
  values
    (v_caja_ayer, 'ingreso', 4800.00, 'Cobro de limpieza y dos resinas',      (v_hoy - 1)::timestamptz + time '10:15'),
    (v_caja_ayer, 'ingreso', 6500.00, 'Cobro de extracción de tercer molar',  (v_hoy - 1)::timestamptz + time '12:40'),
    (v_caja_ayer, 'ingreso', 1000.00, 'Abono a plan de cuotas',               (v_hoy - 1)::timestamptz + time '16:05'),
    (v_caja_ayer, 'egreso',  1500.00, 'Pago a laboratorio dental',            (v_hoy - 1)::timestamptz + time '17:20');

  -- --------------------------------------------------------------------------
  -- Hoy: jornada abierta. Sólo puede haber una caja con `cerrada = false`
  -- (índice único `cajas_una_abierta_idx`), por eso la de ayer va cerrada.
  -- --------------------------------------------------------------------------
  insert into public.cajas (
    fecha, monto_apertura, monto_esperado, monto_real, monto_cierre, cerrada
  ) values (
    v_hoy::timestamptz + time '08:30',
    5000, 5000, 0, 0, false
  ) returning id into v_caja_hoy;

  insert into public.movimientos_caja (caja_diaria_id, tipo, monto, descripcion, fecha)
  values
    (v_caja_hoy, 'ingreso',  3500.00, 'Cobro consulta y profilaxis',              v_hoy::timestamptz + time '09:45'),
    (v_caja_hoy, 'egreso',   1250.50, 'Compra de insumos de esterilización',      v_hoy::timestamptz + time '11:10'),
    (v_caja_hoy, 'ingreso', 18500.00, 'Cobro endodoncia multirradicular',         v_hoy::timestamptz + time '13:20'),
    (v_caja_hoy, 'egreso',    800.00, 'Pago de mensajería',                       v_hoy::timestamptz + time '15:00'),
    (v_caja_hoy, 'ingreso',  2400.25, 'Abono a plan de cuotas',                   v_hoy::timestamptz + time '16:30');

  raise notice
    'SD-119 seed: caja de ayer cerrada (faltante 120.00) y caja de hoy abierta (esperado 27349.75).';
end;
$seed$;
