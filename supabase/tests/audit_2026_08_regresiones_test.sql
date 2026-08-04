-- ============================================================================
--  Audit del 2 ago 2026 · Regresiones de los defectos reproducidos en vivo.
--
--  Cada bloque vigila un defecto que el audit ejerció con un token real y que
--  la suite anterior no veía. Si alguno vuelve, esto lo dice.
--
--    I1  · recibir una compra respondía 23514 contra su propio CHECK
--    I5  · la compra se creaba en dos escrituras sin transacción
--    I6  · el egreso caía en cualquier caja abierta y siempre como efectivo
--    F1-01 · el cliente podía insertar en `tratamientos_aplicados` de una
--            consulta abierta y el autoguardado anulaba la fila
--    F2-02 · la cantidad ejecutada nunca llegaba a la factura, y un
--            tratamiento a medias se cobraba entero
--    F2-01 · una caja abierta de otro día bloqueaba los cobros de hoy
--    S10   · un pago pendiente que se completaba no entraba en el arqueo
--    F2-04 · anular un pago no revertía su ingreso
--    F3-01 · reprogramar con consulta abierta movía la fecha del expediente
--    F3-04 · un booleano del cliente desactivaba el control de solape
--    F5-04 · un paciente borrado bloqueaba su cédula para siempre
--
--  Cómo ejecutarla (NO deja datos: todo va dentro de una transacción que se
--  revierte):
--
--    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 \
--      -f supabase/tests/audit_2026_08_regresiones_test.sql
--
--  Salida esperada: un `NOTICE  OK ...` por bloque y `ROLLBACK`.
-- ============================================================================

begin;

set local role postgres;

-- ---------------------------------------------------------------------------
-- Fixtures compartidos.
-- ---------------------------------------------------------------------------
do $$
declare
  v_paciente uuid := gen_random_uuid();
  v_doctor   uuid := gen_random_uuid();
  v_sup      uuid;
  v_cons     uuid;
  v_trat     uuid;
begin
  insert into public.personas (id, nombre, apellido, fecha_nacimiento, cedula, estatus)
  values (v_paciente, 'Paciente', 'Audit', date '1990-01-01',
          'AUD-P-' || substr(v_paciente::text, 1, 8), 'activo');
  insert into public.pacientes (id, genero, tipo_paciente)
  values (v_paciente, 'otro', 'integrado');

  insert into public.personas (id, nombre, apellido, fecha_nacimiento, cedula, estatus)
  values (v_doctor, 'Doctora', 'Audit', date '1980-01-01',
          'AUD-D-' || substr(v_doctor::text, 1, 8), 'activo');
  insert into public.usuarios (id, username)
  values (v_doctor, 'aud-' || substr(v_doctor::text, 1, 8));
  insert into public.doctores (id, especialidad)
  values (v_doctor, 'Odontología general');

  insert into public.suplidores (nombre, tipo_suplidor) values ('Suplidor Audit', 'consumible')
  returning id into v_sup;
  insert into public.consumibles (nombre, descripcion, precio, stock_actual, stock_minimo, suplidor_id)
  values ('Insumo Audit', 'Para la prueba', 50, 10, 2, v_sup)
  returning id into v_cons;
  insert into public.tratamientos (nombre, costo, alcance)
  values ('Resina Audit', 12000, 'puntual')
  returning id into v_trat;

  perform set_config('aud.paciente', v_paciente::text, true);
  perform set_config('aud.doctor', v_doctor::text, true);
  perform set_config('aud.suplidor', v_sup::text, true);
  perform set_config('aud.consumible', v_cons::text, true);
  perform set_config('aud.tratamiento', v_trat::text, true);
end $$;

-- ---------------------------------------------------------------------------
-- I1 + I5 + I6 · Compras
-- ---------------------------------------------------------------------------
do $$
declare
  v_compra uuid;
  v_cons   uuid := current_setting('aud.consumible')::uuid;
  v_stock  integer;
  v_caja   uuid;
