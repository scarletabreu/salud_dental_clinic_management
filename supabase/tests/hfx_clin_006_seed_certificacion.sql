-- HFX-CLIN-006 · Seed clínico de certificación.
--
-- Reconstruye una clínica completa sobre una base recién reseteada para poder
-- ejecutar una jornada entera —admin que ejerce, doctora, asistente— sin
-- inventar datos por el camino. No contiene información real: todas las cédulas
-- llevan el prefijo `CERT`, los correos el dominio `cert.local` y los nombres
-- son ficticios.
--
-- Es idempotente: si los actores ya existen no vuelve a insertarlos, así que
-- puede ejecutarse dos veces seguidas sin dejar la agenda duplicada.
--
-- Sobre los usuarios: se crean directamente en `auth.users` con la contraseña
-- ya cifrada, para que las jornadas por REST puedan iniciar sesión sin depender
-- de la API de administración. Los campos de token van a cadena vacía y no a
-- nulo: GoTrue los lee como `string` y con nulo devuelve un 500 opaco
-- («Database error querying schema») que parece un fallo de esquema y no lo es.
--
--   psql "$DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/hfx_clin_006_seed_certificacion.sql
--
-- Contraseña de todos los actores: Cert-2026!

begin;

do $seed$
declare
  v_instancia constant uuid := '00000000-0000-0000-0000-000000000000';
  v_password  constant text := 'Cert-2026!';

  -- Actores. UUID fijos para que las jornadas y el informe puedan citarlos.
  v_admin     constant uuid := 'ce470000-0000-4000-8000-000000000001';
  v_doctora   constant uuid := 'ce470000-0000-4000-8000-000000000002';
  v_asistente constant uuid := 'ce470000-0000-4000-8000-000000000003';

  -- Pacientes.
  v_sano       constant uuid := 'ce470000-0000-4000-8000-000000000101';
  v_embarazo   constant uuid := 'ce470000-0000-4000-8000-000000000102';
  v_hiperten   constant uuid := 'ce470000-0000-4000-8000-000000000103';
  v_diabetes   constant uuid := 'ce470000-0000-4000-8000-000000000104';
  v_alergica   constant uuid := 'ce470000-0000-4000-8000-000000000105';
  v_pediatrico constant uuid := 'ce470000-0000-4000-8000-000000000106';
  v_nuevo      constant uuid := 'ce470000-0000-4000-8000-000000000107';
  v_urgencia   constant uuid := 'ce470000-0000-4000-8000-000000000108';

  v_cond_embarazo  uuid;
  v_cond_hiperten  uuid;
  v_cond_diabetes  uuid;
  v_cond_alergia   uuid;

  v_med_amoxicilina uuid;
  v_med_ibuprofeno  uuid;
  v_med_paracetamol uuid;
  v_med_clindamicina uuid;

  v_trat_profilaxis uuid;   -- global
  v_trat_resina     uuid;   -- por pieza
  v_trat_endodoncia uuid;   -- por pieza, cara
  v_trat_extraccion uuid;

  v_diag_caries     uuid;
  v_diag_periodont  uuid;

  v_manana timestamptz;
