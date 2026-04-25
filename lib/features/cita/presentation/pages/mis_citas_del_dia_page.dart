import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/shell/widgets/coming_soon_view.dart';

class MisCitasDelDiaPage extends StatelessWidget {
  const MisCitasDelDiaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: const ComingSoonView(
        icon: Icons.event_outlined,
        title: 'Mis Citas del Día',
        subtitle:
            'Agenda, estado y detalles de cada cita del día se mostrarán aquí.',
      ),
    );
  }
}
