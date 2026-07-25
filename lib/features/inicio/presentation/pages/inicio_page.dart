import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/cubit/dashboard_cubit.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/cubit/dashboard_state.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/widgets/dashboard_alert_center.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/widgets/dashboard_citas_hoy_section.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/widgets/dashboard_header_card.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/widgets/siguiente_paciente_card.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';

class InicioPage extends StatelessWidget {
  const InicioPage({
    super.key,
    this.onNavigateToCitas,
    this.onNavigateToPacientes,
    this.onNavigateToMedicinas,
    this.onNavigateToConfiguracion,
    this.onNavigateToInventario,
    this.onNavigateToCaja,
  });

  final VoidCallback? onNavigateToCitas;
  final VoidCallback? onNavigateToPacientes;
  final VoidCallback? onNavigateToMedicinas;
  final VoidCallback? onNavigateToConfiguracion;
  final VoidCallback? onNavigateToInventario;
  final VoidCallback? onNavigateToCaja;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

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
            final isNarrow = MediaQuery.sizeOf(context).width < 850;
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
                  // ── Header ───────────────────────────────────────────────
                  DashboardHeaderCard(
                    onVerCitas: onNavigateToCitas,
                    nombreDoctor: loaded.nombreDoctor,
                    citasHoy: loaded.citasHoy,
                    citasEnEspera: loaded.citasEnEspera,
                  ),
                  const SizedBox(height: 16),

                  // ── Centro de alertas ────────────────────────────────────
                  DashboardAlertCenter(
                    alertas: loaded.alertas,
                    rolesUsuario: loaded.roles,
                    onAlertaCita: onNavigateToCitas,
                    onAlertaConsumible: onNavigateToInventario,
                    onAlertaCaja: onNavigateToCaja,
                  ),
                  const SizedBox(height: 16),

                  // ── Fila 1 de gráficos de pastel: Hoy + Esta Semana ──────
                  if (isNarrow) ...[
                    _TodayPieChart(loaded: loaded, ac: ac),
                    const SizedBox(height: 16),
                    _WeeklyPieChart(loaded: loaded, ac: ac),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _TodayPieChart(loaded: loaded, ac: ac),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _WeeklyPieChart(loaded: loaded, ac: ac),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),

                  // ── Fila 2 de gráficos de pastel: Mes + Inventario ───────
                  if (isNarrow) ...[
                    _MonthlyPieChart(loaded: loaded, ac: ac),
                    if (loaded.tieneAccesoOperativo) ...[
                      const SizedBox(height: 16),
                      _InventoryPieChart(loaded: loaded, ac: ac),
                    ],
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _MonthlyPieChart(loaded: loaded, ac: ac),
                        ),
                        if (loaded.tieneAccesoOperativo) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: _InventoryPieChart(loaded: loaded, ac: ac),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),

                  // ── Siguiente paciente ────────────────────────────────────
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

                  // ── Resumen Operativo de Hoy ──────────────────────────────
                  _ResumenJornadaCard(loaded: loaded, ac: ac),
                  const SizedBox(height: 16),

                  // ── Lista citas de hoy ────────────────────────────────────
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

// ══════════════════════════════════════════════════════════════════════════
// RESUMEN DE LA JORNADA
// ══════════════════════════════════════════════════════════════════════════

class _ResumenJornadaCard extends StatelessWidget {
  const _ResumenJornadaCard({required this.loaded, required this.ac});

