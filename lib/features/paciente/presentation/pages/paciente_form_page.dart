import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/shell/widgets/coming_soon_view.dart';

class PacienteFormPage extends StatelessWidget {
  final Paciente? paciente;

  const PacienteFormPage({super.key, this.paciente});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(paciente == null ? 'Nuevo Paciente' : 'Editar Paciente'),
      ),
      body: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: ComingSoonView(
          icon: Icons.person_add_outlined,
          title: paciente == null ? 'Nuevo Paciente' : 'Editar Paciente',
          subtitle: 'Formulario de registro en construcción.',
        ),
      ),
    );
  }
}
