-- Migración aplicada en remoto el 2026-07-25 (Studio/MCP) y recuperada al repo para
-- que el historial local y el remoto coincidan. No re-ejecutar a mano.

-- Grupo clínico: doctor acceso completo, asistente sin acceso, admin acceso completo
-- condiciones
CREATE POLICY condiciones_select ON public.condiciones FOR SELECT TO authenticated USING (es_admin() OR es_doctor());
CREATE POLICY condiciones_insert ON public.condiciones FOR INSERT TO authenticated WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY condiciones_update ON public.condiciones FOR UPDATE TO authenticated USING (es_admin() OR es_doctor()) WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY condiciones_delete ON public.condiciones FOR DELETE TO authenticated USING (es_admin() OR es_doctor());

-- contraindicaciones
CREATE POLICY contraindicaciones_select ON public.contraindicaciones FOR SELECT TO authenticated USING (es_admin() OR es_doctor());
CREATE POLICY contraindicaciones_insert ON public.contraindicaciones FOR INSERT TO authenticated WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY contraindicaciones_update ON public.contraindicaciones FOR UPDATE TO authenticated USING (es_admin() OR es_doctor()) WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY contraindicaciones_delete ON public.contraindicaciones FOR DELETE TO authenticated USING (es_admin() OR es_doctor());

-- diagnosticos
CREATE POLICY diagnosticos_select ON public.diagnosticos FOR SELECT TO authenticated USING (es_admin() OR es_doctor());
CREATE POLICY diagnosticos_insert ON public.diagnosticos FOR INSERT TO authenticated WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY diagnosticos_update ON public.diagnosticos FOR UPDATE TO authenticated USING (es_admin() OR es_doctor()) WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY diagnosticos_delete ON public.diagnosticos FOR DELETE TO authenticated USING (es_admin() OR es_doctor());

-- diagnosticos_aplicados
CREATE POLICY diagnosticos_aplicados_select ON public.diagnosticos_aplicados FOR SELECT TO authenticated USING (es_admin() OR es_doctor());
CREATE POLICY diagnosticos_aplicados_insert ON public.diagnosticos_aplicados FOR INSERT TO authenticated WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY diagnosticos_aplicados_update ON public.diagnosticos_aplicados FOR UPDATE TO authenticated USING (es_admin() OR es_doctor()) WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY diagnosticos_aplicados_delete ON public.diagnosticos_aplicados FOR DELETE TO authenticated USING (es_admin() OR es_doctor());

-- dientes
CREATE POLICY dientes_select ON public.dientes FOR SELECT TO authenticated USING (es_admin() OR es_doctor());
CREATE POLICY dientes_insert ON public.dientes FOR INSERT TO authenticated WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY dientes_update ON public.dientes FOR UPDATE TO authenticated USING (es_admin() OR es_doctor()) WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY dientes_delete ON public.dientes FOR DELETE TO authenticated USING (es_admin() OR es_doctor());

-- documentos_clinicos
CREATE POLICY documentos_clinicos_select ON public.documentos_clinicos FOR SELECT TO authenticated USING (es_admin() OR es_doctor());
CREATE POLICY documentos_clinicos_insert ON public.documentos_clinicos FOR INSERT TO authenticated WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY documentos_clinicos_update ON public.documentos_clinicos FOR UPDATE TO authenticated USING (es_admin() OR es_doctor()) WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY documentos_clinicos_delete ON public.documentos_clinicos FOR DELETE TO authenticated USING (es_admin() OR es_doctor());

-- medicinas
CREATE POLICY medicinas_select ON public.medicinas FOR SELECT TO authenticated USING (es_admin() OR es_doctor());
CREATE POLICY medicinas_insert ON public.medicinas FOR INSERT TO authenticated WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY medicinas_update ON public.medicinas FOR UPDATE TO authenticated USING (es_admin() OR es_doctor()) WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY medicinas_delete ON public.medicinas FOR DELETE TO authenticated USING (es_admin() OR es_doctor());

-- ordenes_medicas
CREATE POLICY ordenes_medicas_select ON public.ordenes_medicas FOR SELECT TO authenticated USING (es_admin() OR es_doctor());
CREATE POLICY ordenes_medicas_insert ON public.ordenes_medicas FOR INSERT TO authenticated WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY ordenes_medicas_update ON public.ordenes_medicas FOR UPDATE TO authenticated USING (es_admin() OR es_doctor()) WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY ordenes_medicas_delete ON public.ordenes_medicas FOR DELETE TO authenticated USING (es_admin() OR es_doctor());

-- procedimientos
CREATE POLICY procedimientos_select ON public.procedimientos FOR SELECT TO authenticated USING (es_admin() OR es_doctor());
CREATE POLICY procedimientos_insert ON public.procedimientos FOR INSERT TO authenticated WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY procedimientos_update ON public.procedimientos FOR UPDATE TO authenticated USING (es_admin() OR es_doctor()) WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY procedimientos_delete ON public.procedimientos FOR DELETE TO authenticated USING (es_admin() OR es_doctor());

-- recetas
CREATE POLICY recetas_select ON public.recetas FOR SELECT TO authenticated USING (es_admin() OR es_doctor());
CREATE POLICY recetas_insert ON public.recetas FOR INSERT TO authenticated WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY recetas_update ON public.recetas FOR UPDATE TO authenticated USING (es_admin() OR es_doctor()) WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY recetas_delete ON public.recetas FOR DELETE TO authenticated USING (es_admin() OR es_doctor());

-- superficies
CREATE POLICY superficies_select ON public.superficies FOR SELECT TO authenticated USING (es_admin() OR es_doctor());
CREATE POLICY superficies_insert ON public.superficies FOR INSERT TO authenticated WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY superficies_update ON public.superficies FOR UPDATE TO authenticated USING (es_admin() OR es_doctor()) WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY superficies_delete ON public.superficies FOR DELETE TO authenticated USING (es_admin() OR es_doctor());

-- tratamientos
CREATE POLICY tratamientos_select ON public.tratamientos FOR SELECT TO authenticated USING (es_admin() OR es_doctor());
CREATE POLICY tratamientos_insert ON public.tratamientos FOR INSERT TO authenticated WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY tratamientos_update ON public.tratamientos FOR UPDATE TO authenticated USING (es_admin() OR es_doctor()) WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY tratamientos_delete ON public.tratamientos FOR DELETE TO authenticated USING (es_admin() OR es_doctor());

-- tratamientos_aplicados
CREATE POLICY tratamientos_aplicados_select ON public.tratamientos_aplicados FOR SELECT TO authenticated USING (es_admin() OR es_doctor());
CREATE POLICY tratamientos_aplicados_insert ON public.tratamientos_aplicados FOR INSERT TO authenticated WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY tratamientos_aplicados_update ON public.tratamientos_aplicados FOR UPDATE TO authenticated USING (es_admin() OR es_doctor()) WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY tratamientos_aplicados_delete ON public.tratamientos_aplicados FOR DELETE TO authenticated USING (es_admin() OR es_doctor());

-- record_condicion (ya tenía RLS habilitado pero sin policies)
CREATE POLICY record_condicion_select ON public.record_condicion FOR SELECT TO authenticated USING (es_admin() OR es_doctor());
CREATE POLICY record_condicion_insert ON public.record_condicion FOR INSERT TO authenticated WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY record_condicion_update ON public.record_condicion FOR UPDATE TO authenticated USING (es_admin() OR es_doctor()) WITH CHECK (es_admin() OR es_doctor());
CREATE POLICY record_condicion_delete ON public.record_condicion FOR DELETE TO authenticated USING (es_admin() OR es_doctor());