begin
  select stock_actual into v_stock from public.consumibles where id = v_cons;

  -- I5: cabecera y renglones nacen juntos, y una compra sin renglones no existe.
  begin
    perform public.hfx_base_crear_compra('[]'::jsonb);
    raise exception 'FALLO I5: se creó una compra sin artículos';
  exception when sqlstate '22023' then null;
  end;

  v_compra := public.hfx_base_crear_compra(jsonb_build_array(jsonb_build_object(
    'consumible_id', v_cons,
    'suplidor_id', current_setting('aud.suplidor')::uuid,
    'cantidad', 7,
    'precio_unitario', 100
  )));

  -- I6: el egreso exige la caja de HOY, la misma regla que los cobros.
  begin
    perform public.hfx_base_recibir_compra(v_compra, null, 'transferencia_bancaria');
    raise exception 'FALLO I6: se recibió la compra sin caja abierta de hoy';
  exception when sqlstate 'P0001' then null;
  end;

  -- El seed ya deja una caja abierta hoy; si no la hubiera, se abre.
  select id into v_caja from public.cajas
   where cerrada = false
     and fecha_civil = (current_timestamp at time zone 'America/Santo_Domingo')::date;
  if v_caja is null then
    insert into public.cajas (fecha, monto_apertura, monto_esperado, cerrada)
    values (now(), 1000, 1000, false) returning id into v_caja;
  end if;

  -- I1: antes respondía 23514 · movimientos_stock_consumible_motivo_check.
  perform public.hfx_base_recibir_compra(v_compra, null, 'transferencia_bancaria');

  if (select stock_actual from public.consumibles where id = v_cons) <> v_stock + 7 then
    raise exception 'FALLO I1: el stock no subió por la compra';
  end if;
  if (select estado from public.compras where id = v_compra) <> 'recibida' then
    raise exception 'FALLO I2: la compra quedó en "%"',
      (select estado from public.compras where id = v_compra);
  end if;
  if not exists (
    select 1 from public.movimientos_caja
     where referencia_id = v_compra and tipo = 'egreso'
       and caja_diaria_id = v_caja and metodo_pago = 'transferencia_bancaria'
  ) then
    raise exception 'FALLO I6: el egreso no cayó en la caja de hoy con su método real';
  end if;

  -- Recibirla dos veces no duplica nada.
  begin
    perform public.hfx_base_recibir_compra(v_compra, null, 'efectivo');
    raise exception 'FALLO I1: la compra se recibió dos veces';
  exception when sqlstate '22023' then null;
  end;

  perform set_config('aud.caja', v_caja::text, true);
  raise notice 'OK I1+I5+I6 · compra transaccional, stock +7 y egreso en la caja de hoy con su método';
end $$;

-- ---------------------------------------------------------------------------
-- F1-01 · El cliente no escribe `tratamientos_aplicados` de una consulta abierta
-- ---------------------------------------------------------------------------
do $$
declare
  v_consulta uuid;
  v_odonto   uuid;
  v_diente   uuid;
begin
  insert into public.consultas (paciente_id, doctor_id, fecha, motivo_consulta)
  values (current_setting('aud.paciente')::uuid,
          current_setting('aud.doctor')::uuid, now(), 'Audit F1-01')
  returning id into v_consulta;

  insert into public.odontogramas (consulta_id) values (v_consulta)
  returning id into v_odonto;
  insert into public.dientes (odontograma_id, fdi_code) values (v_odonto, 16)
  returning id into v_diente;

  perform set_config('request.jwt.claims',
    json_build_object('sub', current_setting('aud.doctor'), 'role', 'authenticated')::text,
    true);
  perform set_config('role', 'authenticated', true);

  begin
    insert into public.tratamientos_aplicados (
      tratamiento_id, consulta_id, diente_id, superficie, estado,
      precio_aplicado, cantidad_realizada, doctor_ejecuta_id, fecha_ejecucion
    ) values (
      current_setting('aud.tratamiento')::uuid, v_consulta, v_diente,
      'oclusal', 'completado', 12000, 3,
      current_setting('aud.doctor')::uuid, now()
    );
    perform set_config('role', 'postgres', true);
    raise exception
      'FALLO F1-01: el cliente insertó en una consulta abierta; el siguiente '
      'autoguardado anularía la fila y el procedimiento no se cobraría';
  exception when insufficient_privilege then
    perform set_config('role', 'postgres', true);
  end;

  perform set_config('aud.consulta', v_consulta::text, true);
  perform set_config('aud.diente', v_diente::text, true);
  raise notice 'OK F1-01 · la escritura directa a una consulta abierta se rechaza con 42501';
end $$;

-- ---------------------------------------------------------------------------
-- F2-02 · La cantidad ejecutada llega a la factura; lo que sigue en proceso, no
-- ---------------------------------------------------------------------------
do $$
declare
  v_consulta uuid := current_setting('aud.consulta')::uuid;
  v_diente   uuid := current_setting('aud.diente')::uuid;
  v_cuenta   uuid;
  v_total    numeric;
  v_cant     numeric;
  v_items    integer;
