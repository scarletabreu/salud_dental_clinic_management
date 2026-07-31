import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_state.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/formulario_evaluacion.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/panel_paciente.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/workspace_consulta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/pages/pre_factura_page.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/pages/paciente_form_page.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/cubit/plan_tratamiento_cubit.dart';

class EfectuarConsultaPage extends StatefulWidget {
  final String? citaId;
  final String pacienteId;
  final String doctorId;
  final String? consultaId;

  /// Motivo declarado al agendar la cita, para prellenar la evaluación.
  final String? motivoCita;

  const EfectuarConsultaPage({
    super.key,
    required this.citaId,
    required this.pacienteId,
    required this.doctorId,
    this.consultaId,
    this.motivoCita,
  });

  @override
  State<EfectuarConsultaPage> createState() => _EfectuarConsultaPageState();
}

class _EfectuarConsultaPageState extends State<EfectuarConsultaPage> {
  bool _enWorkspace = false;
  bool _hasInitialTriggered = false;
  bool _hasLoadedParaConsulta = false;
  bool? _registroIncompleto;

  /// Último fallo clínico sin resolver. Vive en la pantalla y no en un
  /// snackbar: desaparece cuando el usuario lo descarta o cuando una operación
  /// posterior confirma, nunca por un temporizador.
  String? _fallo;

  /// La consulta ya está cerrada en el servidor. No se sigue editando.
  String? _consultaCerrada;
  Paciente?
  _pacienteParaForm; // <-- NUEVO: copia local, inmune a emits del cubit
  late final PacienteCubit _pacienteCubit;

  @override
  void initState() {
    super.initState();
    _enWorkspace = widget.consultaId != null;
    _pacienteCubit = sl<PacienteCubit>();
    _verificarRegistro();
  }

  Future<void> _verificarRegistro() async {
    final completo = await _pacienteCubit.isPaciente(widget.pacienteId);

    if (!completo) {
      await _pacienteCubit.loadParaConsulta(widget.pacienteId);
      final s = _pacienteCubit.state;
      if (s is PacienteDetailLoaded) {
        _pacienteParaForm = s.paciente;
      }
    }

    if (mounted) {
      setState(() => _registroIncompleto = !completo);
    }
  }

  @override
  void dispose() {
    _pacienteCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _pacienteCubit),
        BlocProvider(create: (_) => sl<ConsultaCubit>()),
        // El plan vive junto a la consulta que lo origina (SD-135): se propone
        // y se decide con el paciente delante.
        BlocProvider(create: (_) => sl<PlanTratamientoCubit>()),
      ],
      child: Builder(
        builder: (innerContext) {
          if (widget.consultaId != null && !_hasInitialTriggered) {
            _hasInitialTriggered = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!innerContext.mounted) return;
              innerContext.read<ConsultaCubit>().reanudarConsulta(
                consultaId: widget.consultaId!,
              );
            });
          }

          if (_registroIncompleto == null) {
            return Scaffold(
              backgroundColor: ac.bgPage,
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          // Gate: falta completar la ficha clínica antes de evaluar/consultar.
          if (_registroIncompleto == true) {
            if (_pacienteParaForm == null) {
              return Scaffold(
                backgroundColor: ac.bgPage,
                body: const Center(child: CircularProgressIndicator()),
              );
            }
            return Scaffold(
              backgroundColor: ac.bgPage,
              body: PacienteFormPage(
                paciente: _pacienteParaForm!,
                modo: PacienteFormModo.completarRegistro,
                onCompletado: () => setState(() => _registroIncompleto = false),
              ),
            );
          }

          // Ya confirmado que es paciente: recién aquí se carga/crea para consulta.
          if (!_hasLoadedParaConsulta) {
            _hasLoadedParaConsulta = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!innerContext.mounted) return;
              innerContext.read<PacienteCubit>().loadParaConsulta(
                widget.pacienteId,
              );
            });
          }

          // Only the desktop layout can afford a 300 px patient card next to
          // the workspace; everywhere else the odontogram needs the full width
          // and the record moves into a drawer reachable from the header.
          final panelInline = innerContext.appLayout.isDesktop;

          return Scaffold(
            backgroundColor: ac.bgPage,
            endDrawer: panelInline
                ? null
                : Drawer(
                    width: math.min(
                      360,
                      MediaQuery.sizeOf(innerContext).width * 0.92,
                    ),
                    backgroundColor: ac.cardBg,
                    child: SafeArea(child: _buildPanel(ac, asSidebar: false)),
                  ),
            body: BlocListener<ConsultaCubit, ConsultaState>(
              listener: _onConsultaState,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FloatingBar(
                    enWorkspace: _enWorkspace,
                    showPacienteAction: !panelInline,
                  ),
                  if (_fallo case final mensaje?)
                    _BannerFallo(
                      mensaje: mensaje,
                      onDescartar: () => setState(() => _fallo = null),
                    ),
                  const SizedBox(height: 12),
                  if (_consultaCerrada case final mensaje?)
                    Expanded(child: _PanelConsultaCerrada(mensaje: mensaje))
                  else
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (panelInline) _buildPanel(ac),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 280),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
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
                                      motivoCita: widget.motivoCita,
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

  Widget _buildPanel(AppColors ac, {bool asSidebar = true}) {
    return BlocBuilder<PacienteCubit, PacienteState>(
      builder: (context, state) {
        if (state is PacienteDetailLoaded) {
          return PanelPaciente(paciente: state.paciente, asSidebar: asSidebar);
        }
        return Container(
          width: asSidebar ? 300 : null,
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
                    color: ac.primaryGreen,
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
    } else if (state is ConsultaCerradaEnServidor) {
      // No hay borrador que rescatar ni reintento posible: la pantalla deja de
      // ofrecer edición en vez de mostrar un aviso sobre un workspace muerto.
      setState(() => _consultaCerrada = state.mensaje);
    } else if (state is ConsultaError) {
      // El fallo se queda arriba de la pantalla hasta que el usuario lo
      // descarte o una operación posterior salga bien. Un snackbar de tres
      // segundos escondía el motivo por el que no se guardó una consulta.
      setState(() => _fallo = state.message);
    } else if (state is ConsultaIniciada && _fallo != null) {
      setState(() => _fallo = null);
    }
  }
}

/// Fallo clínico que espera una decisión. No se cierra solo.
class _BannerFallo extends StatelessWidget {
  const _BannerFallo({required this.mensaje, required this.onDescartar});

  final String mensaje;
  final VoidCallback onDescartar;

  static const clave = ValueKey('banner-fallo-consulta');

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        key: clave,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: ac.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ac.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, size: 18, color: ac.red),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensaje,
                style: TextStyle(
                  fontSize: 13,
                  color: ac.textPrimary,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(onPressed: onDescartar, child: const Text('Entendido')),
          ],
        ),
      ),
    );
  }
}

