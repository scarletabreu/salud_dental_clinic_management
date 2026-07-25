-- Migración aplicada en remoto el 2026-07-25 (Studio/MCP) y recuperada al repo para
-- que el historial local y el remoto coincidan. No re-ejecutar a mano.

-- doctores: select para doctor/asistente/admin (todos), modificación solo admin o self (esta_disponible)
CREATE POLICY doctores_select ON public.doctores FOR SELECT TO authenticated USING (es_admin() OR es_doctor() OR es_asistente());
CREATE POLICY doctores_insert ON public.doctores FOR INSERT TO authenticated WITH CHECK (es_admin());
CREATE POLICY doctores_update ON public.doctores FOR UPDATE TO authenticated USING (es_admin() OR id = auth.uid()) WITH CHECK (es_admin() OR id = auth.uid());
CREATE POLICY doctores_delete ON public.doctores FOR DELETE TO authenticated USING (es_admin());

-- asistentes: select para doctor/asistente/admin (todos), modificación solo admin o self (turno)
CREATE POLICY asistentes_select ON public.asistentes FOR SELECT TO authenticated USING (es_admin() OR es_doctor() OR es_asistente());
CREATE POLICY asistentes_insert ON public.asistentes FOR INSERT TO authenticated WITH CHECK (es_admin());
CREATE POLICY asistentes_update ON public.asistentes FOR UPDATE TO authenticated USING (es_admin() OR id = auth.uid()) WITH CHECK (es_admin() OR id = auth.uid());
CREATE POLICY asistentes_delete ON public.asistentes FOR DELETE TO authenticated USING (es_admin());

-- admins: self-access, admin acceso completo
CREATE POLICY admins_select ON public.admins FOR SELECT TO authenticated USING (es_admin() OR id = auth.uid());
CREATE POLICY admins_insert ON public.admins FOR INSERT TO authenticated WITH CHECK (es_admin());
CREATE POLICY admins_update ON public.admins FOR UPDATE TO authenticated USING (es_admin()) WITH CHECK (es_admin());
CREATE POLICY admins_delete ON public.admins FOR DELETE TO authenticated USING (es_admin());

-- usuarios: self-access, admin acceso completo
CREATE POLICY usuarios_select ON public.usuarios FOR SELECT TO authenticated USING (es_admin() OR id = auth.uid());
CREATE POLICY usuarios_insert ON public.usuarios FOR INSERT TO authenticated WITH CHECK (es_admin());
CREATE POLICY usuarios_update ON public.usuarios FOR UPDATE TO authenticated USING (es_admin() OR id = auth.uid()) WITH CHECK (es_admin() OR id = auth.uid());
CREATE POLICY usuarios_delete ON public.usuarios FOR DELETE TO authenticated USING (es_admin());

-- doctor_asistentes: self-access (cada quien ve sus propias relaciones), admin acceso completo
CREATE POLICY doctor_asistentes_select ON public.doctor_asistentes FOR SELECT TO authenticated USING (es_admin() OR doctor_id = auth.uid() OR asistente_id = auth.uid());
CREATE POLICY doctor_asistentes_insert ON public.doctor_asistentes FOR INSERT TO authenticated WITH CHECK (es_admin());
CREATE POLICY doctor_asistentes_update ON public.doctor_asistentes FOR UPDATE TO authenticated USING (es_admin()) WITH CHECK (es_admin());
CREATE POLICY doctor_asistentes_delete ON public.doctor_asistentes FOR DELETE TO authenticated USING (es_admin());

-- contactos: igual que personas (select/insert/update para admin/doctor/asistente, delete solo admin)
CREATE POLICY contactos_select ON public.contactos FOR SELECT TO authenticated USING (es_admin() OR es_doctor() OR es_asistente());
CREATE POLICY contactos_insert ON public.contactos FOR INSERT TO authenticated WITH CHECK (es_admin() OR es_doctor() OR es_asistente());
CREATE POLICY contactos_update ON public.contactos FOR UPDATE TO authenticated USING (es_admin() OR es_doctor() OR es_asistente()) WITH CHECK (es_admin() OR es_doctor() OR es_asistente());
CREATE POLICY contactos_delete ON public.contactos FOR DELETE TO authenticated USING (es_admin());

-- persona_contactos: igual que personas
CREATE POLICY persona_contactos_select ON public.persona_contactos FOR SELECT TO authenticated USING (es_admin() OR es_doctor() OR es_asistente());
CREATE POLICY persona_contactos_insert ON public.persona_contactos FOR INSERT TO authenticated WITH CHECK (es_admin() OR es_doctor() OR es_asistente());
CREATE POLICY persona_contactos_update ON public.persona_contactos FOR UPDATE TO authenticated USING (es_admin() OR es_doctor() OR es_asistente()) WITH CHECK (es_admin() OR es_doctor() OR es_asistente());
CREATE POLICY persona_contactos_delete ON public.persona_contactos FOR DELETE TO authenticated USING (es_admin());
