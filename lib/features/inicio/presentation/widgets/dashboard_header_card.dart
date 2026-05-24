import 'package:flutter/material.dart';

class DashboardHeaderCard extends StatelessWidget {
  final VoidCallback? onVerCitas;

  const DashboardHeaderCard({super.key, this.onVerCitas});

  String _saludo() {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Buenos días';
    if (hora < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _fechaFormateada() {
    final hoy = DateTime.now();
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    final dia = dias[hoy.weekday - 1];
    final mes = meses[hoy.month - 1];
    return '$dia, ${hoy.day} de $mes · ${hoy.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ícono decorativo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.local_hospital_rounded,
              color: colorScheme.onPrimary,
              size: 22,
            ),
          ),

          const SizedBox(height: 20),

          // Saludo + nombre del doctor
          Text(
            '${_saludo()},',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Dr. Méndez',
            style: textTheme.headlineMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          // Fecha
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.65),
              ),
              const SizedBox(width: 6),
              Text(
                _fechaFormateada(),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.65),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Botón
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onVerCitas,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.calendar_month_rounded, size: 18),
              label: const Text(
                'Ver Mis Citas',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
