import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_state.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/formulario_evaluacion.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/panel_paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';

/// Pantalla "Efectuar Consulta": carga el paciente en un panel lateral y
/// presenta el formulario de evaluación clínica para crear la consulta con su
/// odontograma inicializado.
class EfectuarConsultaPage extends StatelessWidget {
  final String citaId;
  final String pacienteId;
  final String doctorId;

  const EfectuarConsultaPage({
    super.key,
    required this.citaId,
    required this.pacienteId,
    required this.doctorId,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<PacienteCubit>()..loadById(pacienteId),
        ),
        BlocProvider(create: (_) => sl<ConsultaCubit>()),
      ],
      child: Scaffold(
        backgroundColor: c.bgPage,
        appBar: AppBar(
          backgroundColor: c.cardBg,
          foregroundColor: c.textPrimary,
          elevation: 0,
          title: const Text('Efectuar Consulta'),
        ),
        body: BlocListener<ConsultaCubit, ConsultaState>(
          listener: _onConsultaState,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPanel(),
              Expanded(
                child: FormularioEvaluacion(
                  pacienteId: pacienteId,
                  doctorId: doctorId,
                  citaId: citaId,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    return BlocBuilder<PacienteCubit, PacienteState>(
      builder: (context, state) {
        if (state is PacienteDetailLoaded) {
          return PanelPaciente(paciente: state.paciente);
        }
        final c = context.appColors;
        return Container(
          width: 320,
          decoration: BoxDecoration(
            color: c.cardBg,
            border: Border(right: BorderSide(color: c.divider)),
          ),
          child: Center(
            child: state is PacienteError
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.red),
                    ),
                  )
                : const CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  void _onConsultaState(BuildContext context, ConsultaState state) {
    if (state is ConsultaCreada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consulta registrada con su odontograma.'),
        ),
      );
      Navigator.of(context).pop(true);
    } else if (state is ConsultaError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: context.appColors.red,
        ),
      );
    }
  }
}
