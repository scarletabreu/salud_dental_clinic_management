-- HFX-CLIN-002 · persistencia y cierre clínico transaccional.
-- Se ejecuta tras `supabase db reset` y revierte todos sus datos.

begin;
set local role postgres;

do $$
declare
  v_doc_a      uuid := '30000000-0000-4000-8000-000000000001';
  v_doc_b      uuid := '30000000-0000-4000-8000-000000000002';
  v_paciente   uuid := '30000000-0000-4000-8000-000000000010';
  v_cita       uuid;
  v_cita_2     uuid;
  v_consulta   uuid;
  v_consulta_2 uuid;
  v_odontograma uuid;
  v_diente     uuid;
  v_tratamiento uuid;
  v_diagnostico uuid;
  v_consumible uuid;
  v_escaso     uuid;
begin
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    created_at, updated_at, raw_user_meta_data
  ) values
  (v_doc_a, '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'hfx002-a@test.local', 'x', now(), now(),
   '{"rol":"doctor","nombre":"Delia","apellido":"Autora","fecha_nacimiento":"1981-01-01","cedula":"HFX002-D1","username":"hfx002_d1","especialidad":"General"}'),
  (v_doc_b, '00000000-0000-0000-0000-000000000000', 'authenticated',
   'authenticated', 'hfx002-b@test.local', 'x', now(), now(),
   '{"rol":"doctor","nombre":"Darío","apellido":"Ajeno","fecha_nacimiento":"1982-01-01","cedula":"HFX002-D2","username":"hfx002_d2","especialidad":"General"}');

  insert into public.personas (id, nombre, apellido, fecha_nacimiento, cedula)
  values (v_paciente, 'Petra', 'Paciente', date '1995-01-01', 'HFX002-P');
  insert into public.pacientes(id, genero) values (v_paciente, 'femenino');

  -- Nacen `en_consulta` porque su consulta ya está abierta: desde HFX-CLIN-004
  -- el grafo de estados vive en la base y cerrar una cita que nunca recibió al
  -- paciente sería una transición imposible.
  insert into public.citas(persona_id, doctor_id, fecha_hora, duracion_minutos, estado)
  values (v_paciente, v_doc_a, now() + interval '1 day', 30, 'en_consulta')
  returning id into v_cita;
  insert into public.citas(persona_id, doctor_id, fecha_hora, duracion_minutos, estado)
  values (v_paciente, v_doc_a, now() + interval '2 day', 30, 'en_consulta')
  returning id into v_cita_2;

  insert into public.consultas(paciente_id, doctor_id, cita_id, fecha)
  values (v_paciente, v_doc_a, v_cita, now())
  returning id into v_consulta;
  insert into public.consultas(paciente_id, doctor_id, cita_id, fecha)
  values (v_paciente, v_doc_a, v_cita_2, now())
  returning id into v_consulta_2;

  insert into public.odontogramas(consulta_id) values (v_consulta)
  returning id into v_odontograma;
  insert into public.dientes(odontograma_id, fdi_code) values (v_odontograma, 16)
  returning id into v_diente;

  insert into public.tratamientos(nombre, costo, alcance)
  -- Puntual: se ejecuta sobre una cara, y el payload de la prueba manda la
  -- superficie. Desde HFX-CLIN-003 la base exige que ambos concuerden.
  values ('Resina HFX002', 1500, 'puntual') returning id into v_tratamiento;
  insert into public.diagnosticos(nombre, alcance, categoria)
  values ('Caries HFX002', 'puntual', 'caries') returning id into v_diagnostico;

  insert into public.consumibles(nombre, stock_actual, stock_minimo, precio)
  values ('Gasas HFX002', 20, 2, 25) returning id into v_consumible;
  insert into public.consumibles(nombre, stock_actual, stock_minimo, precio)
  values ('Anestesia HFX002', 1, 1, 300) returning id into v_escaso;

  perform set_config('hfx002.doc_a', v_doc_a::text, true);
  perform set_config('hfx002.doc_b', v_doc_b::text, true);
  perform set_config('hfx002.paciente', v_paciente::text, true);
  perform set_config('hfx002.cita', v_cita::text, true);
  perform set_config('hfx002.consulta', v_consulta::text, true);
  perform set_config('hfx002.consulta_2', v_consulta_2::text, true);
  perform set_config('hfx002.tratamiento', v_tratamiento::text, true);
  perform set_config('hfx002.diagnostico', v_diagnostico::text, true);
  perform set_config('hfx002.consumible', v_consumible::text, true);
  perform set_config('hfx002.escaso', v_escaso::text, true);
end;
$$;

