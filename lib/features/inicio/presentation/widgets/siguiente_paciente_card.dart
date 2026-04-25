import 'package:flutter/material.dart';

class SiguientePacienteCard extends StatelessWidget {
  const SiguientePacienteCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: colorScheme.primary),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _content(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Text(
            'SIGUIENTE PACIENTE',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 28,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sin paciente asignado',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'La agenda de hoy aparecerá aquí cuando el módulo de citas esté conectado.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Ver Historial'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Iniciar Cita'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
