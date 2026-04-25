import 'package:flutter/material.dart';

class ShellLogo extends StatelessWidget {
  final bool extended;

  const ShellLogo({super.key, required this.extended});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final icon = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.medical_services_rounded,
        color: colorScheme.onPrimaryContainer,
        size: 22,
      ),
    );

    if (!extended) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: icon,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salud Dental',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                    height: 1.1,
                  ),
                ),
                Text(
                  'Gestión Clínica',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