-- ---------------------------------------------------------------------------
-- 1 · Una cita no admite dos consultas vigentes.
-- ---------------------------------------------------------------------------
do $$
begin
  begin
    insert into public.consultas(paciente_id, doctor_id, cita_id, fecha)
    values (
      current_setting('hfx002.paciente')::uuid,
      current_setting('hfx002.doc_a')::uuid,
      current_setting('hfx002.cita')::uuid,
      now()
    );
    raise exception 'la cita aceptó una segunda consulta vigente';
  exception when unique_violation then null;
  end;
  raise notice 'OK 1 · una cita solo tiene una consulta vigente';
end;
$$;

-- ---------------------------------------------------------------------------
-- 2 · El borrador es atómico, identifica lo guardado y versiona.
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('hfx002.doc_a'), 'role', 'authenticated')::text,
  true
);

do $$
declare
  v_out jsonb;
  v_trat uuid;
  v_diag uuid;
  v_receta uuid;
  v_version integer;
begin
  v_out := public.guardar_borrador_consulta(
    current_setting('hfx002.consulta')::uuid,
    1,
    jsonb_build_object(
      'notas', 'Molestia al masticar.',
      'signos_vitales', jsonb_build_object('pulso', 72),
      'dientes', jsonb_build_array(jsonb_build_object(
        'fdi_code', 16,
        'esta_ausente', false,
        'observaciones', 'Sensibilidad oclusal',
        'tratamientos', jsonb_build_array(jsonb_build_object(
          'tratamiento_id', current_setting('hfx002.tratamiento'),
          'superficie', 'oclusal',
          'precio_aplicado', 1500,
          'estado', 'aplicado',
          'notas', 'Resina simple'
        )),
        'diagnosticos', jsonb_build_array(jsonb_build_object(
          'diagnosis_id', current_setting('hfx002.diagnostico'),
          'severidad', 'moderada',
          'superficie', 'oclusal',
          'origen', 'diagnosticado_hoy'
        ))
      )),
      'recetas', jsonb_build_array(jsonb_build_object(
        -- Renglón estructurado (HFX-CLIN-003): la emisión exige dosis, vía,
        -- frecuencia, duración y una cantidad coherente con ellas.
        'items_receta', jsonb_build_array(jsonb_build_object(
          'nombre_medicamento', 'Ibuprofeno',
          'dosis', '400 mg',
          'dosis_cantidad', 1,
          'dosis_unidad', 'tableta',
          'via_administracion', 'oral',
          'frecuencia_horas', 8,
          'duracion_dias', 5,
          'cantidad_total', 15
        ))
      )),
      'insumos', jsonb_build_array(
        jsonb_build_object('consumible_id', current_setting('hfx002.consumible'),
                           'nombre', 'Gasas HFX002', 'cantidad', 2),
        -- el formulario permite repetir un consumible: debe agregarse
        jsonb_build_object('consumible_id', current_setting('hfx002.consumible'),
                           'nombre', 'Gasas HFX002', 'cantidad', 3)
      )
    )
  );

  if (v_out ->> 'version')::integer <> 2 then
    raise exception 'el borrador no incrementó la versión: %', v_out ->> 'version';
  end if;

  v_trat := ((v_out -> 'dientes' -> 0 -> 'tratamientos') ->> 0)::uuid;
  v_diag := ((v_out -> 'dientes' -> 0 -> 'diagnosticos') ->> 0)::uuid;
  if v_trat is null or v_diag is null then
    raise exception 'el borrador no devolvió los ids confirmados: %', v_out;
  end if;

  -- Lo visible en la pantalla es lo que quedó en la base: pieza, cara y notas.
  perform 1 from public.diagnosticos_aplicados
   where id = v_diag and superficie = 'oclusal'::tipo_superficie
     and origen = 'diagnosticado_hoy' and deleted_at is null;
  if not found then raise exception 'el hallazgo no conservó su cara ni su origen'; end if;

  perform 1 from public.dientes
   where fdi_code = 16 and observaciones = 'Sensibilidad oclusal'
     and v_trat = any (tratamientos_aplicados_ids);
  if not found then raise exception 'la pieza no quedó sellada con su tratamiento'; end if;

  select id, version into v_receta, v_version from public.recetas
   where consulta_id = current_setting('hfx002.consulta')::uuid and deleted_at is null;
  if v_receta is null then raise exception 'la receta borrador no se guardó'; end if;
  if (select estado from public.recetas where id = v_receta) <> 'borrador' then
    raise exception 'la receta nació emitida en vez de borrador';
  end if;

  if (select cantidad from public.consumos_consulta
       where consulta_id = current_setting('hfx002.consulta')::uuid
         and deleted_at is null) <> 5 then
    raise exception 'el consumible repetido no se agregó';
  end if;

  perform set_config('hfx002.trat', v_trat::text, true);
  perform set_config('hfx002.diag', v_diag::text, true);
  perform set_config('hfx002.receta', v_receta::text, true);
  raise notice 'OK 2 · el borrador guarda, identifica y versiona en una operación';
