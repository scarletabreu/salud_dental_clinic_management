-- ============================================================================
--  SD-119 · Prueba del trigger `pagos_registrar_ingreso_caja` (SD-111 / S4-02).
--
--  Contrato que se verifica:
--    1. Un pago `completado` inserta exactamente UN ingreso en la caja abierta,
--       por el monto del pago y referenciando el pago.
--    2. Un pago que no está `completado` no toca la caja.
--    3. Un pago `completado` sin caja abierta del día falla con P0001 y no deja
--       el pago persistido (el trigger es AFTER INSERT: aborta la transacción).
--    4. La caja de un día anterior no sirve para el pago de hoy.
--    5. No queda ningún trigger duplicado sobre `pagos` que doble el ingreso.
--
--  Cómo ejecutarla (NO deja datos: todo corre dentro de una transacción que se
--  revierte al final; si algo falla, la excepción aborta igual la transacción):
--
--    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 \
--      -f supabase/tests/sd_111_trigger_caja_test.sql
--
--  Contra la base local:  supabase db reset && psql "$(supabase status -o env \
--      | grep DB_URL | cut -d= -f2- | tr -d '\"')" -v ON_ERROR_STOP=1 \
--      -f supabase/tests/sd_111_trigger_caja_test.sql
--
--  Salida esperada: cinco `NOTICE  OK ...` y `ROLLBACK`. Cualquier ERROR es un
--  fallo real del trigger.
-- ============================================================================

begin;

-- El trigger es SECURITY DEFINER y lee `cajas`/`movimientos_caja` con RLS
-- activo. Se ejecuta la prueba como superusuario (rol de psql), que es el mismo
-- contexto en el que corre el owner de la función.
set local role postgres;

do $test$
declare
  v_persona_id  uuid := gen_random_uuid();
  v_doctor_id   uuid := gen_random_uuid();
  v_consulta_id uuid;
  v_cuenta_id   uuid;
  v_caja_hoy    uuid;
  v_caja_ayer   uuid;
  v_pago_id     uuid;
  v_movimientos int;
  v_monto       numeric(12,2);
  v_referencia  uuid;
  v_triggers    int;
  v_zona constant text := 'America/Santo_Domingo';