begin
  -- Estas dos filas las escribe el servidor, que es la única vía viva.
  insert into public.tratamientos_aplicados (
    tratamiento_id, consulta_id, diente_id, superficie, estado,
    precio_aplicado, cantidad_realizada, doctor_ejecuta_id, fecha_ejecucion
  ) values (
    current_setting('aud.tratamiento')::uuid, v_consulta, v_diente,
    'oclusal', 'completado', 12000, 3,
    current_setting('aud.doctor')::uuid, now()
  );
  insert into public.tratamientos_aplicados (
    tratamiento_id, consulta_id, diente_id, superficie, estado,
    precio_aplicado, cantidad_realizada, doctor_ejecuta_id, fecha_ejecucion
  ) values (
    current_setting('aud.tratamiento')::uuid, v_consulta, v_diente,
    'mesial', 'en_proceso', 9000, 1,
    current_setting('aud.doctor')::uuid, now()
  );

  v_cuenta := public.hfx_base_finalizar_consulta(v_consulta);
  select monto_total into v_total from public.cuentas where id = v_cuenta;
  select count(*), coalesce(sum(cantidad), 0) into v_items, v_cant
    from public.items_cuenta where cuenta_id = v_cuenta;

  -- 12.000 × 3 sesiones = 36.000. El `en_proceso` no entra: se cobra donde se
  -- termina. Antes salían 21.000 (12.000 + 9.000, ambos con cantidad 1).
  if v_total <> 36000 then
    raise exception 'FALLO F2-02: la cuenta suma % en vez de 36000', v_total;
  end if;
  if v_items <> 1 or v_cant <> 3 then
    raise exception 'FALLO F2-02: % renglón(es) con cantidad total %', v_items, v_cant;
  end if;

  perform set_config('aud.cuenta', v_cuenta::text, true);
  raise notice 'OK F2-02 · tres sesiones se cobran como tres y lo empezado no se cobra';
end $$;

-- ---------------------------------------------------------------------------
-- S10 + F2-04 · El arqueo sigue al pago en las dos direcciones
-- ---------------------------------------------------------------------------
do $$
declare
  v_cuenta uuid := current_setting('aud.cuenta')::uuid;
  v_caja   uuid := current_setting('aud.caja')::uuid;
  v_pago   uuid;
  v_ingresos integer;
begin
  -- S10: un pago que NACE pendiente y se completa después. Antes el trigger era
  -- AFTER INSERT únicamente y este dinero nunca entraba en el arqueo.
  insert into public.pagos (cuenta_id, monto, estado, metodo_pago)
  values (v_cuenta, 5000, 'pendiente', 'efectivo') returning id into v_pago;

  select count(*) into v_ingresos from public.movimientos_caja
   where referencia_id = v_pago and tipo = 'ingreso' and deleted_at is null;
  if v_ingresos <> 0 then
    raise exception 'FALLO: un pago pendiente movió la caja';
  end if;

  update public.pagos set estado = 'completado' where id = v_pago;

  select count(*) into v_ingresos from public.movimientos_caja
   where referencia_id = v_pago and tipo = 'ingreso'
     and caja_diaria_id = v_caja and deleted_at is null;
  if v_ingresos <> 1 then
    raise exception 'FALLO S10: completar el pago no lo llevó al arqueo (% ingresos)', v_ingresos;
  end if;

  -- F2-04: anularlo revierte su ingreso y devuelve la cuenta a su estado real.
  perform public.hfx_base_anular_pago(v_pago, 'prueba de regresión');

  select count(*) into v_ingresos from public.movimientos_caja
   where referencia_id = v_pago and tipo = 'ingreso' and deleted_at is null;
  if v_ingresos <> 0 then
    raise exception 'FALLO F2-04: el ingreso del pago anulado sigue vivo';
  end if;
  if (select estado from public.cuentas where id = v_cuenta) = 'saldada' then
    raise exception 'FALLO F2-04: la cuenta sigue saldada tras anular el pago';
  end if;

  raise notice 'OK S10+F2-04 · el arqueo sigue al pago al completarlo y al anularlo';
end $$;

-- ---------------------------------------------------------------------------
-- F2-01 · Una caja de otro día ya no bloquea el día de hoy
-- ---------------------------------------------------------------------------
do $$
declare v_ayer uuid;
begin
  -- Con el índice global anterior esto era imposible teniendo la de hoy abierta.
  insert into public.cajas (fecha, monto_apertura, monto_esperado, cerrada)
  values (now() - interval '3 days', 500, 500, false)
  returning id into v_ayer;

  if (select count(*) from public.cajas where cerrada = false) < 2 then
    raise exception 'FALLO F2-01: no conviven la caja olvidada y la de hoy';
  end if;

  -- Y dos del MISMO día siguen siendo imposibles.
  begin
    insert into public.cajas (fecha, monto_apertura, monto_esperado, cerrada)
    values (now(), 100, 100, false);
    raise exception 'FALLO F2-01: se abrieron dos cajas el mismo día';
  exception when unique_violation then null;
  end;

  raise notice 'OK F2-01 · una caja olvidada no bloquea el día, y sigue habiendo una por día';