end;
$$;

-- ---------------------------------------------------------------------------
-- 3 · Versión obsoleta: conflicto accionable, sin escribir nada.
-- ---------------------------------------------------------------------------
do $$
declare
  v_notas text;
begin
  begin
    perform public.guardar_borrador_consulta(
      current_setting('hfx002.consulta')::uuid,
      1,
      jsonb_build_object('notas', 'escritura con versión vieja')
    );
    raise exception 'una versión obsoleta pudo guardar';
  exception when sqlstate 'CL001' then null;
  end;

  select notas into v_notas from public.consultas
   where id = current_setting('hfx002.consulta')::uuid;
  if v_notas <> 'Molestia al masticar.' then
    raise exception 'el conflicto de versión dejó rastro: %', v_notas;
  end if;
  raise notice 'OK 3 · el conflicto de versión no escribe nada';
end;
$$;

-- ---------------------------------------------------------------------------
-- 4 · Un fallo de receta no borra la receta anterior.
-- ---------------------------------------------------------------------------
do $$
declare
  v_items jsonb;
begin
  begin
    perform public.guardar_borrador_consulta(
      current_setting('hfx002.consulta')::uuid,
      null,
      jsonb_build_object('recetas', jsonb_build_array(
        jsonb_build_object(
          'id', current_setting('hfx002.receta'),
          'items_receta', jsonb_build_array(jsonb_build_object('nombre_medicamento', 'Amoxicilina'))
        ),
        -- receta inexistente: la operación completa debe fallar
        jsonb_build_object('id', '00000000-0000-4000-8000-0000000000ff',
                           'items_receta', '[]'::jsonb)
      ))
    );
    raise exception 'una receta ajena pasó la validación';
  exception when sqlstate 'CL004' then null;
  end;

  select items_receta into v_items from public.recetas
   where id = current_setting('hfx002.receta')::uuid and deleted_at is null;
  if v_items is null then raise exception 'la receta previa desapareció tras el fallo'; end if;
  if v_items -> 0 ->> 'nombre_medicamento' <> 'Ibuprofeno' then
    raise exception 'la receta previa quedó a medio escribir: %', v_items;
  end if;
  raise notice 'OK 4 · un guardado fallido no borra la receta persistida';
end;
$$;

-- ---------------------------------------------------------------------------
-- 5 · Stock insuficiente revierte el cierre completo.
-- ---------------------------------------------------------------------------
do $$
declare
  v_stock integer;
begin
  perform public.guardar_borrador_consulta(
    current_setting('hfx002.consulta')::uuid,
    null,
    jsonb_build_object('insumos', jsonb_build_array(
      jsonb_build_object('consumible_id', current_setting('hfx002.consumible'),
                         'nombre', 'Gasas HFX002', 'cantidad', 5),
      jsonb_build_object('consumible_id', current_setting('hfx002.escaso'),
                         'nombre', 'Anestesia HFX002', 'cantidad', 4)
    ))
  );

  begin
    perform public.cerrar_consulta(
      current_setting('hfx002.consulta')::uuid, null, '{}'::jsonb, 'intento-1'
    );
    raise exception 'el cierre aceptó consumir más stock del existente';
  exception when sqlstate 'CL003' then null;
  end;

  if (select finalizada from public.consultas
       where id = current_setting('hfx002.consulta')::uuid) then
    raise exception 'la consulta quedó finalizada pese al fallo de stock';
  end if;

  select stock_actual into v_stock from public.consumibles
   where id = current_setting('hfx002.consumible')::uuid;
  if v_stock <> 20 then
    raise exception 'el cierre fallido descontó inventario: quedan %', v_stock;
  end if;

  if exists (select 1 from public.cuentas
              where consulta_id = current_setting('hfx002.consulta')::uuid) then
    raise exception 'el cierre fallido creó una cuenta';
  end if;
  raise notice 'OK 5 · stock insuficiente revierte todo el cierre';
end;
$$;

-- ---------------------------------------------------------------------------
-- 6 · Cierre confirmado: una transacción, una cuenta, un movimiento.
-- ---------------------------------------------------------------------------
do $$
declare
  v_out jsonb;
  v_stock integer;