/// La consulta cerró: aquí ya no se edita nada.
class _PanelConsultaCerrada extends StatelessWidget {
  const _PanelConsultaCerrada({required this.mensaje});

  final String mensaje;

  static const clave = ValueKey('panel-consulta-cerrada');

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return Center(
      key: clave,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded, size: 40, color: ac.textMuted),
              const SizedBox(height: 14),
              Text(
                'Esta consulta ya está finalizada',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: ac.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: ac.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Volver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingBar extends StatelessWidget {
  const _FloatingBar({
    required this.enWorkspace,
    this.showPacienteAction = false,
  });
  final bool enWorkspace;
  final bool showPacienteAction;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final layout = context.appLayout;

    final subtitle = enWorkspace
        ? 'Diagnostica, planifica y registra tratamientos sin salir'
        : 'Completa el contexto clínico para continuar';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        layout.isNarrow ? 8 : 16,
        MediaQuery.of(context).padding.top + 12,
        layout.isNarrow ? 8 : 16,
        0,
      ),
      child: Container(
        padding: layout.isCompact
            ? const EdgeInsets.fromLTRB(12, 12, 10, 12)
            : const EdgeInsets.fromLTRB(18, 16, 16, 14),
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
                        'Consulta clínica',
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
                // At 320 px the badge and the record button cannot both sit
                // next to the title without squeezing it out of the bar.
                if (!layout.isNarrow)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: enWorkspace
                        ? _StatusBadge(
                            key: const ValueKey('ws'),
                            icon: Icons.radio_button_checked_rounded,
                            label: 'En consulta',
                            color: ac.green,
                            ac: ac,
                          )
                        : _StatusBadge(
                            key: const ValueKey('ev'),
                            icon: Icons.assignment_outlined,
                            label: 'Consulta',
                            color: ac.teal,
                            ac: ac,
                          ),
                  ),
                if (showPacienteAction) ...[
                  const SizedBox(width: 6),
                  _PanelPacienteButton(ac: ac),
                ],
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

/// Opens the patient record when it is not docked beside the workspace.
class _PanelPacienteButton extends StatelessWidget {
  const _PanelPacienteButton({required this.ac});
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ficha del paciente',
      child: InkWell(
        key: const ValueKey('abrir-panel-paciente'),
        onTap: Scaffold.of(context).openEndDrawer,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: ac.chipBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.badge_outlined, size: 19, color: ac.primaryGreen),
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
        Flexible(
          child: _StepPill(
            number: '01',
            label: 'Datos iniciales',
            active: !enWorkspace,
            done: enWorkspace,
            ac: ac,
          ),
        ),
        // El conector es lo primero que cede: nunca baja de 16 px.
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 16),
            child: _StepConnector(done: enWorkspace, ac: ac),
          ),
        ),
        Flexible(
          child: _StepPill(
            number: '02',
            label: 'Consulta clínica',
            active: enWorkspace,
            done: false,
            ac: ac,
          ),
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
      bg = ac.primaryGreen;
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
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active || done ? FontWeight.w700 : FontWeight.w500,
              color: textColor,
            ),
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
