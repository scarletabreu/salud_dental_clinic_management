import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/util/fecha_es.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';

/// Pantalla de detalle de consulta. Por ahora es un stub que muestra los datos
/// básicos y deja el flujo de navegación cableado; el detalle completo se
/// implementará en su propio ticket.
class ConsultaDetallePage extends StatelessWidget {
  final Consulta consulta;
  final String nombrePaciente;
  final String nombreDoctor;

  const ConsultaDetallePage({
    super.key,
    required this.consulta,
    required this.nombrePaciente,
    required this.nombreDoctor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ac = context.appColors;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Detalle de consulta'),
        backgroundColor: ac.cardBg,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ac.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ac.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fila(context, 'Fecha', fechaLargaEs(consulta.fecha)),
                      const SizedBox(height: 14),
                      _fila(context, 'Paciente', nombrePaciente),
                      const SizedBox(height: 14),
                      _fila(context, 'Doctor', nombreDoctor),
                      if (consulta.motivoConsulta != null &&
                          consulta.motivoConsulta!.trim().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _fila(context, 'Motivo', consulta.motivoConsulta!),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _badge(
                            context,
                            icon: Icons.receipt_long_rounded,
                            label:
                                '${consulta.recetas.length} receta${consulta.recetas.length == 1 ? '' : 's'}',
                            color: ac.primaryBlue,
                            activo: consulta.tieneRecetas,
                          ),
                          const SizedBox(width: 8),
                          _badge(
                            context,
                            icon: Icons.healing_rounded,
                            label: consulta.tieneTratamientosAplicados
                                ? 'Con tratamientos'
                                : 'Sin tratamientos',
                            color: ac.teal,
                            activo: consulta.tieneTratamientosAplicados,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Icon(
                  Icons.construction_rounded,
                  size: 36,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'El detalle completo de la consulta está en construcción.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fila(BuildContext context, String label, String valor) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            letterSpacing: 0.8,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _badge(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required bool activo,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final fg = activo ? color : colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
