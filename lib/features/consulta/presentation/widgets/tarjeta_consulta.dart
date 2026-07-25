import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';

/// Tarjeta de una sección del workspace de consulta: icono, título, subtítulo y
/// una acción opcional en la cabecera.
class TarjetaConsulta extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String titulo;
  final String subtitulo;
  final Widget? accion;
  final Widget child;

  const TarjetaConsulta({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.titulo,
    required this.subtitulo,
    required this.child,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ac.divider.withValues(alpha: 0.6)),
        boxShadow: [ac.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ac.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitulo,
                      style: TextStyle(fontSize: 11, color: ac.textMuted),
                    ),
                  ],
                ),
              ),
              if (accion != null) ...[const SizedBox(width: 8), accion!],
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: ac.divider.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
