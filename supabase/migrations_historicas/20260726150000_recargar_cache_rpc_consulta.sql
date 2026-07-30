-- Hotfix: SD-138 añade una sobrecarga de crear_consulta_completa con
-- p_tipo_atencion. PostgREST debe verla en cuanto termina el despliegue, sin
-- depender de la expiración de su caché de esquema.
notify pgrst, 'reload schema';
