import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_item_plan.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_plan_tratamiento.dart';

/// Color e ícono de cada estado, en un solo lugar para que la consulta y el
/// expediente cuenten la misma historia sobre la misma actividad.
///
/// El criterio: ámbar = esperando una decisión, azul = decidida y en camino,
/// verde = cerrada con éxito, rojo/gris = cerrada sin ejecutarse.
({Color color, IconData icono}) estiloItemPlan(
  EstadoItemPlan estado,
  AppColors ac,
) {
  switch (estado) {
    case EstadoItemPlan.propuesto:
      return (color: ac.amber, icono: Icons.help_outline_rounded);
    case EstadoItemPlan.aceptado:
      return (color: ac.primaryGreen, icono: Icons.task_alt_rounded);
    case EstadoItemPlan.pendiente:
      return (color: ac.indigo, icono: Icons.schedule_rounded);
    case EstadoItemPlan.enProceso:
      return (color: ac.teal, icono: Icons.play_circle_outline_rounded);
    case EstadoItemPlan.completado:
      return (color: ac.green, icono: Icons.check_circle_outline_rounded);
    case EstadoItemPlan.rechazado:
      return (color: ac.red, icono: Icons.cancel_outlined);
    case EstadoItemPlan.cancelado:
      return (color: ac.textDisabled, icono: Icons.block_rounded);
  }
}

({Color color, IconData icono}) estiloPlan(
  EstadoPlanTratamiento estado,
  AppColors ac,
) {
  switch (estado) {
    case EstadoPlanTratamiento.borrador:
      return (color: ac.textMuted, icono: Icons.edit_note_rounded);
    case EstadoPlanTratamiento.propuesto:
      return (color: ac.amber, icono: Icons.help_outline_rounded);
    case EstadoPlanTratamiento.aceptado:
      return (color: ac.primaryGreen, icono: Icons.task_alt_rounded);
    case EstadoPlanTratamiento.enProceso:
      return (color: ac.teal, icono: Icons.play_circle_outline_rounded);
    case EstadoPlanTratamiento.completado:
      return (color: ac.green, icono: Icons.check_circle_outline_rounded);
    case EstadoPlanTratamiento.rechazado:
      return (color: ac.red, icono: Icons.cancel_outlined);
    case EstadoPlanTratamiento.cancelado:
      return (color: ac.textDisabled, icono: Icons.block_rounded);
  }
}

/// Pastilla de estado. Misma forma en las dos pantallas.
class ChipEstado extends StatelessWidget {
  final String texto;
  final Color color;
  final IconData icono;

  const ChipEstado({
    super.key,
    required this.texto,
    required this.color,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
