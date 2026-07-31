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
  -- El trigger `validar_caja_abierta` rechaza movimientos sobre una caja ya
  -- cerrada, así que hay que reproducir el orden real de la jornada: se abre,
  -- se registran los movimientos y sólo al final se cierra.
  insert into public.cajas (
    fecha, monto_apertura, monto_esperado, monto_real, monto_cierre, cerrada
  ) values (
    (v_hoy - 1)::timestamptz + time '08:30',
    5000, 5000, 0, 0, false
  ) returning id into v_caja_ayer;

  insert into public.movimientos_caja (caja_diaria_id, tipo, monto, descripcion, fecha)
  values
    (v_caja_ayer, 'ingreso', 4800.00, 'Cobro de limpieza y dos resinas',      (v_hoy - 1)::timestamptz + time '10:15'),
    (v_caja_ayer, 'ingreso', 6500.00, 'Cobro de extracción de tercer molar',  (v_hoy - 1)::timestamptz + time '12:40'),
    (v_caja_ayer, 'ingreso', 1000.00, 'Abono a plan de cuotas',               (v_hoy - 1)::timestamptz + time '16:05'),
    (v_caja_ayer, 'egreso',  1500.00, 'Pago a laboratorio dental',            (v_hoy - 1)::timestamptz + time '17:20');

  update public.cajas
     set monto_esperado = 15800, monto_real = 15680, monto_cierre = 15680,
         cerrada = true,
         observaciones = 'Faltante de RD$ 120.00. Se revisa el arqueo de la tarde.'
   where id = v_caja_ayer;

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

-- ============================================================================
--  Usuarios de desarrollo
--
--  El campo de usuario del login muestra `pruebadoctor` como texto de ejemplo
--  (`login_page.dart`), pero nadie lo creaba nunca: el seed no traía usuarios y
--  ese nombre no existía en ninguna base. Quien seguía la pista del formulario
--  se topaba con «credenciales inválidas» sin manera de saber por qué.
--
--    pruebadoctor    / pruebadoctor      · doctor
--    pruebaadmin     / pruebaadmin       · admin (y doctor en todas las capas,
--                                          por HFX-CLIN-000)
--    pruebaasistente / pruebaasistente   · asistente
--
--  El correo tiene que ser `<usuario>@saluddental.com`: la pantalla de login no
--  pide correo sino usuario y compone ese dominio de forma fija
--  (`usuario_repository_impl.dart`).
--
--  La contraseña es igual al usuario **a propósito**, porque esto sólo se
--  ejecuta en el stack local: `supabase db reset` nunca corre contra un
--  proyecto remoto. Estas credenciales no deben sembrarse en un entorno
--  desplegado.
--
--  Idempotente: si ya existen, no hace nada.
-- ============================================================================
do
$usuarios$
declare
  v_instancia uuid := '00000000-0000-0000-0000-000000000000';
  v_actor     record;
begin
  for v_actor in
    select * from (values
      ('11111111-0000-4000-8000-000000000001'::uuid, 'pruebadoctor',
       '{"rol":"doctor","nombre":"Daniel","apellido":"Prueba","fecha_nacimiento":"1985-05-20","cedula":"PRUEBA-DOC","username":"pruebadoctor","especialidad":"Odontología general","telefono":"(809) 555-0201"}'::jsonb),
      ('11111111-0000-4000-8000-000000000002'::uuid, 'pruebaadmin',
       '{"rol":"admin","nombre":"Andrea","apellido":"Prueba","fecha_nacimiento":"1980-11-02","cedula":"PRUEBA-ADM","username":"pruebaadmin","especialidad":"Odontología general","departamento":"Dirección","telefono":"(809) 555-0202"}'::jsonb),
      ('11111111-0000-4000-8000-000000000003'::uuid, 'pruebaasistente',
       '{"rol":"asistente","nombre":"Alicia","apellido":"Prueba","fecha_nacimiento":"1993-07-14","cedula":"PRUEBA-ASI","username":"pruebaasistente","turno":"matutino","telefono":"(809) 555-0203"}'::jsonb)
    ) as t(id, usuario, metadata)
  loop
    if exists (select 1 from auth.users where id = v_actor.id) then
      continue;
    end if;

    -- `handle_new_user` cuelga de `auth.users` y crea persona, usuario y
    -- perfil: basta con insertar aquí con la metadata completa.
    insert into auth.users (
      id, instance_id, aud, role, email, encrypted_password,
      email_confirmed_at, created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change,
      email_change_token_current, phone_change, phone_change_token,
      reauthentication_token,
      raw_app_meta_data, raw_user_meta_data
    ) values (
      v_actor.id, v_instancia, 'authenticated', 'authenticated',
      v_actor.usuario || '@saluddental.com',
      extensions.crypt(v_actor.usuario, extensions.gen_salt('bf')),
      now(), now(), now(),
      '', '', '', '', '', '', '', '',
      '{"provider":"email","providers":["email"]}'::jsonb,
      v_actor.metadata
    );

    -- Sin fila en `auth.identities` el usuario existe pero no tiene con qué
    -- probar que el correo es suyo, y GoTrue rechaza el inicio de sesión.
    insert into auth.identities (
      id, user_id, provider_id, identity_data, provider,
      last_sign_in_at, created_at, updated_at
    ) values (
      gen_random_uuid(), v_actor.id, v_actor.id::text,
      jsonb_build_object('sub', v_actor.id::text,
                         'email', v_actor.usuario || '@saluddental.com',
                         'email_verified', true),
      'email', now(), now(), now()
    );

    raise notice 'seed: usuario % creado (contraseña igual al usuario).', v_actor.usuario;
  end loop;
end;
$usuarios$;