begin
  -- --------------------------------------------------------------------------
  -- Fixtures mínimos: la cadena completa que exigen las FK de `pagos`.
  --
  --   personas → pacientes                    ─┐
  --   personas → usuarios → doctores          ─┴→ consultas → cuentas → pagos
  --
  -- `cuentas.consulta_id` es NOT NULL, así que no se puede cobrar sin consulta.
  -- --------------------------------------------------------------------------
  insert into public.personas (id, nombre, apellido, fecha_nacimiento, cedula, estatus)
  values (v_persona_id, 'Paciente', 'De Prueba SD-119', date '1990-01-01',
          'SD119-P-' || substr(v_persona_id::text, 1, 8), 'activo');

  insert into public.pacientes (id, genero, tipo_paciente)
  values (v_persona_id, 'otro', 'integrado');

  insert into public.personas (id, nombre, apellido, fecha_nacimiento, cedula, estatus)
  values (v_doctor_id, 'Doctor', 'De Prueba SD-119', date '1980-01-01',
          'SD119-D-' || substr(v_doctor_id::text, 1, 8), 'activo');

  insert into public.usuarios (id, username)
  values (v_doctor_id, 'sd119-' || substr(v_doctor_id::text, 1, 8));

  insert into public.doctores (id, especialidad)
  values (v_doctor_id, 'Odontología general');

  insert into public.consultas (paciente_id, doctor_id, fecha, motivo_consulta)
  values (v_persona_id, v_doctor_id, now(), 'Consulta de prueba SD-119')
  returning id into v_consulta_id;

  insert into public.cuentas (paciente_id, consulta_id, estado, monto_total,
                              metodo_pago, fecha_creacion)
  values (v_persona_id, v_consulta_id, 'abierta', 10000, 'contado', now())
  returning id into v_cuenta_id;

  -- --------------------------------------------------------------------------
  -- Precondición: la prueba no puede asumir el estado de la base. Si hay una
  -- caja abierta (el seed deja una, y en una instancia real la habrá casi
  -- siempre), el caso 3 no probaría nada. Se cierra dentro de la transacción,
  -- así que el ROLLBACK final la devuelve intacta.
  -- --------------------------------------------------------------------------
  update public.cajas set cerrada = true where cerrada = false;

  -- --------------------------------------------------------------------------
  -- Caso 3 (ya sin caja abierta): el pago debe ser rechazado.
  -- --------------------------------------------------------------------------
  begin
    insert into public.pagos (cuenta_id, monto, fecha, estado, metodo_pago)
    values (v_cuenta_id, 1500, now(), 'completado', 'efectivo');

    raise exception
      'FALLO (3): un pago completado sin caja abierta debió ser rechazado y pasó.';
  exception
    when sqlstate 'P0001' then
      -- Es el error esperado del trigger. Si el mensaje fuera otro P0001 (por
      -- ejemplo el propio FALLO de arriba), se distingue por el texto.
      if sqlerrm like 'FALLO%' then
        raise exception '%', sqlerrm;
      end if;
      raise notice 'OK (3) sin caja abierta el pago se rechaza: %', sqlerrm;
  end;

  if exists (select 1 from public.pagos where cuenta_id = v_cuenta_id) then
    raise exception
      'FALLO (3b): el pago quedó persistido pese a que el trigger falló.';
  end if;

  -- --------------------------------------------------------------------------
  -- Caso 4: una caja abierta pero de AYER no habilita el pago de hoy.
  -- --------------------------------------------------------------------------
  insert into public.cajas (fecha, monto_apertura, cerrada)
  values (now() - interval '1 day', 5000, false)
  returning id into v_caja_ayer;

  begin
    insert into public.pagos (cuenta_id, monto, fecha, estado, metodo_pago)
    values (v_cuenta_id, 1500, now(), 'completado', 'efectivo');

    raise exception
      'FALLO (4): la caja de ayer no debe habilitar el cobro de hoy.';
  exception
    when sqlstate 'P0001' then
      if sqlerrm like 'FALLO%' then
        raise exception '%', sqlerrm;
      end if;
      raise notice 'OK (4) la caja de ayer no habilita el cobro de hoy.';
  end;

  -- El índice único `cajas_una_abierta_idx` sólo admite una caja abierta a la
  -- vez, así que la de ayer se cierra antes de abrir la de hoy.
  update public.cajas set cerrada = true where id = v_caja_ayer;

  -- --------------------------------------------------------------------------
  -- Caso 1: pago completado con la caja de hoy abierta.
  -- --------------------------------------------------------------------------
  insert into public.cajas (fecha, monto_apertura, cerrada)
  values (now(), 5000, false)
  returning id into v_caja_hoy;

  insert into public.pagos (cuenta_id, monto, fecha, estado, metodo_pago)
  values (v_cuenta_id, 1500.75, now(), 'completado', 'efectivo')
  returning id into v_pago_id;

  -- `max()` no está definido para uuid, de ahí el array_agg.
  select count(*), coalesce(max(monto), 0), (array_agg(referencia_id))[1]
    into v_movimientos, v_monto, v_referencia
    from public.movimientos_caja
   where caja_diaria_id = v_caja_hoy
     and deleted_at is null;

  if v_movimientos <> 1 then
    raise exception
      'FALLO (1): se esperaba 1 movimiento de caja y hay %. Un trigger duplicado doblaría el ingreso del día.',
      v_movimientos;
  end if;

  if v_monto <> 1500.75 then
    raise exception 'FALLO (1): el ingreso registró % en vez de 1500.75.', v_monto;
  end if;

  if v_referencia is distinct from v_pago_id then
    raise exception
      'FALLO (1): el movimiento no referencia el pago que lo originó (% vs %).',
      v_referencia, v_pago_id;
  end if;

  if not exists (
    select 1 from public.movimientos_caja
     where caja_diaria_id = v_caja_hoy and tipo = 'ingreso'
  ) then
    raise exception 'FALLO (1): el movimiento no se registró como ingreso.';
  end if;

  raise notice 'OK (1) el pago completado generó un ingreso de % en la caja de hoy.', v_monto;

  -- --------------------------------------------------------------------------
  -- Caso 2: un pago que no está completado no mueve la caja.
  -- --------------------------------------------------------------------------
  insert into public.pagos (cuenta_id, monto, fecha, estado, metodo_pago)
  values (v_cuenta_id, 999, now(), 'pendiente', 'efectivo');

  select count(*) into v_movimientos
    from public.movimientos_caja
   where caja_diaria_id = v_caja_hoy
     and deleted_at is null;

  if v_movimientos <> 1 then
    raise exception
      'FALLO (2): un pago no completado movió la caja (hay % movimientos).',
      v_movimientos;
  end if;

  raise notice 'OK (2) el pago pendiente no movió la caja.';

  -- --------------------------------------------------------------------------
  -- Caso 5: un solo trigger de caja sobre `pagos`.
  --
  -- El drift ya metió una vez `tr_pago_a_movimiento_caja` conviviendo con
  -- `pagos_registrar_ingreso_caja`; dos triggers duplican cada cobro del día.
  -- --------------------------------------------------------------------------
  -- Se cuentan sólo los triggers que ESCRIBEN en `movimientos_caja`. `pagos`
  -- tiene legítimamente otros (p. ej. `tr_validar_exceso_pago`, que valida el
  -- saldo); contarlos todos sería ruido.
  select count(*) into v_triggers
    from pg_trigger t
    join pg_class c on c.oid = t.tgrelid
    join pg_proc  p on p.oid = t.tgfoid
    join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public'
     and c.relname = 'pagos'
     and not t.tgisinternal
     and p.prosrc like '%movimientos_caja%';

  if v_triggers <> 1 then
    raise exception
      'FALLO (5): % triggers de `pagos` escriben en movimientos_caja; debe ser exactamente 1.',
      v_triggers;
  end if;

  if not exists (
    select 1 from pg_trigger t join pg_class c on c.oid = t.tgrelid
     where c.relname = 'pagos' and t.tgname = 'pagos_registrar_ingreso_caja'
  ) then
    raise exception 'FALLO (5): falta el trigger `pagos_registrar_ingreso_caja`.';
  end if;

  if exists (
    select 1 from pg_trigger t join pg_class c on c.oid = t.tgrelid
     where c.relname = 'pagos' and t.tgname = 'tr_pago_a_movimiento_caja'
  ) then
    raise exception
      'FALLO (5): revivió `tr_pago_a_movimiento_caja`: cada cobro se registraría dos veces en la caja.';
  end if;

  raise notice 'OK (5) sólo `pagos_registrar_ingreso_caja` alimenta la caja.';

  -- --------------------------------------------------------------------------
  -- Comprobación de zona horaria: la caja se busca por fecha en la zona de la
  -- clínica, no en UTC. Un cobro a las 21:00 de Santo Domingo (01:00 UTC del
  -- día siguiente) debe seguir cayendo en la caja de hoy.
  -- --------------------------------------------------------------------------
  if (now() at time zone v_zona)::date
     <> ((select fecha from public.cajas where id = v_caja_hoy) at time zone v_zona)::date then
    raise exception
      'FALLO (tz): la caja de hoy no cae en la fecha local de la clínica.';
  end if;

  raise notice 'OK (tz) la caja se resuelve en la zona horaria de la clínica.';
end;
$test$;

rollback;
