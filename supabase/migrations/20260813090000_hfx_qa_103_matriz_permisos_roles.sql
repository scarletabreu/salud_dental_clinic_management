-- HFX-QA-103 · La matriz de permisos por rol que fijó QA, impuesta por la base.
--
-- Hasta aquí la matriz vivía en la cabeza de quien la acordó: ni el cliente ni
-- el SQL la imponían. Esta migración pone la mitad que corresponde a la base;
-- la UI oculta, pero es RLS quien decide.
--
-- Cubre los defectos D8, D11 y D12 de la jornada del 1 ago 2026.

-- ---------------------------------------------------------------------------
-- D8 · Los catálogos clínicos son de sólo lectura para el doctor
-- ---------------------------------------------------------------------------
-- El doctor los consulta para trabajar; crearlos, cambiarles el precio y
-- retirarlos es administración. Se tocan **sólo** los catálogos: las tablas
-- `*_aplicados` son clínicas y siguen siendo del doctor, que es quien
-- diagnostica y trata.

do $$
declare
  v_tabla text;
begin
  foreach v_tabla in array array[
    'tratamientos', 'procedimientos', 'diagnosticos', 'medicinas'
  ] loop
    execute format('drop policy if exists %I on public.%I', v_tabla || '_insert', v_tabla);
    execute format(
      'create policy %I on public.%I for insert with check (public.es_admin())',
      v_tabla || '_insert', v_tabla
    );

    execute format('drop policy if exists %I on public.%I', v_tabla || '_update', v_tabla);
    execute format(
      'create policy %I on public.%I for update using (public.es_admin()) with check (public.es_admin())',
      v_tabla || '_update', v_tabla
    );

    execute format('drop policy if exists %I on public.%I', v_tabla || '_delete', v_tabla);
    execute format(
      'create policy %I on public.%I for delete using (public.es_admin())',
      v_tabla || '_delete', v_tabla
    );

    -- El SELECT no se toca: el doctor necesita leer el catálogo para poder
    -- registrar lo que hace.
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- D11 · El doctor ve todas las consultas — TEMPORAL
-- ---------------------------------------------------------------------------
-- TEMPORAL (QA 1-ago): revertir cuando Isaac entregue el modelo definitivo.
--
-- La escritura NO se toca: `consulta_insert` y `consulta_update` siguen atadas
-- al doctor firmante, y las RPC clínicas también. Esto abre la **lectura**.

drop policy if exists consulta_select on public.consultas;
create policy consulta_select on public.consultas
  for select using (public.es_admin() or public.es_doctor());

comment on policy consulta_select on public.consultas is
  'TEMPORAL (QA 1-ago-2026): cualquier doctor lee cualquier consulta. Revertir a (es_admin() OR doctor_id = auth.uid()) cuando se entregue el modelo definitivo de alcance clínico.';

-- `puede_ver_consulta` propaga ese alcance a todo lo que cuelga de una
-- consulta —recetas, consumos, signos vitales, odontogramas—; sin ella el
-- expediente se abriría a medias: la consulta visible y su contenido no.
create or replace function public.puede_ver_consulta(p_consulta_id uuid)
returns boolean
language sql stable security definer
set search_path to 'public'
as $$
  -- TEMPORAL (QA 1-ago): revertir cuando Isaac entregue el modelo definitivo.
  select public.es_admin() or public.es_doctor() or exists (
    select 1 from public.consultas c
     where c.id = p_consulta_id
       and c.deleted_at is null
       and c.doctor_id = auth.uid()
  );
$$;

comment on function public.puede_ver_consulta(uuid) is
  'Encadena hasta puede_ver_paciente() para tablas colgadas de consultas. TEMPORAL (QA 1-ago-2026): mientras dure la decisión D11, cualquier doctor pasa.';

revoke all on function public.puede_ver_consulta(uuid) from public;
grant all on function public.puede_ver_consulta(uuid) to authenticated;
grant all on function public.puede_ver_consulta(uuid) to service_role;

-- ---------------------------------------------------------------------------
-- D12 · El asistente sólo alcanza a los doctores que tiene asignados
-- ---------------------------------------------------------------------------
-- El recorte por `doctor_asistentes` existía sólo en memoria
-- (`cita_cubit.dart`), que es decoración: la API devolvía la agenda entera a
-- cualquier asistente.

create or replace function public.asiste_a_doctor(p_doctor_id uuid)
returns boolean
language sql stable security definer
set search_path to 'public'
as $$
  select exists (
    select 1 from public.doctor_asistentes da
     where da.asistente_id = auth.uid()
       and da.doctor_id = p_doctor_id
  );
$$;

comment on function public.asiste_a_doctor(uuid) is
  'true si quien consulta es asistente asignado a ese doctor. Es el alcance de la agenda de una asistente: lo administrativo de los doctores a los que asiste, y de nadie más.';

revoke all on function public.asiste_a_doctor(uuid) from public;
grant all on function public.asiste_a_doctor(uuid) to authenticated;
grant all on function public.asiste_a_doctor(uuid) to service_role;

