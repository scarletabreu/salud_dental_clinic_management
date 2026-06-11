import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_state.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/formulario_evaluacion.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/panel_paciente.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/workspace_consulta.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';

/// Pantalla "Efectuar Consulta". Flujo de dos etapas con el paciente fijo a la
/// izquierda:
///   1. [FormularioEvaluacion] — evaluación clínica que crea la consulta y su
///      odontograma inicializado.
///   2. [WorkspaceConsulta] — odontograma interactivo, tratamientos y notas;
///      finaliza con "Terminar consulta".
class EfectuarConsultaPage extends StatefulWidget {
  final String? citaId;
  final String pacienteId;
  final String doctorId;

  const EfectuarConsultaPage({
    super.key,
    this.citaId,
    required this.pacienteId,
    required this.doctorId,
  });

  @override
  State<EfectuarConsultaPage> createState() => _EfectuarConsultaPageState();
}

class _EfectuarConsultaPageState extends State<EfectuarConsultaPage> {
  bool _enWorkspace = false;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<PacienteCubit>()..loadById(widget.pacienteId),
        ),
        BlocProvider(create: (_) => sl<ConsultaCubit>()),
      ],
      child: Scaffold(
        backgroundColor: c.bgPage,
        appBar: AppBar(
          backgroundColor: c.cardBg,
          foregroundColor: c.textPrimary,
          elevation: 0,
          title: Text(_enWorkspace ? 'Consulta en curso' : 'Efectuar Consulta'),
        ),
        body: BlocListener<ConsultaCubit, ConsultaState>(
          listener: _onConsultaState,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPanel(),
              Expanded(
                child: _enWorkspace
                    ? WorkspaceConsulta(citaId: widget.citaId)
                    : FormularioEvaluacion(
                        pacienteId: widget.pacienteId,
                        doctorId: widget.doctorId,
                        citaId: widget.citaId,
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
      // Etapa 1 completada: la consulta y su odontograma quedaron creados.
      setState(() => _enWorkspace = true);
    } else if (state is ConsultaTerminada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consulta finalizada.')),
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