begin
  perform public.guardar_borrador_consulta(
    current_setting('hfx002.consulta')::uuid,
    null,
    jsonb_build_object('insumos', jsonb_build_array(
      jsonb_build_object('consumible_id', current_setting('hfx002.consumible'),
                         'nombre', 'Gasas HFX002', 'cantidad', 5)
    ))
  );

  v_out := public.cerrar_consulta(
    current_setting('hfx002.consulta')::uuid, null, '{}'::jsonb, 'cierre-ok'
  );

  if not (v_out ->> 'finalizada')::boolean then
    raise exception 'el cierre no marcó la consulta como finalizada';
  end if;
  if v_out ->> 'cuenta_id' is null then
    raise exception 'el cierre no generó pre-factura';
  end if;
  if (v_out ->> 'monto_total')::numeric <> 1500 then
    raise exception 'la cuenta no facturó el tratamiento ejecutado: %', v_out ->> 'monto_total';
  end if;
  if v_out ->> 'cita_estado' <> 'completada' then
    raise exception 'la cita no quedó completada: %', v_out ->> 'cita_estado';
  end if;

  select stock_actual into v_stock from public.consumibles
   where id = current_setting('hfx002.consumible')::uuid;
  if v_stock <> 15 then
    raise exception 'el stock no refleja el consumo: %', v_stock;
  end if;

  if (select estado from public.recetas
       where id = current_setting('hfx002.receta')::uuid) <> 'emitida' then
    raise exception 'la receta no se emitió al cerrar';
  end if;

  if not exists (select 1 from public.auditoria_clinica
                  where consulta_id = current_setting('hfx002.consulta')::uuid
                    and evento = 'consulta_cerrada') then
    raise exception 'el cierre no dejó auditoría';
  end if;
  raise notice 'OK 6 · el cierre confirma consulta, cita, stock, cuenta y receta';
end;
$$;

-- ---------------------------------------------------------------------------
-- 7 · Reintentar el mismo cierre devuelve el resultado, sin repetir efectos.
-- ---------------------------------------------------------------------------
do $$
declare
  v_out jsonb;
  v_cuentas integer;
  v_movimientos integer;
  v_stock integer;
begin
  v_out := public.cerrar_consulta(
    current_setting('hfx002.consulta')::uuid, null, '{}'::jsonb, 'cierre-ok'
  );

  select count(*) into v_cuentas from public.cuentas
   where consulta_id = current_setting('hfx002.consulta')::uuid and deleted_at is null;
  select count(*) into v_movimientos from public.movimientos_stock_consumible
   where consulta_id = current_setting('hfx002.consulta')::uuid;
  select stock_actual into v_stock from public.consumibles
   where id = current_setting('hfx002.consumible')::uuid;

  if v_cuentas <> 1 then raise exception 'el reintento duplicó la cuenta (%)', v_cuentas; end if;
  if v_movimientos <> 1 then raise exception 'el reintento duplicó el movimiento (%)', v_movimientos; end if;
  if v_stock <> 15 then raise exception 'el reintento volvió a descontar inventario: %', v_stock; end if;
  if v_out ->> 'cuenta_id' is null then raise exception 'el reintento no devolvió la cuenta'; end if;
  raise notice 'OK 7 · reintentar el cierre es idempotente';
end;
$$;

-- ---------------------------------------------------------------------------
-- 8 · Una consulta finalizada no se edita como borrador ni se reescribe su receta.
-- ---------------------------------------------------------------------------
do $$
declare
  v_count integer;
begin
  begin
    perform public.guardar_borrador_consulta(
      current_setting('hfx002.consulta')::uuid,
      null,
      jsonb_build_object('notas', 'edición después del cierre')
    );
    raise exception 'se editó el borrador de una consulta finalizada';
  exception when sqlstate 'CL002' then null;
  end;

  -- Primera barrera: RLS ya no considera editable una consulta cerrada.
  update public.recetas
     set items_receta = '[{"nombre_medicamento":"Otro"}]'::jsonb
   where id = current_setting('hfx002.receta')::uuid;
  get diagnostics v_count = row_count;
  if v_count <> 0 then raise exception 'RLS permitió tocar la receta de una consulta cerrada'; end if;
  raise notice 'OK 8 · el cierre es inmutable para el borrador y para su receta';
end;
$$;

-- ---------------------------------------------------------------------------
-- 8b · Segunda barrera: una receta emitida es inmutable aunque su consulta
--      siga abierta y RLS deje pasar la escritura.
-- ---------------------------------------------------------------------------
do $$
declare
  v_receta uuid;
