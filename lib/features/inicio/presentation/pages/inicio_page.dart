import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/cubit/dashboard_cubit.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/cubit/dashboard_state.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/widgets/dashboard_citas_hoy_section.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/widgets/dashboard_header_card.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/widgets/dashboard_metric_card.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/widgets/dashboard_quick_action_card.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    // MediaQuery instead of LayoutBuilder — avoids scroll+layout conflicts
    final isNarrow = MediaQuery.sizeOf(context).width < 700;

    return ColoredBox(
      color: colorScheme.surfaceContainerLowest,
      child: SafeArea(
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is DashboardError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No se pudo cargar el dashboard',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () => context.read<DashboardCubit>().load(),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            final loaded = state as DashboardLoaded;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopSection(
                    isNarrow: isNarrow,
                    loaded: loaded,
                    onVerCitas: onNavigateToCitas,
                  ),
                  const SizedBox(height: 12),
                  _BottomMetricsRow(loaded: loaded),
                  const SizedBox(height: 12),
                  _QuickActionsSection(
                    onNavigateToCitas: onNavigateToCitas,
                    onNavigateToPacientes: onNavigateToPacientes,
                    onNavigateToMedicinas: onNavigateToMedicinas,
                  ),
                  const SizedBox(height: 12),
                  DashboardCitasHoySection(citas: loaded.citasDeHoy),
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

// ─── Sección superior: Header + 3 métricas de citas ───────────────────────

class _TopSection extends StatelessWidget {
  final bool isNarrow;
  final DashboardLoaded loaded;
  final VoidCallback? onVerCitas;

  const _TopSection({
    required this.isNarrow,
    required this.loaded,
    this.onVerCitas,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final metricCards = [
      DashboardMetricCard(
        icon: Icons.hourglass_empty_rounded,
        label: 'En espera',
        value: '${loaded.citasEnEspera}',
        accentColor: Colors.amber.shade700,
      ),
      DashboardMetricCard(
        icon: Icons.check_circle_outline_rounded,
        label: 'Completadas',
        value: '${loaded.citasCompletadas}',
        accentColor: Colors.green.shade600,
      ),
    ];

    final header = DashboardHeaderCard(onVerCitas: onVerCitas);

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: metricCards[0]),
              const SizedBox(width: 12),
              Expanded(child: metricCards[1]),
            ],
          ),
        ],
      );
    }

    // Wide: header left (flex 2), 3 metric cards stacked right (flex 1)
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: header),
          const SizedBox(width: 12),
          SizedBox(
            width: 160,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(child: metricCards[0]),
                const SizedBox(height: 12),
                Expanded(child: metricCards[1]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Fila inferior: Pacientes + Medicinas ─────────────────────────────────

class _BottomMetricsRow extends StatelessWidget {
  final DashboardLoaded loaded;

  const _BottomMetricsRow({required this.loaded});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: DashboardMetricCard(
            icon: Icons.people_alt_rounded,
            label: 'Pacientes activos',
            value: '${loaded.totalPacientes}',
            accentColor: colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DashboardMetricCard(
            icon: Icons.medication_rounded,
            label: 'Medicinas en catálogo',
            value: '${loaded.totalMedicinas}',
            accentColor: colorScheme.tertiary,
          ),
        ),
      ],
    );
  }
}

// ─── Accesos Rápidos ──────────────────────────────────────────────────────

class _QuickActionsSection extends StatelessWidget {
  final VoidCallback? onNavigateToCitas;
  final VoidCallback? onNavigateToPacientes;
  final VoidCallback? onNavigateToMedicinas;

  const _QuickActionsSection({
    this.onNavigateToCitas,
    this.onNavigateToPacientes,
    this.onNavigateToMedicinas,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accesos Rápidos',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DashboardQuickActionCard(
                  icon: Icons.people_alt_rounded,
                  label: 'Pacientes',
                  onTap: onNavigateToPacientes ?? () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DashboardQuickActionCard(
                  icon: Icons.today_rounded,
                  label: 'Mis Citas',
                  onTap: onNavigateToCitas ?? () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DashboardQuickActionCard(
                  icon: Icons.medication_rounded,
                  label: 'Medicinas',
                  onTap: onNavigateToMedicinas ?? () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
