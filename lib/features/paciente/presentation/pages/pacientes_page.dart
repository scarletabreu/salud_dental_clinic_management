import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/shell/widgets/coming_soon_view.dart';

class PacientesPage extends StatelessWidget {
  const PacientesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: const ComingSoonView(
        icon: Icons.people_alt_outlined,
        title: 'Pacientes',
        subtitle:
            'Historial, expedientes y tratamientos de pacientes aparecerán aquí.',
      ),
    );
  }
}
