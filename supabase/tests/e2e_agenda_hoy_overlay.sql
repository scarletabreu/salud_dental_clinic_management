-- Overlay de agenda para las jornadas E2E de navegador.
--
-- El seed de certificación siembra la agenda **mañana** (para no chocar con
-- `citas_sin_solape` al re-sembrar), pero «Mis Citas del Día» muestra HOY y sin
-- una cita de hoy no hay forma de pulsar «Registrar llegada» → «Iniciar
-- consulta». Este overlay reescribe la agenda al día en curso y reparte las
-- citas entre la doctora y el admin-doctor.
--
-- Además enlaza a la asistente con ambos doctores en `doctor_asistentes`: sin
-- esa fila la asistente inicia sesión correctamente y no ve ninguna cita, que
-- es exactamente el falso «módulo roto» descrito en el informe HFX-CLIN-006.
--
-- Es idempotente y re-ejecutable: borra las citas y las consultas de los
-- pacientes del seed antes de volver a sembrarlas, de modo que cada corrida
-- arranca de la misma agenda.
--
--   psql "$DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/e2e_agenda_hoy_overlay.sql

begin;

do $overlay$
declare
  v_admin     constant uuid := 'ce470000-0000-4000-8000-000000000001';
  v_doctora   constant uuid := 'ce470000-0000-4000-8000-000000000002';
  v_asistente constant uuid := 'ce470000-0000-4000-8000-000000000003';

  v_sano       constant uuid := 'ce470000-0000-4000-8000-000000000101';
  v_embarazo   constant uuid := 'ce470000-0000-4000-8000-000000000102';
  v_hiperten   constant uuid := 'ce470000-0000-4000-8000-000000000103';
  v_diabetes   constant uuid := 'ce470000-0000-4000-8000-000000000104';
  v_alergica   constant uuid := 'ce470000-0000-4000-8000-000000000105';
  v_pediatrico constant uuid := 'ce470000-0000-4000-8000-000000000106';
  v_nuevo      constant uuid := 'ce470000-0000-4000-8000-000000000107';

  v_pacientes uuid[] := array[v_sano, v_embarazo, v_hiperten, v_diabetes,
                              v_alergica, v_pediatrico, v_nuevo];
  v_hoy timestamptz;
  v_consultas uuid[];
