-- D11 · Modelo definitivo de alcance clínico: cada doctor ve lo suyo.
--
-- El 1 ago 2026 QA abrió la lectura de consultas a cualquier doctor como
-- arreglo TEMPORAL (HFX-QA-103), a la espera del modelo definitivo. Esta es esa
-- decisión, tomada por la dirección de la clínica el 3 ago 2026:
--
--   · El doctor ve **sus** citas y **sus** consultas, y nada más.
--   · El administrador es el único que ve la agenda y el expediente completos.
--   · El asistente conserva lo administrativo de los doctores que asiste
--     (HFX-QA-103, D12): ni ve ni deja de ver consultas por esta migración.
--
-- La escritura no cambia: ya estaba atada al doctor firmante desde
-- HFX-CLIN-001, y las RPC clínicas siguen corriendo como `postgres`.

-- ---------------------------------------------------------------------------
-- 1 · La consulta vuelve a ser de su doctor
-- ---------------------------------------------------------------------------

drop policy if exists consulta_select on public.consultas;
create policy consulta_select on public.consultas
  for select using (
    public.es_admin()
    or (public.es_doctor() and doctor_id = auth.uid())
  );

comment on policy consulta_select on public.consultas is
  'Alcance clínico definitivo (3 ago 2026): el doctor lee sólo las consultas que firmó; el admin, todas. Deroga la apertura TEMPORAL de HFX-QA-103 (D11).';

-- `puede_ver_consulta` es la que propaga el alcance a todo lo que cuelga de una
-- consulta —recetas, consumos, signos vitales, odontogramas, dientes,
-- superficies, auditoría—. Si se cierra la policy y no la función, el
-- expediente ajeno seguiría abierto por sus tablas hijas.
create or replace function public.puede_ver_consulta(p_consulta_id uuid)
returns boolean
language sql stable security definer
set search_path to 'public'
as $$
  select public.es_admin() or exists (
    select 1 from public.consultas c
     where c.id = p_consulta_id
       and c.deleted_at is null
       and c.doctor_id = auth.uid()
       and public.es_doctor()
  );
$$;

comment on function public.puede_ver_consulta(uuid) is
  'Guardia de todo lo que cuelga de una consulta: admin siempre, y el doctor sólo en las consultas que firmó (3 ago 2026, D11 definitivo).';

revoke all on function public.puede_ver_consulta(uuid) from public;
grant all on function public.puede_ver_consulta(uuid) to authenticated;
grant all on function public.puede_ver_consulta(uuid) to service_role;

-- ---------------------------------------------------------------------------
-- 2 · Cerrar los desvíos que dejaban leer consultas ajenas por otro camino
-- ---------------------------------------------------------------------------
-- `consulta_resumen` es de la línea base, la posee `postgres` y no declara
-- `security_invoker`: PostgREST la sirve a `authenticated` saltándose la RLS de
-- `consultas`, así que devolvía doctor, paciente y fecha de TODAS las
-- consultas. Nadie la consume en el cliente; se deja publicada pero obediente.
alter view public.consulta_resumen set (security_invoker = on);

comment on view public.consulta_resumen is
  'Resumen de consultas. security_invoker=on desde el 3 ago 2026: sin él la vista saltaba consulta_select y exponía el listado completo a cualquier doctor.';

-- Las órdenes médicas son contenido de la consulta y su policy miraba sólo el
-- rol (`es_admin() OR es_doctor()`), no la autoría: un doctor leía —y escribía—
-- las órdenes de la consulta de otro. Pasan por las mismas guardias que
-- recetas. La tabla no tiene aún pantalla que la escriba, así que el cambio no
-- toca ningún flujo vivo.
drop policy if exists ordenes_medicas_select on public.ordenes_medicas;
create policy ordenes_medicas_select on public.ordenes_medicas
  for select to authenticated
  using (public.puede_ver_consulta(consulta_id));

drop policy if exists ordenes_medicas_insert on public.ordenes_medicas;
create policy ordenes_medicas_insert on public.ordenes_medicas
  for insert to authenticated
  with check (public.puede_editar_consulta_propia(consulta_id));

drop policy if exists ordenes_medicas_update on public.ordenes_medicas;
create policy ordenes_medicas_update on public.ordenes_medicas
  for update to authenticated
  using (public.puede_editar_consulta_propia(consulta_id))
  with check (public.puede_editar_consulta_propia(consulta_id));

drop policy if exists ordenes_medicas_delete on public.ordenes_medicas;
create policy ordenes_medicas_delete on public.ordenes_medicas
  for delete to authenticated
  using (
    public.es_admin() or public.puede_editar_consulta_propia(consulta_id)
  );

-- ---------------------------------------------------------------------------
-- 3 · La agenda: reafirmar el recorte por doctor
-- ---------------------------------------------------------------------------
-- HFX-QA-103 ya dejó `citas_select/update/delete` recortadas por doctor, pero
-- esa migración pudo no haber llegado a toda instancia (producción va por
-- detrás del repo). Se reescriben idénticas: donde ya estaban, no cambia nada;
-- donde faltaban, cierran la agenda ajena. `citas_insert` no se toca.

drop policy if exists citas_select on public.citas;
create policy citas_select on public.citas
  for select using (
    public.es_admin()
    or (public.es_doctor() and doctor_id = auth.uid())
    or (public.es_asistente() and public.asiste_a_doctor(doctor_id))
  );

comment on policy citas_select on public.citas is
  'Cada quien ve la agenda que le toca: el admin toda, el doctor la suya, el asistente la de los doctores que asiste (HFX-QA-103 D12, reafirmado el 3 ago 2026).';

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