begin
  if exists (select 1 from public.personas where cedula = 'CERT-ADMIN') then
    raise notice 'HFX-CLIN-006 seed: los actores ya existen, no se reinserta nada.';
    return;
  end if;

  -- =========================================================================
  -- 1 · Actores capaces de iniciar sesión
  -- =========================================================================
  -- `handle_new_user` cuelga de `auth.users` y crea persona, usuario y perfil:
  -- basta con insertar aquí y mandar la metadata completa.
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, phone_change, phone_change_token,
    reauthentication_token,
    raw_app_meta_data, raw_user_meta_data
  )
  select
    a.id, v_instancia, 'authenticated', 'authenticated', a.email,
    extensions.crypt(v_password, extensions.gen_salt('bf')),
    now(), now(), now(),
    '', '', '', '', '', '', '', '',
    '{"provider":"email","providers":["email"]}'::jsonb,
    a.metadata
  from (values
    (v_admin, 'cert.admin@cert.local',
     '{"rol":"admin","nombre":"Alma","apellido":"Dirección","fecha_nacimiento":"1978-04-12","cedula":"CERT-ADMIN","username":"cert_admin","especialidad":"Odontología general","departamento":"Dirección","telefono":"(809) 555-0001"}'::jsonb),
    (v_doctora, 'cert.doctora@cert.local',
     '{"rol":"doctor","nombre":"Delia","apellido":"Clínica","fecha_nacimiento":"1985-09-30","cedula":"CERT-DOCTORA","username":"cert_doctora","especialidad":"Endodoncia","telefono":"(809) 555-0002"}'::jsonb),
    (v_asistente, 'cert.asistente@cert.local',
     '{"rol":"asistente","nombre":"Rita","apellido":"Recepción","fecha_nacimiento":"1995-02-18","cedula":"CERT-ASIST","username":"cert_asistente","turno":"matutino","telefono":"(809) 555-0003"}'::jsonb)
  ) as a(id, email, metadata);

  -- Sin fila en `auth.identities` el usuario existe pero no tiene con qué
  -- probar que el correo es suyo, y algunos flujos de GoTrue lo rechazan.
  insert into auth.identities (
    id, user_id, provider_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  )
  select gen_random_uuid(), u.id, u.id::text,
         jsonb_build_object('sub', u.id::text, 'email', u.email,
                            'email_verified', true),
         'email', now(), now(), now()
    from auth.users u
   where u.id in (v_admin, v_doctora, v_asistente);

  -- =========================================================================
  -- 2 · Catálogo clínico
  -- =========================================================================
  -- Los nombres de las condiciones importan: el motor de alertas las busca por
  -- `lower(nombre) like '%embarazo%'`, `'%hipertensión%'` y `'%diabetes%'`.
  -- Renombrarlas apaga las tres reglas de combinación sin dar ningún error.
  insert into public.condiciones (nombre, tipo, categoria) values
    ('Embarazo',                     'fisiologica', 'temporal'),
    ('Hipertensión arterial',        'patologica',  'cronica'),
    ('Diabetes mellitus tipo 2',     'patologica',  'cronica'),
    ('Alergia a la penicilina',      'alergica',    'cronica');

  select id into v_cond_embarazo from public.condiciones where nombre = 'Embarazo';
  select id into v_cond_hiperten from public.condiciones where nombre = 'Hipertensión arterial';
  select id into v_cond_diabetes from public.condiciones where nombre = 'Diabetes mellitus tipo 2';
  select id into v_cond_alergia  from public.condiciones where nombre = 'Alergia a la penicilina';

  insert into public.medicinas (nombre, principio_activo) values
    ('Amoxicilina 500 mg',  'amoxicilina'),
    ('Ibuprofeno 400 mg',   'ibuprofeno'),
    ('Paracetamol 500 mg',  'paracetamol'),
    ('Clindamicina 300 mg', 'clindamicina');

  select id into v_med_amoxicilina from public.medicinas where nombre = 'Amoxicilina 500 mg';
  select id into v_med_ibuprofeno  from public.medicinas where nombre = 'Ibuprofeno 400 mg';
  select id into v_med_paracetamol from public.medicinas where nombre = 'Paracetamol 500 mg';
  select id into v_med_clindamicina from public.medicinas where nombre = 'Clindamicina 300 mg';

  -- Una absoluta y dos relativas: la certificación necesita comprobar que la
  -- absoluta bloquea y que la relativa deja pasar con justificación.
  insert into public.contraindicaciones (
    medicina_id, condicion_id, descripcion, tipo_contraindicacion, efectos_adversos
  ) values
    (v_med_amoxicilina, v_cond_alergia,
     'Reacción alérgica grave en pacientes alérgicos a la penicilina.',
     'absoluta', '{anafilaxia,reaccion_alergica}'),
    (v_med_ibuprofeno, v_cond_hiperten,
     'Los AINE elevan la presión arterial y reducen el efecto de los antihipertensivos.',
     'relativa', '{arritmia}'),
    (v_med_ibuprofeno, v_cond_embarazo,
     'Desaconsejado en el tercer trimestre.',
     'relativa', '{sangrado_aumentado}');

  insert into public.tratamientos (nombre, descripcion, costo, alcance) values
    ('Profilaxis dental',      'Limpieza completa.',            2500.00, 'global'),
    ('Resina compuesta',       'Restauración por superficie.',  3200.00, 'puntual'),
    ('Endodoncia unirradicular','Tratamiento de conducto.',    12000.00, 'diente'),
    ('Extracción simple',      'Exodoncia no quirúrgica.',      4500.00, 'diente');

  select id into v_trat_profilaxis from public.tratamientos where nombre = 'Profilaxis dental';
  select id into v_trat_resina     from public.tratamientos where nombre = 'Resina compuesta';
  select id into v_trat_endodoncia from public.tratamientos where nombre = 'Endodoncia unirradicular';
  select id into v_trat_extraccion from public.tratamientos where nombre = 'Extracción simple';

  insert into public.diagnosticos (nombre, descripcion, severidad_default, alcance, categoria) values
    ('Caries dental',            'Lesión cariosa activa.',    'moderada', 'puntual', 'caries'),
    ('Periodontitis crónica',    'Pérdida de inserción.',     'grave',    'global',  'periodontitis');

  select id into v_diag_caries    from public.diagnosticos where nombre = 'Caries dental';
  select id into v_diag_periodont from public.diagnosticos where nombre = 'Periodontitis crónica';

  -- Inventario: uno holgado y otro que se agota a la segunda consulta. El
  -- escenario de stock insuficiente necesita que el corte sea alcanzable.
  insert into public.consumibles (nombre, descripcion, stock_actual, stock_minimo, precio) values
    ('Anestesia lidocaína 2%',   'Cartucho.',        120, 20, 85.00),
    ('Guantes de nitrilo (par)', 'Talla M.',         400, 50, 12.00),
    ('Lima endodóntica K-15',    'Uso único.',         2,  5, 240.00),
    ('Gutapercha punta F2',      'Uso único.',         0,  4, 190.00);

  -- =========================================================================
  -- 3 · Pacientes
  -- =========================================================================
  insert into public.personas (id, nombre, apellido, fecha_nacimiento, cedula) values
    (v_sano,       'Sara',   'Sanabria', date '1992-06-11', 'CERT-PAC-001'),
    (v_embarazo,   'Elena',  'Espinal',  date '1994-11-02', 'CERT-PAC-002'),
    (v_hiperten,   'Hugo',   'Herrera',  date '1961-03-27', 'CERT-PAC-003'),
    (v_diabetes,   'Diana',  'Duarte',   date '1968-08-15', 'CERT-PAC-004'),
    (v_alergica,   'Ana',    'Alcántara',date '1987-01-09', 'CERT-PAC-005'),
    (v_pediatrico, 'Pablo',  'Peña',     (now() - interval '8 years')::date, 'CERT-PAC-006'),
    (v_nuevo,      'Nuria',  'Nieves',   date '1999-12-24', 'CERT-PAC-007'),
    (v_urgencia,   'Uriel',  'Ureña',    date '1980-07-07', 'CERT-PAC-008');

  insert into public.pacientes (id, genero, tipo_paciente, peso, altura) values
    (v_sano,       'femenino',  'integrado',  62.0, 165),
    (v_embarazo,   'femenino',  'integrado',  68.5, 162),
    (v_hiperten,   'masculino', 'integrado',  91.0, 174),
    (v_diabetes,   'femenino',  'integrado',  78.0, 158),
    (v_alergica,   'femenino',  'integrado',  55.0, 160),
    -- El pediátrico llega con peso: la regla `PED_PESO_REQUERIDO` exige que se
    -- mida *en la consulta*, así que tener el dato en ficha no la desactiva.
    (v_pediatrico, 'masculino', 'integrado',  26.0, 128),
    (v_nuevo,      'femenino',  'integrado',  null, null),
    (v_urgencia,   'masculino', 'emergencia', null, null);

  insert into public.records (paciente_id, tipo_sangre, historial_familiar)
  select id, 'o_positivo', 'Sin antecedentes relevantes.'
    from (values (v_sano),(v_embarazo),(v_hiperten),(v_diabetes),
                 (v_alergica),(v_pediatrico),(v_nuevo),(v_urgencia)) as p(id);

  -- Las condiciones del expediente son las que el motor cruza con los signos
  -- vitales de la consulta.
  insert into public.record_condicion (record_id, condicion_id, notas, activo)
  select r.id, c.condicion_id, c.notas, true
    from (values
      (v_embarazo, v_cond_embarazo, 'Segundo trimestre.'),
      (v_hiperten, v_cond_hiperten, 'En tratamiento con enalapril.'),
      (v_diabetes, v_cond_diabetes, 'Control con metformina.'),
      (v_alergica, v_cond_alergia,  'Anafilaxia documentada en 2019.')
    ) as c(paciente_id, condicion_id, notas)
    join public.records r on r.paciente_id = c.paciente_id;

  insert into public.contactos (numero_telefono, email)
  select '(809) 555-01' || lpad(n::text, 2, '0'),
         'cert.paciente' || n || '@cert.local'
    from generate_series(1, 8) n;

  insert into public.persona_contactos (persona_id, contacto_id, tipo_contacto, es_principal)
  select p.id, c.id, 'personal', true
    from (
      select unnest(array[v_sano, v_embarazo, v_hiperten, v_diabetes,
                          v_alergica, v_pediatrico, v_nuevo, v_urgencia]) as id,
             generate_series(1, 8) as n
    ) p
    join public.contactos c
      on c.email = 'cert.paciente' || p.n || '@cert.local';

  -- =========================================================================
  -- 4 · Agenda de mañana
  -- =========================================================================
  -- Mañana y no hoy: `citas_sin_solape` cuenta también las citas ya sembradas,
  -- y una agenda en el pasado no permite ensayar la llegada del paciente.
  v_manana := date_trunc('day', now()) + interval '1 day' + interval '8 hours';

  insert into public.citas (persona_id, doctor_id, fecha_hora, duracion_minutos, estado, motivo)
  values
    (v_sano,       v_doctora, v_manana,                       30, 'confirmada', 'Profilaxis semestral'),
    (v_embarazo,   v_doctora, v_manana + interval '30 min',   30, 'confirmada', 'Control de encías'),
    (v_hiperten,   v_doctora, v_manana + interval '60 min',   45, 'confirmada', 'Dolor en molar inferior'),
    (v_diabetes,   v_doctora, v_manana + interval '105 min',  30, 'confirmada', 'Revisión periodontal'),
    (v_alergica,   v_doctora, v_manana + interval '135 min',  30, 'confirmada', 'Absceso periapical'),
    (v_pediatrico, v_doctora, v_manana + interval '165 min',  30, 'confirmada', 'Primera consulta pediátrica'),
    -- El admin ejerce: tiene su propia cita, en su propia agenda.
    (v_sano,       v_admin,   v_manana + interval '4 hours',  30, 'confirmada', 'Segunda opinión');

  raise notice 'HFX-CLIN-006 seed: 3 actores, 8 pacientes, 7 citas y catálogo clínico completo.';
  raise notice 'HFX-CLIN-006 seed: contraseña de los actores = %', v_password;
end;
$seed$;

commit;