  final DashboardLoaded loaded;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    final total = loaded.citasHoy;
    final completadas = loaded.citasCompletadas;
    final porcentaje = total > 0 ? (completadas / total) : 0.0;

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
          Row(
            children: [
              Icon(
                Icons.assignment_turned_in_rounded,
                color: ac.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Estado Operativo de Hoy',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ac.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progreso de atenciones',
                      style: TextStyle(fontSize: 12, color: ac.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completadas de $total completadas (${(porcentaje * 100).toStringAsFixed(0)}%)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ac.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (loaded.citasEnEspera > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ac.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hourglass_empty_rounded,
                        size: 14,
                        color: ac.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${loaded.citasEnEspera} en espera',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ac.amber,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: porcentaje,
              minHeight: 8,
              backgroundColor: ac.primaryBlue.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(ac.green),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 1. PIE CHART: HOY
// ══════════════════════════════════════════════════════════════════════════

class _TodayPieChart extends StatelessWidget {
  final DashboardLoaded loaded;
  final AppColors ac;

  const _TodayPieChart({required this.loaded, required this.ac});

  @override
  Widget build(BuildContext context) {
    final allSections = [
      _ChartSection(
        'Completadas',
        loaded.citasCompletadas,
        ac.green,
        Icons.check_circle_rounded,
      ),
      _ChartSection(
        'En espera',
        loaded.citasEnEspera,
        ac.amber,
        Icons.hourglass_bottom_rounded,
      ),
      _ChartSection(
        'Pendientes',
        loaded.citasPendientes,
        ac.indigo,
        Icons.pending_actions_rounded,
      ),
      _ChartSection(
        'Canceladas',
        loaded.citasCanceladas,
        ac.red,
        Icons.cancel_rounded,
      ),
    ];

    final totalHoy =
        loaded.citasEnEspera +
        loaded.citasCompletadas +
        loaded.citasPendientes +
        loaded.citasCanceladas;

    return _PieCard(
      title: 'Citas de Hoy',
      subtitle: 'Distribución del día',
      total: totalHoy,
      unidad: 'citas',
      sections: allSections,
      emptyMessage: 'Sin citas para hoy',
      ac: ac,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 2. PIE CHART: ESTA SEMANA
// ══════════════════════════════════════════════════════════════════════════

class _WeeklyPieChart extends StatelessWidget {
  final DashboardLoaded loaded;
  final AppColors ac;

  const _WeeklyPieChart({required this.loaded, required this.ac});

  @override
  Widget build(BuildContext context) {
    final allSections = [
      _ChartSection(
        'Completadas',
        loaded.citasSemanaCompletadas,
        ac.green,
        Icons.check_circle_rounded,
      ),
      _ChartSection(
        'En espera',
        loaded.citasSemanaEnEspera,
        ac.amber,
        Icons.hourglass_bottom_rounded,
      ),
      _ChartSection(
        'Pendientes',
        loaded.citasSemanaPendientes,
        ac.indigo,
        Icons.pending_actions_rounded,
      ),
      _ChartSection(
        'Canceladas',
        loaded.citasSemanaCanceladas,
        ac.red,
        Icons.cancel_rounded,
      ),
    ];

    return _PieCard(
      title: 'Citas de la Semana',
      subtitle: 'Resumen semanal en curso',
      total: loaded.citasSemanaTotal,
      unidad: 'citas',
      sections: allSections,
      emptyMessage: 'Sin citas esta semana',
      ac: ac,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 3. PIE CHART: ESTE MES
// ══════════════════════════════════════════════════════════════════════════

class _MonthlyPieChart extends StatelessWidget {
  final DashboardLoaded loaded;
  final AppColors ac;

  const _MonthlyPieChart({required this.loaded, required this.ac});

  @override
  Widget build(BuildContext context) {
    final allSections = [
      _ChartSection(
        'Completadas',
        loaded.citasMesCompletadas,
        ac.green,
        Icons.check_circle_rounded,
      ),
      _ChartSection(
        'En espera',
        loaded.citasMesEnEspera,
        ac.amber,
        Icons.hourglass_bottom_rounded,
      ),
      _ChartSection(
        'Pendientes',
        loaded.citasMesPendientes,
        ac.indigo,
        Icons.pending_actions_rounded,
      ),
      _ChartSection(
        'Canceladas',
        loaded.citasMesCanceladas,
        ac.red,
        Icons.cancel_rounded,
      ),
    ];

    return _PieCard(
      title: 'Citas del Mes',
      subtitle: 'Distribución acumulada del mes',
      total: loaded.citasMesTotal,
      unidad: 'citas',
      sections: allSections,
      emptyMessage: 'Sin citas este mes',
      ac: ac,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 4. PIE CHART: INVENTARIO
// ══════════════════════════════════════════════════════════════════════════

class _InventoryPieChart extends StatelessWidget {
  final DashboardLoaded loaded;
  final AppColors ac;

  const _InventoryPieChart({required this.loaded, required this.ac});

  @override
  Widget build(BuildContext context) {
    final total =
        loaded.consumiblesNormal +
        loaded.consumiblesBajoStock +
        loaded.consumiblesAgotados;

    final allSections = [
      _ChartSection(
        'Stock normal',
        loaded.consumiblesNormal,
        ac.green,
        Icons.inventory_2_rounded,
      ),
      _ChartSection(
        'Stock bajo',
        loaded.consumiblesBajoStock,
        ac.amber,
        Icons.warning_rounded,
      ),
      _ChartSection(
        'Agotados',
        loaded.consumiblesAgotados,
        ac.red,
        Icons.remove_shopping_cart_rounded,
      ),
    ];

    return _PieCard(
      title: 'Estado de Inventario',
      subtitle: 'Balance actual de consumibles',
      total: total,
      unidad: 'items',
      sections: allSections,
      emptyMessage: 'Sin consumibles registrados',
      ac: ac,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// COMPONENTE REUTILIZABLE: PIE CARD (Estilo PieChartSample3)
// ══════════════════════════════════════════════════════════════════════════

class _PieCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final int total;
  final String unidad;
  final List<_ChartSection> sections;
  final String emptyMessage;
  final AppColors ac;

  const _PieCard({
    required this.title,
    required this.subtitle,
    required this.total,
    required this.unidad,
    required this.sections,
    required this.emptyMessage,
    required this.ac,
  });

  @override
  State<_PieCard> createState() => _PieCardState();
}

class _PieCardState extends State<_PieCard> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final ac = widget.ac;
    final activePieSections = widget.sections
        .where((s) => s.value > 0)
        .toList();

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
            widget.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ac.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.subtitle,
            style: TextStyle(fontSize: 12, color: ac.textSecondary),
          ),
          const SizedBox(height: 18),
          widget.total == 0 || activePieSections.isEmpty
              ? SizedBox(
                  height: 160,
                  child: Center(
                    child: Text(
                      widget.emptyMessage,
                      style: TextStyle(color: ac.textSecondary, fontSize: 13),
                    ),
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: SizedBox(
                        height: 170,
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (event, response) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      response == null ||
                                      response.touchedSection == null) {
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  _touchedIndex = response
                                      .touchedSection!
                                      .touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: 0,
                            sections: List.generate(activePieSections.length, (
                              i,
                            ) {
                              final isTouched = i == _touchedIndex;
                              final s = activePieSections[i];
                              final radius = isTouched ? 68.0 : 60.0;
                              final fontSize = isTouched ? 14.0 : 12.0;
                              final badgeSize = isTouched ? 32.0 : 26.0;
                              final pct = (s.value / widget.total * 100)
                                  .toStringAsFixed(0);

                              return PieChartSectionData(
                                color: s.color,
                                value: s.value.toDouble(),
                                title: '$pct%',
                                radius: radius,
                                titleStyle: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                badgeWidget: _BadgeIcon(
                                  icon: s.icon,
                                  size: badgeSize,
                                  color: s.color,
                                ),
                                badgePositionPercentageOffset: .98,
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 6,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: widget.sections.map((s) {
                          final pct = widget.total > 0
                              ? (s.value / widget.total * 100).toStringAsFixed(
                                  0,
                                )
                              : '0';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: s.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    s.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ac.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${s.value} ($pct%)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: ac.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({
    required this.icon,
    required this.size,
    required this.color,
  });

  final IconData icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 3),
        ],
      ),
      child: Center(
        child: Icon(icon, size: size * 0.55, color: color),
      ),
    );
  }
}

class _ChartSection {
  const _ChartSection(this.label, this.value, this.color, this.icon);
  final String label;
  final int value;
  final Color color;
  final IconData icon;
}