begin
  if not exists (select 1 from public.personas where cedula = 'CERT-ADMIN') then
    raise exception 'falta el seed de certificación: corre hfx_clin_006_seed_certificacion.sql primero';
  end if;

  -- 08:00 de HOY en la zona de la clínica, no en la del servidor.
  --
  -- El contenedor de Postgres corre en UTC: `date_trunc('day', now())` cae a
  -- las 20:00 del día anterior en hora local, y la agenda entera aparecía
  -- «mañana» tanto para el cliente como para `registrar_llegada_cita`, que
  -- compara contra `America/Santo_Domingo` y respondía CL015.
  v_hoy := (date_trunc('day', timezone('America/Santo_Domingo', now()))
            + interval '8 hours') at time zone 'America/Santo_Domingo';

  -- ---------------------------------------------------------------------
  -- Limpieza de todo lo que dejó una corrida anterior
  -- ---------------------------------------------------------------------
  -- El orden importa: las consultas cuelgan de la cita, y la pre-factura y sus
  -- renglones cuelgan de la consulta.
  -- Nada de esto cae en cascada: la cadena se cortó a propósito (F5-05 del
  -- audit) para que un borrado no se lleve el expediente entero. Hay que
  -- desmontar la consulta pieza por pieza.
  select array_agg(c.id) into v_consultas
    from public.consultas c
   where c.paciente_id = any(v_pacientes);

  if v_consultas is not null then
    delete from public.pagos
     where cuenta_id in (select id from public.cuentas
                          where consulta_id = any(v_consultas));
    delete from public.items_cuenta
     where cuenta_id in (select id from public.cuentas
                          where consulta_id = any(v_consultas));
    delete from public.cuentas where consulta_id = any(v_consultas);

    delete from public.items_receta
     where receta_id in (select id from public.recetas
                          where consulta_id = any(v_consultas));
    delete from public.recetas             where consulta_id = any(v_consultas);

    -- Lo aplicado apunta al diente, así que va primero: si se borra el diente
    -- antes, la FK `diagnosticos_aplicados_diente_id_fkey` lo impide.
    delete from public.diagnosticos_aplicados    where consulta_id = any(v_consultas);
    delete from public.tratamientos_aplicados    where consulta_id = any(v_consultas);

    delete from public.superficies
     where diente_id in (
       select d.id from public.dientes d
        where d.odontograma_id in (select id from public.odontogramas
                                    where consulta_id = any(v_consultas)));
    delete from public.dientes
     where odontograma_id in (select id from public.odontogramas
                               where consulta_id = any(v_consultas));
    delete from public.odontogramas              where consulta_id = any(v_consultas);
    delete from public.alertas_clinicas          where consulta_id = any(v_consultas);
    delete from public.auditoria_correcciones_clinicas where consulta_id = any(v_consultas);
    delete from public.auditoria_clinica         where consulta_id = any(v_consultas);
    delete from public.condiciones_consulta      where consulta_id = any(v_consultas);
    delete from public.consumos_consulta         where consulta_id = any(v_consultas);
    delete from public.documentos_clinicos       where consulta_id = any(v_consultas);
    delete from public.evaluaciones_clinicas     where consulta_id = any(v_consultas);
    delete from public.ordenes_medicas           where consulta_id = any(v_consultas);
    delete from public.signos_vitales_consulta   where consulta_id = any(v_consultas);
    update public.movimientos_stock_consumible
       set consulta_id = null where consulta_id = any(v_consultas);

    delete from public.consultas where id = any(v_consultas);
  end if;

  delete from public.cuentas where paciente_id = any(v_pacientes);
  delete from public.citas_items_plan
   where cita_id in (select id from public.citas
                      where persona_id = any(v_pacientes));
  delete from public.citas where persona_id = any(v_pacientes);

  -- ---------------------------------------------------------------------
  -- Agenda de hoy
  -- ---------------------------------------------------------------------
  insert into public.citas
    (persona_id, doctor_id, fecha_hora, duracion_minutos, estado, motivo)
  values
    -- Doctora Delia
    (v_sano,     v_doctora, v_hoy,                        30, 'confirmada', 'Profilaxis semestral'),
    (v_embarazo, v_doctora, v_hoy + interval '30 min',    30, 'confirmada', 'Control de encías'),
    (v_hiperten, v_doctora, v_hoy + interval '60 min',    45, 'confirmada', 'Dolor en molar inferior'),
    (v_diabetes, v_doctora, v_hoy + interval '105 min',   30, 'cancelada',  'Revisión periodontal'),
    (v_alergica, v_doctora, v_hoy + interval '135 min',   30, 'confirmada', 'Absceso periapical'),
    -- Admin que ejerce: la pediátrica y una de control
    (v_pediatrico, v_admin, v_hoy + interval '60 min',    30, 'confirmada', 'Primera consulta pediátrica'),
    (v_nuevo,      v_admin, v_hoy + interval '120 min',   30, 'confirmada', 'Evaluación inicial');

  -- ---------------------------------------------------------------------
  -- Acceso del doctor a sus pacientes  ·  ATENCIÓN: tapa un defecto real
  -- ---------------------------------------------------------------------
  -- `pacientes_select` exige `puede_ver_paciente(id)`, que para un doctor que
  -- no es admin pide una fila ACTIVA en `doctor_paciente`. Esa fila sólo la
  -- crea `fn_autoasignar_doctor_paciente`, un trigger de `consultas`.
  --
  -- Pero la pantalla de consulta lee `pacientes` ANTES de crear la consulta
  -- (`esPersonaSinFichaClinica`), así que con un paciente que el doctor nunca
  -- ha atendido: la lectura vuelve vacía → el cliente cree que la persona no
  -- tiene ficha → intenta crearla → `42501` → la pantalla se queda en un
  -- indicador de carga permanente, sin un solo texto. La consulta no puede
  -- nacer, y sin consulta la fila de acceso nunca se crea: bloqueo circular.
  --
  -- Se siembra aquí para poder ejercitar el resto de la jornada. Cuando el
  -- defecto se corrija, esta sección debe desaparecer.
  insert into public.doctor_paciente (doctor_id, paciente_id, asignado_por, motivo)
  select v_doctora, p.id, v_admin, 'arnés E2E: acceso previo a la primera consulta'
    from unnest(v_pacientes) as p(id)
   where not exists (
     select 1 from public.doctor_paciente dp
      where dp.doctor_id = v_doctora and dp.paciente_id = p.id and dp.activo);

  -- ---------------------------------------------------------------------
  -- Un suplidor: sin él no se puede registrar una compra desde la interfaz
  -- ---------------------------------------------------------------------
  insert into public.suplidores (nombre, tipo_suplidor, summary)
  select 'Depósito Dental E2E', 'consumible', 'Suplidor de prueba del arnés E2E'
   where not exists (
     select 1 from public.suplidores where nombre = 'Depósito Dental E2E');

  -- ---------------------------------------------------------------------
  -- La asistente tiene que estar asignada a los doctores que apoya
  -- ---------------------------------------------------------------------
  insert into public.doctor_asistentes (doctor_id, asistente_id)
  select d.id, v_asistente
    from (values (v_admin), (v_doctora)) as d(id)
   where not exists (
     select 1 from public.doctor_asistentes da
      where da.doctor_id = d.id and da.asistente_id = v_asistente);

  raise notice 'overlay: agenda de hoy sembrada (5 citas de la doctora, 2 del admin) y asistente enlazada';
end;
$overlay$;

commit;