end $$;

-- ---------------------------------------------------------------------------
-- F3-01 + F3-04 · Agenda
-- ---------------------------------------------------------------------------
do $$
declare
  v_cita   uuid;
  v_otra   uuid;
  v_cons   uuid;
  v_fecha  timestamptz;
begin
  insert into public.citas (persona_id, doctor_id, fecha_hora, duracion_minutos, estado)
  values (current_setting('aud.paciente')::uuid, current_setting('aud.doctor')::uuid,
          now() + interval '2 hours', 30, 'confirmada')
  returning id into v_cita;

  insert into public.consultas (paciente_id, doctor_id, cita_id, fecha, motivo_consulta)
  values (current_setting('aud.paciente')::uuid, current_setting('aud.doctor')::uuid,
          v_cita, now() + interval '2 hours', 'Audit F3-01')
  returning id into v_cons;
  select fecha into v_fecha from public.consultas where id = v_cons;

  -- F3-01: con la consulta abierta, reprogramar movía `consultas.fecha` al
  -- futuro y sacaba el expediente del historial de hoy.
  begin
    update public.citas set fecha_hora = now() + interval '30 days' where id = v_cita;
    raise exception 'FALLO F3-01: se reprogramó una cita con consulta abierta';
  exception when sqlstate 'P0001' then null;
  end;

  if (select fecha from public.consultas where id = v_cons) <> v_fecha then
    raise exception 'FALLO F3-01: la fecha clínica se movió igual';
  end if;

  -- F3-04: el solape honesto se rechaza…
  perform set_config('role', 'authenticated', true);
  begin
    insert into public.citas (persona_id, doctor_id, fecha_hora, duracion_minutos, estado)
    values (current_setting('aud.paciente')::uuid, current_setting('aud.doctor')::uuid,
            now() + interval '2 hours', 30, 'programada');
    perform set_config('role', 'postgres', true);
    raise exception 'FALLO: el control de solape no actuó';
  exception when exclusion_violation then null;
  end;
  perform set_config('role', 'postgres', true);

  -- …y encender `es_emergencia` a posteriori ya no lo desactiva.
  insert into public.citas (persona_id, doctor_id, fecha_hora, duracion_minutos, estado)
  values (current_setting('aud.paciente')::uuid, current_setting('aud.doctor')::uuid,
          now() + interval '9 hours', 30, 'programada')
  returning id into v_otra;

  perform set_config('role', 'authenticated', true);
  begin
    update public.citas set es_emergencia = true where id = v_otra;
    perform set_config('role', 'postgres', true);
    raise exception
      'FALLO F3-04: el cliente encendió `es_emergencia` y con ella se sale del '
      'control de solapes sin dejar constancia del motivo';
  exception when insufficient_privilege then
    perform set_config('role', 'postgres', true);
  end;

  raise notice 'OK F3-01+F3-04 · no se reprograma con consulta abierta ni se declara urgencia editando';
end $$;

-- ---------------------------------------------------------------------------
-- F5-04 · La cédula de un paciente borrado se puede reutilizar
-- ---------------------------------------------------------------------------
do $$
declare
  v_uno uuid := gen_random_uuid();
  v_dos uuid := gen_random_uuid();
  v_ced text := 'AUD-CED-' || substr(v_uno::text, 1, 8);
begin
  insert into public.personas (id, nombre, apellido, fecha_nacimiento, cedula, estatus)
  values (v_uno, 'Ficha', 'Por Error', date '1990-01-01', v_ced, 'activo');

  update public.personas set deleted_at = now() where id = v_uno;

  -- Antes: `duplicate key ... personas_cedula_key`, sin salida desde la app.
  insert into public.personas (id, nombre, apellido, fecha_nacimiento, cedula, estatus)
  values (v_dos, 'Ficha', 'Correcta', date '1990-01-01', v_ced, 'activo');

  -- Y dos fichas VIVAS con la misma cédula siguen siendo imposibles.
  begin
    insert into public.personas (id, nombre, apellido, fecha_nacimiento, cedula, estatus)
    values (gen_random_uuid(), 'Ficha', 'Duplicada', date '1990-01-01', v_ced, 'activo');
    raise exception 'FALLO F5-04: se permitió duplicar la cédula de un paciente vivo';
  exception when unique_violation then null;
  end;

  raise notice 'OK F5-04 · la cédula de una ficha borrada se reutiliza; la de una viva, no';
end $$;

rollback;
