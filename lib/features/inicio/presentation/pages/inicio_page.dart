import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/cubit/dashboard_cubit.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/cubit/dashboard_state.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/widgets/dashboard_citas_hoy_section.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/widgets/dashboard_header_card.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/widgets/dashboard_metric_card.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/widgets/dashboard_quick_action_card.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/widgets/siguiente_paciente_card.dart';

class InicioPage extends StatelessWidget {
  final VoidCallback? onNavigateToCitas;
  final VoidCallback? onNavigateToPacientes;
  final VoidCallback? onNavigateToMedicinas;

  const InicioPage({
    super.key,
    this.onNavigateToCitas,
    this.onNavigateToPacientes,
    this.onNavigateToMedicinas,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final isNarrow = MediaQuery.sizeOf(context).width < 700;

    return ColoredBox(
      color: ac.bgPage,
      child: SafeArea(
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: ac.primaryBlue,
                  strokeWidth: 2,
                ),
              );
            }

            if (state is DashboardError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: ac.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No se pudo cargar el dashboard',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ac.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.read<DashboardCubit>().load(),
                      style: FilledButton.styleFrom(
                        backgroundColor: ac.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            final loaded = state as DashboardLoaded;

            final enEsperaHoy = loaded.citasDeHoy
                .where((c) => c.estado == EstadoCita.enEspera)
                .toList();
            final siguiente =
                enEsperaHoy.isNotEmpty ? enEsperaHoy.first : null;

            void cambiarEstado(String id, EstadoCita estado) =>
                context.read<DashboardCubit>().updateEstado(id, estado);

            final citasRestantes =
                loaded.citasPendientes + loaded.citasEnEspera;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DashboardHeaderCard(
                    onVerCitas: onNavigateToCitas,
                    nombreDoctor: loaded.nombreDoctor,
                    citasHoy: loaded.citasHoy,
                    citasEnEspera: loaded.citasEnEspera,
                  ),
                  const SizedBox(height: 16),

                  _MetricsGrid(loaded: loaded, isNarrow: isNarrow),
                  const SizedBox(height: 16),

                  SiguientePacienteCard(
                    cita: siguiente,
                    onCambiarEstado: siguiente?.id != null
                        ? (estado) => cambiarEstado(siguiente!.id!, estado)
                        : null,
                  ),
                  const SizedBox(height: 16),

                  _QuickActionsSection(
                    onNavigateToCitas: onNavigateToCitas,
                    onNavigateToPacientes: onNavigateToPacientes,
                    onNavigateToMedicinas: onNavigateToMedicinas,
                    citasRestantes: citasRestantes,
                    totalPacientes: loaded.totalPacientes,
                  ),
                  const SizedBox(height: 16),

                  DashboardCitasHoySection(
                    citas: loaded.citasDeHoy,
                    onCambiarEstado: (id, estado) => cambiarEstado(id, estado),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Métricas responsivas ─────────────────────────────────────────────────────

class _MetricsGrid extends StatelessWidget {
  final DashboardLoaded loaded;
  final bool isNarrow;

  const _MetricsGrid({required this.loaded, required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    final enEspera = DashboardMetricCard(
      icon: Icons.hourglass_empty_rounded,
      label: 'En espera',
      value: '${loaded.citasEnEspera}',
      accentColor: ac.amber,
    );
    final completadas = DashboardMetricCard(
      icon: Icons.check_circle_outline_rounded,
      label: 'Completadas',
      value: '${loaded.citasCompletadas}',
      accentColor: ac.green,
    );
    final pendientes = DashboardMetricCard(
      icon: Icons.pending_actions_rounded,
      label: 'Pendientes',
      value: '${loaded.citasPendientes}',
      accentColor: ac.indigo,
    );
    final pacientes = DashboardMetricCard(
      icon: Icons.people_alt_rounded,
      label: 'Pacientes',
      value: '${loaded.totalPacientes}',
      accentColor: ac.teal,
    );
    final medicinas = DashboardMetricCard(
      icon: Icons.medication_rounded,
      label: 'Medicinas',
      value: '${loaded.totalMedicinas}',
      accentColor: ac.purple,
    );

    if (!isNarrow) {
      return Row(
        children: [
          Expanded(child: enEspera),
          const SizedBox(width: 12),
          Expanded(child: completadas),
          const SizedBox(width: 12),
          Expanded(child: pendientes),
          const SizedBox(width: 12),
          Expanded(child: pacientes),
          const SizedBox(width: 12),
          Expanded(child: medicinas),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: enEspera),
            const SizedBox(width: 12),
            Expanded(child: completadas),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: pendientes),
            const SizedBox(width: 12),
            Expanded(child: pacientes),
            const SizedBox(width: 12),
            Expanded(child: medicinas),
          ],
        ),
      ],
    );
  }
}

// ─── Accesos rápidos ──────────────────────────────────────────────────────────

class _QuickActionsSection extends StatelessWidget {
  final VoidCallback? onNavigateToCitas;
  final VoidCallback? onNavigateToPacientes;
  final VoidCallback? onNavigateToMedicinas;
  final int citasRestantes;
  final int totalPacientes;

  const _QuickActionsSection({
    this.onNavigateToCitas,
    this.onNavigateToPacientes,
    this.onNavigateToMedicinas,
    required this.citasRestantes,
    required this.totalPacientes,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [ac.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Text(
              'Accesos Rápidos',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: ac.textPrimary,
              ),
            ),
          ),
          Divider(height: 1, color: ac.divider),
          DashboardQuickActionCard(
            icon: Icons.people_alt_rounded,
            label: 'Pacientes',
            onTap: onNavigateToPacientes ?? () {},
            badge: totalPacientes > 0 ? '$totalPacientes' : null,
          ),
          Divider(height: 1, color: ac.divider, indent: 68),
          DashboardQuickActionCard(
            icon: Icons.today_rounded,
            label: 'Mis Citas',
            onTap: onNavigateToCitas ?? () {},
            badge: citasRestantes > 0 ? '$citasRestantes restantes' : null,
          ),
          Divider(height: 1, color: ac.divider, indent: 68),
          DashboardQuickActionCard(
            icon: Icons.medication_rounded,
            label: 'Medicinas',
            onTap: onNavigateToMedicinas ?? () {},
          ),
        ],
      ),
    );
  }
}
