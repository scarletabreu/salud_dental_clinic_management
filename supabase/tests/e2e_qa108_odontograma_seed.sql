-- Casos sintéticos equivalentes a los cinco registros ambiguos de producción.
-- Requiere hfx_clin_006_seed_certificacion.sql y e2e_ui_login_overlay.sql.

begin;
set local role postgres;

do $$
declare
  v_doctor constant uuid := 'ce470000-0000-4000-8000-000000000001';
  v_tratamiento constant uuid := '10810000-0000-4000-8000-000000000001';
  v_diagnostico constant uuid := '10810000-0000-4000-8000-000000000002';
  v_pacientes constant uuid[] := array[
    '10810000-0000-4000-8000-000000000101'::uuid,
    '10810000-0000-4000-8000-000000000102'::uuid,
    '10810000-0000-4000-8000-000000000103'::uuid
  ];
  v_consultas constant uuid[] := array[
    '10810000-0000-4000-8000-000000000201'::uuid,
    '10810000-0000-4000-8000-000000000202'::uuid,
    '10810000-0000-4000-8000-000000000203'::uuid
  ];
  v_odontograma uuid;
  i integer;
begin
  insert into public.tratamientos
    (id, nombre, descripcion, costo, alcance, clave_odontograma)
  values
    (v_tratamiento, 'Empaste de resina',
     'Caso sintético HFX-QA-108.', 1, 'diente', null)
  on conflict (id) do update
    set nombre = excluded.nombre, alcance = excluded.alcance,
        clave_odontograma = excluded.clave_odontograma, deleted_at = null;

  -- Una nueva ejecución del E2E parte de las mismas consultas vacías. Son IDs
  -- reservados para este seed local; nunca coinciden con datos de la clínica.
  delete from public.tratamientos_aplicados
   where consulta_id = any(v_consultas);
  delete from public.diagnosticos_aplicados
   where consulta_id = any(v_consultas);
  update public.dientes
     set tratamientos_aplicados_ids = '{}'::uuid[]
   where odontograma_id in (
     select id from public.odontogramas where consulta_id = any(v_consultas)
   );
  update public.consultas set version = 1
   where id = any(v_consultas);

  insert into public.diagnosticos
    (id, nombre, descripcion, severidad_default, alcance, categoria,
     clave_odontograma)
  values
    (v_diagnostico, 'Cariada', 'Caso sintético HFX-QA-108.',
     'moderada', 'puntual', 'caries', 'cariada')
  on conflict (id) do update
    set nombre = excluded.nombre, alcance = excluded.alcance,
        clave_odontograma = excluded.clave_odontograma, deleted_at = null;

  for i in 1..3 loop
    insert into public.personas
      (id, nombre, apellido, fecha_nacimiento, cedula)
    values
      (v_pacientes[i], 'Caso QA108',
       case i when 1 then 'Caries pieza 36'
              when 2 then 'Caries pieza 15'
              else 'Pieza 71 y empastes' end,
       date '1990-01-01', 'QA108-P-' || i)
    on conflict (id) do nothing;

    insert into public.pacientes (id, genero, tipo_paciente)
    values (v_pacientes[i], 'femenino', 'integrado')
    on conflict (id) do nothing;

    insert into public.records (paciente_id, tipo_sangre, historial_familiar)
    select v_pacientes[i], 'o_positivo', 'Caso sintético sin datos reales.'
     where not exists (
       select 1 from public.records where paciente_id = v_pacientes[i]
     );

    insert into public.consultas
      (id, paciente_id, doctor_id, fecha, motivo_consulta, finalizada)
    values
      (v_consultas[i], v_pacientes[i], v_doctor,
       now() - ((3 - i) || ' minutes')::interval,
       'Reproducción HFX-QA-108', false)
    on conflict (id) do nothing;

    select id into v_odontograma
      from public.odontogramas where consulta_id = v_consultas[i];
    if v_odontograma is null then
      insert into public.odontogramas (consulta_id)
      values (v_consultas[i]) returning id into v_odontograma;
    end if;
    perform public.hfx_clin_008_completar_odontograma(v_odontograma);
  end loop;

  -- El item sin pieza reproduce la vía que originó los dos empastes legacy.
  -- La interfaz actual debe mostrarlo como incompleto y la base debe impedir
  -- que produzca una ejecución de alcance `diente` sin diente.
  insert into public.planes_tratamiento (
    id, paciente_id, consulta_origen_id, doctor_id, estado,
    fecha_propuesta, fecha_aceptacion
  ) values (
    '10810000-0000-4000-8000-000000000301', v_pacientes[3],
    v_consultas[3], v_doctor, 'aceptado', now(), now()
  ) on conflict (id) do nothing;

  insert into public.items_plan_tratamiento (
    id, plan_id, tratamiento_id, diente_id, superficie, estado,
    precio_estimado, orden, doctor_propone_id, fecha_propuesta,
    fecha_aceptacion
  ) values (
    '10810000-0000-4000-8000-000000000302',
    '10810000-0000-4000-8000-000000000301', v_tratamiento,
    null, null, 'aceptado', 1, 1, v_doctor, now(), now()
  ) on conflict (id) do nothing;
end;
$$;

commit;
