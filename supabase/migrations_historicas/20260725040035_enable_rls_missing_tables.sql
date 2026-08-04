-- Migración aplicada en remoto el 2026-07-25 (Studio/MCP) y recuperada al repo para
-- que el historial local y el remoto coincidan. No re-ejecutar a mano.

ALTER TABLE public.admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.asistentes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cajas_diarias ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.compras ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.condiciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consumibles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consumibles_compras ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contactos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contraindicaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cuotas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.diagnosticos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.diagnosticos_aplicados ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctor_asistentes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documentos_clinicos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipos_mantenimientos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.items_cuenta ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medicinas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ordenes_medicas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.persona_contactos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.procedimientos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recetas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.superficies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suplidores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suplidores_contactos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tratamientos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tratamientos_aplicados ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
