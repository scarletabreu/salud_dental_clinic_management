import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/shell/widgets/coming_soon_view.dart';

class ConsultasPage extends StatelessWidget {
  const ConsultasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: const ComingSoonView(
        icon: Icons.medical_information_outlined,
        title: 'Consultas',
        subtitle:
            'Historial de consultas, diagnósticos y notas clínicas en construcción.',
      ),
    );
  }
}
