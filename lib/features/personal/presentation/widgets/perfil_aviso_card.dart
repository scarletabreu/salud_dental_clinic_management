import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/listado_perfiles.dart';

/// Tarjeta para un perfil que no se pudo cargar.
///
/// Ocupa el mismo sitio que tendría el perfil en la lista, con el mismo tamaño
/// y la misma forma, para que el administrador vea **dónde** está el hueco. La
/// alternativa —la que había— era sustituir la pantalla entera por un error y
/// dejar sin administrar a todo el personal por culpa de un registro.
class PerfilAvisoCard extends StatelessWidget {
  final AvisoPerfil aviso;
  final VoidCallback? onReintentar;

  const PerfilAvisoCard({super.key, required this.aviso, this.onReintentar});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ac = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.55)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            aviso.esSeccionCompleta
                ? Icons.cloud_off_rounded
                : Icons.report_gmailerrorred_rounded,
            color: colorScheme.error,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aviso.titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  aviso.detalle,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (onReintentar != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onReintentar,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reintentar'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