drop policy if exists citas_select on public.citas;
create policy citas_select on public.citas
  for select using (
    public.es_admin()
    or (public.es_doctor() and doctor_id = auth.uid())
    or (public.es_asistente() and public.asiste_a_doctor(doctor_id))
  );

-- ---------------------------------------------------------------------------
-- D12 · Matriz de transiciones de estado de cita
-- ---------------------------------------------------------------------------
-- Quién puede llevar una cita de un estado a otro. Los estados clínicos
-- (`enConsulta`, `completada`) no salen del desplegable: los produce una RPC
-- SECURITY DEFINER, así que la policy de UPDATE se los niega a todos y sigue
-- funcionando igual.
--
--   | Transición                          | Admin | Doctor (su cita) | Asistente |
--   |-------------------------------------|-------|------------------|-----------|
--   | programada → confirmada             |   ✔   |        —         |     ✔     |
--   | programada/confirmada → en_espera   |   ✔   |        ✔         |     ✔     |
--
-- Reprogramar no está en la tabla porque no es un cambio de estado: es mover
-- la fecha y la hora, y el trigger deja pasar cualquier escritura que no toque
-- `estado` (el alcance de la policy ya decide quién puede escribir esa cita).
--   | → cancelada                         |   ✔   |        ✔         |     ✔     |
--   | → no_asistio                        |   ✔   |        —         |     ✔     |
--
-- El admin puede todo, así que su rama corta antes de mirar la transición.

create or replace function public.puede_cambiar_estado_cita(
  p_doctor_id uuid,
  p_destino   text
) returns boolean
language sql stable
set search_path to 'public'
as $$
  select case
    when public.es_admin() then true

    when public.es_asistente() and public.asiste_a_doctor(p_doctor_id) then
      p_destino in ('confirmada', 'en_espera', 'cancelada',
                    'no_asistio', 'no_asistida')

    when public.es_doctor() and p_doctor_id = auth.uid() then
      -- Lo clínico de su propia cita: dar por presente al paciente y cancelar.
      p_destino in ('en_espera', 'cancelada')

    else false
  end;
$$;

comment on function public.puede_cambiar_estado_cita(uuid, text) is
  'Matriz de transiciones de estado de cita por rol (QA 1-ago-2026): el asistente maneja lo administrativo de la agenda de los doctores que asiste, el doctor lo clínico de sus propias citas, y el admin todo. Los estados en_consulta y completada no pasan por aquí: los producen las RPC de consulta, que corren como `postgres`.';

revoke all on function public.puede_cambiar_estado_cita(uuid, text) from public;
grant all on function public.puede_cambiar_estado_cita(uuid, text) to authenticated;
grant all on function public.puede_cambiar_estado_cita(uuid, text) to service_role;

-- La matriz se impone con un trigger y no con el WITH CHECK de la policy
-- porque `WITH CHECK` sólo ve la fila nueva: no puede distinguir «cambió el
-- estado» de «se editó la hora y el estado siguió igual», y negaría cualquier
-- edición de una cita que ya estuviera en un estado no permitido como destino.
--
-- El trigger NO es `security definer` a propósito: así `current_user` delata
-- desde dónde se escribe. Las RPC clínicas (`registrar_llegada_cita`,
-- `iniciar_consulta_de_cita`, `cerrar_consulta`) son `security definer` de
-- `postgres` y siguen produciendo `en_consulta` y `completada` sin tropezar
-- con la matriz; una escritura directa por la API, no.
create or replace function public.hfx_qa_103_transicion_estado_cita()
returns trigger
language plpgsql
set search_path to 'public'
as $$
begin
  if new.estado is not distinct from old.estado then
    return new;
  end if;

  if current_user in ('postgres', 'service_role', 'supabase_admin') then
    return new;
  end if;

  if not public.puede_cambiar_estado_cita(new.doctor_id, new.estado::text) then
    raise exception
      'Tu rol no puede cambiar esta cita a «%».', new.estado
      using errcode = '42501';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_hfx_qa_103_transicion_estado_cita on public.citas;
create trigger trg_hfx_qa_103_transicion_estado_cita
  before update of estado on public.citas
  for each row execute function public.hfx_qa_103_transicion_estado_cita();

drop policy if exists citas_update on public.citas;
create policy citas_update on public.citas
  for update
  using (
    public.es_admin()
    or (public.es_doctor() and doctor_id = auth.uid())
    or (public.es_asistente() and public.asiste_a_doctor(doctor_id))
  )
  with check (
    public.es_admin()
    or (public.es_doctor() and doctor_id = auth.uid())
    or (public.es_asistente() and public.asiste_a_doctor(doctor_id))
  );

drop policy if exists citas_delete on public.citas;
create policy citas_delete on public.citas
  for delete using (
    public.es_admin()
    or (public.es_doctor() and doctor_id = auth.uid())
    or (public.es_asistente() and public.asiste_a_doctor(doctor_id))
  );

-- `citas_insert` no cambia: el doctor ya podía insertar citas propias desde
-- HFX-CLIN-001 (defecto D10 era del cliente, que lo degradaba a urgencia).
