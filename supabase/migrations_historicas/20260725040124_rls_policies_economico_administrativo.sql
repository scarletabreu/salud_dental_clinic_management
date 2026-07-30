-- Migración aplicada en remoto el 2026-07-25 (Studio/MCP) y recuperada al repo para
-- que el historial local y el remoto coincidan. No re-ejecutar a mano.

-- Grupo económico/administrativo: asistente select+update, doctor solo select, admin acceso completo
-- cajas_diarias
CREATE POLICY cajas_diarias_select ON public.cajas_diarias FOR SELECT TO authenticated USING (es_admin() OR es_doctor() OR es_asistente());
CREATE POLICY cajas_diarias_insert ON public.cajas_diarias FOR INSERT TO authenticated WITH CHECK (es_admin());
CREATE POLICY cajas_diarias_update ON public.cajas_diarias FOR UPDATE TO authenticated USING (es_admin() OR es_asistente()) WITH CHECK (es_admin() OR es_asistente());
CREATE POLICY cajas_diarias_delete ON public.cajas_diarias FOR DELETE TO authenticated USING (es_admin());

-- compras
CREATE POLICY compras_select ON public.compras FOR SELECT TO authenticated USING (es_admin() OR es_doctor() OR es_asistente());
CREATE POLICY compras_insert ON public.compras FOR INSERT TO authenticated WITH CHECK (es_admin());
CREATE POLICY compras_update ON public.compras FOR UPDATE TO authenticated USING (es_admin() OR es_asistente()) WITH CHECK (es_admin() OR es_asistente());
CREATE POLICY compras_delete ON public.compras FOR DELETE TO authenticated USING (es_admin());

-- consumibles
CREATE POLICY consumibles_select ON public.consumibles FOR SELECT TO authenticated USING (es_admin() OR es_doctor() OR es_asistente());
CREATE POLICY consumibles_insert ON public.consumibles FOR INSERT TO authenticated WITH CHECK (es_admin());
CREATE POLICY consumibles_update ON public.consumibles FOR UPDATE TO authenticated USING (es_admin() OR es_asistente()) WITH CHECK (es_admin() OR es_asistente());
CREATE POLICY consumibles_delete ON public.consumibles FOR DELETE TO authenticated USING (es_admin());

-- consumibles_compras
CREATE POLICY consumibles_compras_select ON public.consumibles_compras FOR SELECT TO authenticated USING (es_admin() OR es_doctor() OR es_asistente());
CREATE POLICY consumibles_compras_insert ON public.consumibles_compras FOR INSERT TO authenticated WITH CHECK (es_admin());
CREATE POLICY consumibles_compras_update ON public.consumibles_compras FOR UPDATE TO authenticated USING (es_admin() OR es_asistente()) WITH CHECK (es_admin() OR es_asistente());
CREATE POLICY consumibles_compras_delete ON public.consumibles_compras FOR DELETE TO authenticated USING (es_admin());

-- cuotas
CREATE POLICY cuotas_select ON public.cuotas FOR SELECT TO authenticated USING (es_admin() OR es_doctor() OR es_asistente());
CREATE POLICY cuotas_insert ON public.cuotas FOR INSERT TO authenticated WITH CHECK (es_admin());
CREATE POLICY cuotas_update ON public.cuotas FOR UPDATE TO authenticated USING (es_admin() OR es_asistente()) WITH CHECK (es_admin() OR es_asistente());
CREATE POLICY cuotas_delete ON public.cuotas FOR DELETE TO authenticated USING (es_admin());

-- equipos
CREATE POLICY equipos_select ON public.equipos FOR SELECT TO authenticated USING (es_admin() OR es_doctor() OR es_asistente());
CREATE POLICY equipos_insert ON public.equipos FOR INSERT TO authenticated WITH CHECK (es_admin());
CREATE POLICY equipos_update ON public.equipos FOR UPDATE TO authenticated USING (es_admin() OR es_asistente()) WITH CHECK (es_admin() OR es_asistente());
CREATE POLICY equipos_delete ON public.equipos FOR DELETE TO authenticated USING (es_admin());

-- equipos_mantenimientos
CREATE POLICY equipos_mantenimientos_select ON public.equipos_mantenimientos FOR SELECT TO authenticated USING (es_admin() OR es_doctor() OR es_asistente());
CREATE POLICY equipos_mantenimientos_insert ON public.equipos_mantenimientos FOR INSERT TO authenticated WITH CHECK (es_admin());
CREATE POLICY equipos_mantenimientos_update ON public.equipos_mantenimientos FOR UPDATE TO authenticated USING (es_admin() OR es_asistente()) WITH CHECK (es_admin() OR es_asistente());
CREATE POLICY equipos_mantenimientos_delete ON public.equipos_mantenimientos FOR DELETE TO authenticated USING (es_admin());

-- items_cuenta
CREATE POLICY items_cuenta_select ON public.items_cuenta FOR SELECT TO authenticated USING (es_admin() OR es_doctor() OR es_asistente());
CREATE POLICY items_cuenta_insert ON public.items_cuenta FOR INSERT TO authenticated WITH CHECK (es_admin());
CREATE POLICY items_cuenta_update ON public.items_cuenta FOR UPDATE TO authenticated USING (es_admin() OR es_asistente()) WITH CHECK (es_admin() OR es_asistente());
CREATE POLICY items_cuenta_delete ON public.items_cuenta FOR DELETE TO authenticated USING (es_admin());

-- suplidores
CREATE POLICY suplidores_select ON public.suplidores FOR SELECT TO authenticated USING (es_admin() OR es_doctor() OR es_asistente());
CREATE POLICY suplidores_insert ON public.suplidores FOR INSERT TO authenticated WITH CHECK (es_admin());
CREATE POLICY suplidores_update ON public.suplidores FOR UPDATE TO authenticated USING (es_admin() OR es_asistente()) WITH CHECK (es_admin() OR es_asistente());
CREATE POLICY suplidores_delete ON public.suplidores FOR DELETE TO authenticated USING (es_admin());

-- suplidores_contactos
CREATE POLICY suplidores_contactos_select ON public.suplidores_contactos FOR SELECT TO authenticated USING (es_admin() OR es_doctor() OR es_asistente());
CREATE POLICY suplidores_contactos_insert ON public.suplidores_contactos FOR INSERT TO authenticated WITH CHECK (es_admin());
CREATE POLICY suplidores_contactos_update ON public.suplidores_contactos FOR UPDATE TO authenticated USING (es_admin() OR es_asistente()) WITH CHECK (es_admin() OR es_asistente());
CREATE POLICY suplidores_contactos_delete ON public.suplidores_contactos FOR DELETE TO authenticated USING (es_admin());
