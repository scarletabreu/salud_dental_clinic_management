import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/cubit/dashboard_cubit.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/cubit/dashboard_state.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/widgets/dashboard_citas_hoy_section.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/widgets/dashboard_header_card.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/widgets/dashboard_metric_card.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/widgets/dashboard_quick_action_card.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/widgets/siguiente_paciente_card.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';

class InicioPage extends StatelessWidget {
  const InicioPage({
    super.key,
    this.onNavigateToCitas,
    this.onNavigateToPacientes,
    this.onNavigateToMedicinas,
    this.onNavigateToConfiguracion,
  });

  final VoidCallback? onNavigateToCitas;
  final VoidCallback? onNavigateToPacientes;
  final VoidCallback? onNavigateToMedicinas;
  final VoidCallback? onNavigateToConfiguracion;

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
              return _buildErrorWidget(context, ac);
            }

            if (state is! DashboardLoaded) return const SizedBox.shrink();

            final loaded = state;
            final enEsperaHoy = loaded.citasDeHoy
                .where((c) => c.estado == EstadoCita.enEspera)
                .toList();
            final siguientePaciente = enEsperaHoy.isNotEmpty
                ? enEsperaHoy.first
                : null;

            void cambiarEstado(String id, EstadoCita estado) =>
                context.read<DashboardCubit>().updateEstado(id, estado);

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

                  _buildMetricsGrid(loaded, isNarrow, ac),
                  const SizedBox(height: 16),

                  DashboardCitasChart(
                    pendientes: loaded.citasPendientes,
                    enEspera: loaded.citasEnEspera,
                    completadas: loaded.citasCompletadas,
                  ),
                  const SizedBox(height: 16),

                  if (loaded.isDoctor || loaded.isAdmin) ...[
                    SiguientePacienteCard(
                      cita: siguientePaciente,
                      onCambiarEstado: siguientePaciente?.id != null
                          ? (estado) =>
                                cambiarEstado(siguientePaciente!.id!, estado)
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildQuickActions(loaded, ac),
                  const SizedBox(height: 16),

                  DashboardCitasHoySection(
                    citas: loaded.citasDeHoy,
                    onCambiarEstado: cambiarEstado,
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

  Widget _buildMetricsGrid(
    DashboardLoaded loaded,
    bool isNarrow,
    AppColors ac,
  ) {
    final List<Widget> metrics = [
      DashboardMetricCard(
        icon: Icons.hourglass_empty_rounded,
        label: 'En espera',
        value: '${loaded.citasEnEspera}',
        accentColor: ac.amber,
      ),
      DashboardMetricCard(
        icon: Icons.check_circle_outline_rounded,
        label: 'Completadas',
        value: '${loaded.citasCompletadas}',
        accentColor: ac.green,
      ),
      DashboardMetricCard(
        icon: Icons.pending_actions_rounded,
        label: 'Pendientes',
        value: '${loaded.citasPendientes}',
        accentColor: ac.indigo,
      ),
    ];

    if (loaded.isAdmin || loaded.isDoctor) {
      metrics.add(
        DashboardMetricCard(
          icon: Icons.people_alt_rounded,
          label: 'Pacientes',
          value: '${loaded.totalPacientes}',
          accentColor: ac.teal,
        ),
      );
    }

    if (loaded.isAdmin || loaded.isDoctor) {
      metrics.add(
        DashboardMetricCard(
          icon: Icons.medication_rounded,
          label: 'Medicinas',
          value: '${loaded.totalMedicinas}',
          accentColor: ac.purple,
        ),
      );
    }

    if (!isNarrow) {
      return Row(
        children: [
          for (int i = 0; i < metrics.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: metrics[i]),
          ],
        ],
      );
    }

    final firstRow = metrics.take(2).toList();
    final secondRow = metrics.skip(2).toList();

    return Column(
      children: [
        Row(
          children: [
            for (int i = 0; i < firstRow.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: firstRow[i]),
            ],
          ],
        ),
        if (secondRow.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              for (int i = 0; i < secondRow.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: secondRow[i]),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildQuickActions(DashboardLoaded loaded, AppColors ac) {
    final citasRestantes = loaded.citasPendientes + loaded.citasEnEspera;

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
            badge: loaded.totalPacientes > 0
                ? '${loaded.totalPacientes}'
                : null,
          ),
          Divider(height: 1, color: ac.divider, indent: 68),

          DashboardQuickActionCard(
            icon: Icons.today_rounded,
            label: loaded.isDoctor ? 'Mis Citas' : 'Control de Citas',
            onTap: onNavigateToCitas ?? () {},
            badge: citasRestantes > 0 ? '$citasRestantes activas' : null,
          ),

          if (loaded.isAdmin || loaded.isDoctor) ...[
            Divider(height: 1, color: ac.divider, indent: 68),
            DashboardQuickActionCard(
              icon: Icons.medication_rounded,
              label: 'Catálogo de Medicinas',
              onTap: onNavigateToMedicinas ?? () {},
            ),
          ],

          if (loaded.isAdmin) ...[
            Divider(height: 1, color: ac.divider, indent: 68),
            DashboardQuickActionCard(
              icon: Icons.settings_rounded,
              label: 'Configuración del Sistema',
              onTap: onNavigateToConfiguracion ?? () {},
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, AppColors ac) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: ac.red),
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
            onPressed: () {
              final authState = context.read<AuthCubit>().state;
              final usuario = authState.usuario;
              context.read<DashboardCubit>().load(
                roles: authState.roles,
                doctorId: usuario is Doctor ? usuario.id : null,
                doctorName: usuario is Doctor
                    ? '${usuario.nombre} ${usuario.apellido}'
                    : null,
              );
            },
            style: FilledButton.styleFrom(backgroundColor: ac.primaryBlue),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class DashboardCitasChart extends StatelessWidget {
  final int pendientes;
  final int enEspera;
  final int completadas;

  const DashboardCitasChart({
    super.key,
    required this.pendientes,
    required this.enEspera,
    required this.completadas,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final total = pendientes + enEspera + completadas;

    if (total == 0) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: ac.cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [ac.cardShadow],
        ),
        child: Center(
          child: Text(
            'Sin actividad de citas para el día de hoy',
            style: TextStyle(color: ac.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [ac.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribución de Citas de Hoy',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ac.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 140,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 45,
                      startDegreeOffset: -90,
                      sections: [
                        if (enEspera > 0)
                          PieChartSectionData(
                            color: ac.amber,
                            value: enEspera.toDouble(),
                            title: '$enEspera',
                            radius: 18,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        if (completadas > 0)
                          PieChartSectionData(
                            color: ac.green,
                            value: completadas.toDouble(),
                            title: '$completadas',
                            radius: 18,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        if (pendientes > 0)
                          PieChartSectionData(
                            color: ac.indigo,
                            value: pendientes.toDouble(),
                            title: '$pendientes',
                            radius: 18,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Indicator(color: ac.amber, text: 'En espera ($enEspera)'),
                    const SizedBox(height: 8),
                    _Indicator(
                      color: ac.green,
                      text: 'Completadas ($completadas)',
                    ),
                    const SizedBox(height: 8),
                    _Indicator(
                      color: ac.indigo,
                      text: 'Pendientes ($pendientes)',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  final Color color;
  final String text;

  const _Indicator({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: ac.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
