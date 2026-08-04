import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';

/// Una opción excluyente dentro de una hoja de decisión —imprimir esto o
/// aquello—. Vive en `core` porque la comparten el expediente y el
/// odontodiagrama: si cada hoja pintara la suya, decidir qué se imprime se
/// vería distinto según por dónde se entrara.
///
/// Con [onTap] en `null` la tarjeta se ofrece apagada en vez de desaparecer:
/// una opción que hoy no se puede ejercer se explica, no se esconde.
class TarjetaOpcion extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final bool seleccionada;
  final VoidCallback? onTap;

  const TarjetaOpcion({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.seleccionada,
    this.onTap,
  });

  bool get _habilitada => onTap != null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ac = context.appColors;
    final marcada = seleccionada && _habilitada;

    return Opacity(
      opacity: _habilitada ? 1 : 0.55,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: marcada
                ? ac.primaryGreen.withValues(alpha: 0.08)
                : ac.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: marcada
                  ? ac.primaryGreen
                  : colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: marcada ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icono,
                color: marcada
                    ? ac.primaryGreen
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.75,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: marcada ? ac.primaryGreen : Colors.transparent,
                  border: Border.all(
                    color: marcada
                        ? ac.primaryGreen
                        : colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: marcada
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
