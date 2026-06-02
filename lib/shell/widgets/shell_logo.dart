import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';

class ShellLogo extends StatelessWidget {
  final bool extended;

  const ShellLogo({super.key, required this.extended});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final icon = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: ac.railSelectedBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.medical_services_rounded,
        color: ac.railTextSelected,
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
                    color: ac.railTextSelected,
                    height: 1.1,
                  ),
                ),
                Text(
                  'Gestión Clínica',
                  style: textTheme.labelSmall?.copyWith(
                    color: ac.railText,
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
