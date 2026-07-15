import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/equipo/domain/entities/equipo.dart';

int _diasParaMantenimiento(Equipo e) {
  final proximo = e.ultimoMantenimiento.add(
    Duration(days: e.tiempoParaMantenimiento),
  );
  return proximo.difference(DateTime.now()).inDays;
}

class EquipoCard extends StatelessWidget {
  final Equipo equipo;
  final VoidCallback onTap;
  final VoidCallback onEliminar;

  const EquipoCard({
    super.key,
    required this.equipo,
    required this.onTap,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;
    final dias = _diasParaMantenimiento(equipo);

    final (statusColor, statusLabel, statusIcon) = switch (dias) {
      < 0 => (ac.red, 'Vencido (${dias.abs()}d)', Icons.warning_amber_rounded),
      <= 7 => (ac.amber, 'En $dias días', Icons.schedule_rounded),
      _ => (ac.green, 'En $dias días', Icons.check_circle_outline_rounded),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: ac.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ac.divider.withValues(alpha: 0.4),
            width: 0.8,
          ),
          boxShadow: [ac.cardShadow],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.build_circle_outlined,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Nombre + descripción
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipo.nombre,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (equipo.descripcion.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      equipo.descripcion,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: ac.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  // Pill de estado de mantenimiento
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 11, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          'Mant. $statusLabel',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Botón eliminar
            IconButton(
              onPressed: onEliminar,
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: ac.textSecondary.withValues(alpha: 0.6),
              ),
              tooltip: 'Eliminar equipo',
              visualDensity: VisualDensity.compact,
            ),

            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: ac.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
