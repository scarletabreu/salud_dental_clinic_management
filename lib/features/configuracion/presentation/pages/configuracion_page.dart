import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/shell/widgets/coming_soon_view.dart';

class ConfiguracionPage extends StatelessWidget {
  const ConfiguracionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: const ComingSoonView(
        icon: Icons.settings_outlined,
        title: 'Configuración',
        subtitle:
            'Preferencias de clínica, usuarios y catálogos estarán disponibles pronto.',
      ),
    );
  }
}