begin
  v_receta := ((public.guardar_borrador_consulta(
    current_setting('hfx002.consulta_2')::uuid,
    null,
    jsonb_build_object('recetas', jsonb_build_array(jsonb_build_object(
      'items_receta', jsonb_build_array(jsonb_build_object('nombre_medicamento', 'Ibuprofeno'))
    )))
  ) -> 'recetas' -> 0) ->> 'id')::uuid;

  update public.recetas set estado = 'emitida', emitida_at = now() where id = v_receta;

  begin
    update public.recetas
       set items_receta = '[{"nombre_medicamento":"Otro"}]'::jsonb
     where id = v_receta;
    raise exception 'se reescribió una receta emitida';
  exception when sqlstate 'CL005' then null;
  end;

  begin
    update public.recetas set deleted_at = now() where id = v_receta;
    raise exception 'se borró lógicamente una receta emitida';
  exception when sqlstate 'CL005' then null;
  end;

  begin
    delete from public.recetas where id = v_receta;
    raise exception 'se borró una receta emitida';
  exception when sqlstate 'CL005' then null;
  end;

  -- Anular sí es una vía legítima y conserva el documento original.
  update public.recetas
     set estado = 'anulada', motivo_anulacion = 'Corrección de dosis'
   where id = v_receta;

  if (select items_receta -> 0 ->> 'nombre_medicamento' from public.recetas where id = v_receta)
     <> 'Ibuprofeno' then
    raise exception 'la anulación alteró el contenido de la receta original';
  end if;
  raise notice 'OK 8b · una receta emitida solo se anula o se reemplaza';
end;
$$;

-- ---------------------------------------------------------------------------
-- 8c · Una evaluación sin ejecución cierra sin pre-factura, pero completa la
--      cita: cobrar cero es ruido y el plan no factura por sí mismo.
-- ---------------------------------------------------------------------------
do $$
declare
  v_out jsonb;
begin
  v_out := public.cerrar_consulta(
    current_setting('hfx002.consulta_2')::uuid, null, '{}'::jsonb, 'evaluacion-1'
  );

  if v_out ->> 'cuenta_id' is not null then
    raise exception 'una evaluación sin ejecución generó pre-factura';
  end if;
  if v_out ->> 'cita_estado' <> 'completada' then
    raise exception 'la cita de la evaluación no quedó completada: %', v_out ->> 'cita_estado';
  end if;
  if not (select finalizada from public.consultas
           where id = current_setting('hfx002.consulta_2')::uuid) then
    raise exception 'la evaluación no quedó finalizada';
  end if;
  raise notice 'OK 8c · una evaluación sin ejecución cierra sin cobrar';
end;
$$;

-- ---------------------------------------------------------------------------
-- 9 · Un doctor ajeno no guarda ni cierra la consulta de otro.
-- ---------------------------------------------------------------------------
select set_config(
  'request.jwt.claims',
  json_build_object('sub', current_setting('hfx002.doc_b'), 'role', 'authenticated')::text,
  true
);
do $$
begin
  begin
    perform public.guardar_borrador_consulta(
      current_setting('hfx002.consulta_2')::uuid,
      null,
      jsonb_build_object('notas', 'firma ajena')
    );
    raise exception 'un doctor ajeno guardó el borrador';
  exception when insufficient_privilege then null;
  end;

  begin
    perform public.cerrar_consulta(current_setting('hfx002.consulta_2')::uuid);
    raise exception 'un doctor ajeno cerró la consulta';
  exception when insufficient_privilege then null;
  end;
  raise notice 'OK 9 · la autoría clínica no se transfiere por conocer el UUID';
end;
$$;

-- ---------------------------------------------------------------------------
-- 10 · Anon no alcanza ninguna de las dos operaciones.
-- ---------------------------------------------------------------------------
set local role postgres;
do $$
begin
  if has_function_privilege(
      'anon', 'public.guardar_borrador_consulta(uuid,integer,jsonb)', 'execute') then
    raise exception 'anon conserva guardar_borrador_consulta';
  end if;
  if has_function_privilege(
      'anon', 'public.cerrar_consulta(uuid,integer,jsonb,text,text,text)', 'execute') then
    raise exception 'anon conserva cerrar_consulta';
  end if;
  if has_function_privilege(
      'authenticated', 'public.hfx_clin_002_aplicar_borrador(uuid,uuid,jsonb)', 'execute') then
    raise exception 'authenticated alcanza la función base del borrador';
  end if;
  raise notice 'OK 10 · el contrato de grants de HFX-CLIN-001 se mantiene';
end;
$$;

rollback;
