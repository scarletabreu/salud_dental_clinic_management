import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_state.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/formulario_evaluacion.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/panel_paciente.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/workspace_consulta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/pages/pre_factura_page.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';

class EfectuarConsultaPage extends StatefulWidget {
  final String? citaId;
  final String pacienteId;
  final String doctorId;
  final String? consultaId;

  const EfectuarConsultaPage({
    super.key,
    required this.citaId,
    required this.pacienteId,
    required this.doctorId,
    this.consultaId,
  });

  @override
  State<EfectuarConsultaPage> createState() => _EfectuarConsultaPageState();
}

class _EfectuarConsultaPageState extends State<EfectuarConsultaPage> {
  bool _enWorkspace = false;
  bool _hasInitialTriggered = false;

  @override
  void initState() {
    super.initState();
    _enWorkspace = widget.consultaId != null;
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<PacienteCubit>()..loadParaConsulta(widget.pacienteId),
        ),
        BlocProvider(create: (_) => sl<ConsultaCubit>()),
      ],
      child: Builder( // <--- 1. ADD THIS BUILDER RIGHT HERE
        builder: (innerContext) {
          
          // 2. Safely trigger the resume logic using innerContext
          if (widget.consultaId != null && !_hasInitialTriggered) {
            _hasInitialTriggered = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!innerContext.mounted) return;
              innerContext.read<ConsultaCubit>().reanudarConsulta(consultaId: widget.consultaId!);
            });
          }

          return Scaffold(
            backgroundColor: ac.bgPage,
            body: BlocListener<ConsultaCubit, ConsultaState>(
              listener: _onConsultaState,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FloatingBar(enWorkspace: _enWorkspace),
                  const SizedBox(height: 12),

                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPanel(ac),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, animation) => FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.03, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            ),
                            child: _enWorkspace
                                ? WorkspaceConsulta(
                                    key: const ValueKey('workspace'),
                                    citaId: widget.citaId,
                                  )
                                : FormularioEvaluacion(
                                    key: const ValueKey('formulario'),
                                    pacienteId: widget.pacienteId,
                                    doctorId: widget.doctorId,
                                    citaId: widget.citaId,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPanel(AppColors ac) {
    return BlocBuilder<PacienteCubit, PacienteState>(
      builder: (context, state) {
        if (state is PacienteDetailLoaded) {
          return PanelPaciente(paciente: state.paciente);
        }
        return Container(
          width: 300,
          decoration: BoxDecoration(
            color: ac.cardBg,
            border: Border(right: BorderSide(color: ac.divider)),
          ),
          child: Center(
            child: state is PacienteError
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ac.red),
                    ),
                  )
                : CircularProgressIndicator(
                    color: ac.primaryBlue,
                    strokeWidth: 2,
                  ),
          ),
        );
      },
    );
  }

  void _onConsultaState(BuildContext context, ConsultaState state) {
    if (state is ConsultaIniciada || state is ConsultaGuardando) {
      setState(() => _enWorkspace = true);
    } else if (state is ConsultaTerminada) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Consulta finalizada con éxito.'),
          backgroundColor: context.appColors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      final cuentaId = state.cuentaId;
      if (cuentaId != null) {
        // Se reemplaza la consulta ya cerrada por la pre-factura para que
        // "atrás" no vuelva a ella. Se pasa `result: true` a la ruta que se
        // reemplaza: así los llamadores que esperaban ese `true` (p. ej.
        // consultas_list_page) refrescan su lista.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => PreFacturaPage(cuentaId: cuentaId)),
          result: true,
        );
      } else {
        Navigator.of(context).pop(true);
      }
    } else if (state is ConsultaError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: context.appColors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}

class _FloatingBar extends StatelessWidget {
  const _FloatingBar({required this.enWorkspace});
  final bool enWorkspace;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    final subtitle = enWorkspace
        ? 'Registra tratamientos y notas clínicas'
        : 'Completa la evaluación para iniciar';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 16, 14),
        decoration: BoxDecoration(
          color: ac.cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _BackButton(ac: ac),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Efectuar Consulta',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: ac.textPrimary,
                          letterSpacing: -0.5,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: ac.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: enWorkspace
                      ? _StatusBadge(
                          key: const ValueKey('ws'),
                          icon: Icons.radio_button_checked_rounded,
                          label: 'En curso',
                          color: ac.green,
                          ac: ac,
                        )
                      : _StatusBadge(
                          key: const ValueKey('ev'),
                          icon: Icons.assignment_outlined,
                          label: 'Evaluación',
                          color: ac.primaryBlue,
                          ac: ac,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _StepRow(enWorkspace: enWorkspace, ac: ac),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.ac});
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).maybePop(),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: ac.chipBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          size: 18,
          color: ac.textSecondary,
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.enWorkspace, required this.ac});
  final bool enWorkspace;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepPill(
          number: '01',
          label: 'Evaluación',
          active: !enWorkspace,
          done: enWorkspace,
          ac: ac,
        ),
        Expanded(
          child: _StepConnector(done: enWorkspace, ac: ac),
        ),
        _StepPill(
          number: '02',
          label: 'Consulta',
          active: enWorkspace,
          done: false,
          ac: ac,
        ),
      ],
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({
    required this.number,
    required this.label,
    required this.active,
    required this.done,
    required this.ac,
  });

  final String number;
  final String label;
  final bool active;
  final bool done;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Color textColor;

    if (done) {
      bg = ac.green.withValues(alpha: 0.12);
      fg = ac.green;
      textColor = ac.green;
    } else if (active) {
      bg = ac.primaryBlue;
      fg = Colors.white;
      textColor = ac.textPrimary;
    } else {
      bg = ac.chipBg;
      fg = ac.textMuted;
      textColor = ac.textMuted;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: done
              ? Icon(Icons.check_rounded, size: 14, color: ac.green)
              : Text(
                  number,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: fg,
                    height: 1,
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active || done ? FontWeight.w700 : FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector({required this.done, required this.ac});
  final bool done;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            height: 2,
            decoration: BoxDecoration(
              color: ac.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            widthFactor: done ? 1.0 : 0.0,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: ac.green,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.ac,
  });

  final IconData icon;
  final String label;
  final Color color;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
