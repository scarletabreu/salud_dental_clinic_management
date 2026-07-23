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
    this.onNavigateToCierreCaja,
  });

  final VoidCallback? onNavigateToCitas;
  final VoidCallback? onNavigateToPacientes;
  final VoidCallback? onNavigateToMedicinas;
  final VoidCallback? onNavigateToCierreCaja;
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

                  isNarrow
                      ? Column(
                          children: [
                            _DayDistributionChart(
                              pendientes: loaded.citasPendientes,
                              enEspera: loaded.citasEnEspera,
                              completadas: loaded.citasCompletadas,
                            ),
                            const SizedBox(height: 16),
                            _WeeklyBarChart(ac: ac),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _DayDistributionChart(
                                pendientes: loaded.citasPendientes,
                                enEspera: loaded.citasEnEspera,
                                completadas: loaded.citasCompletadas,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(flex: 7, child: _WeeklyBarChart(ac: ac)),
                          ],
                        ),
                  const SizedBox(height: 16),

                  _MonthlyTrendChart(ac: ac),
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
    final metrics = <Widget>[
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
      if (loaded.isAdmin || loaded.isDoctor)
        DashboardMetricCard(
          icon: Icons.people_alt_rounded,
          label: 'Pacientes',
          value: '${loaded.totalPacientes}',
          accentColor: ac.teal,
        ),
      if (loaded.isAdmin || loaded.isDoctor)
        DashboardMetricCard(
          icon: Icons.medication_rounded,
          label: 'Medicinas',
          value: '${loaded.totalMedicinas}',
          accentColor: ac.purple,
        ),
    ];

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

class _DayDistributionChart extends StatefulWidget {
  final int pendientes;
  final int enEspera;
  final int completadas;

  const _DayDistributionChart({
    required this.pendientes,
    required this.enEspera,
    required this.completadas,
  });

  @override
  State<_DayDistributionChart> createState() => _DayDistributionChartState();
}

class _DayDistributionChartState extends State<_DayDistributionChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final total = widget.pendientes + widget.enEspera + widget.completadas;

    final sections = <_ChartSection>[
      _ChartSection('En espera', widget.enEspera, ac.amber),
      _ChartSection('Completadas', widget.completadas, ac.green),
      _ChartSection('Pendientes', widget.pendientes, ac.indigo),
    ].where((s) => s.value > 0).toList();

    return _ChartCard(
      title: 'Estado de hoy',
      subtitle: 'Distribución de citas',
      child: total == 0
          ? _EmptyChart(message: 'Sin citas registradas para hoy')
          : Row(
              children: [
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 48,
                            startDegreeOffset: -90,
                            pieTouchData: PieTouchData(
                              touchCallback: (event, response) {
                                setState(() {
                                  _touchedIndex =
                                      response
                                          ?.touchedSection
                                          ?.touchedSectionIndex ??
                                      -1;
                                });
                              },
                            ),
                            sections: List.generate(sections.length, (i) {
                              final s = sections[i];
                              final touched = _touchedIndex == i;
                              return PieChartSectionData(
                                color: s.color,
                                value: s.value.toDouble(),
                                radius: touched ? 26 : 20,
                                title: touched ? '${s.value}' : '',
                                titleStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$total',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: ac.textPrimary,
                                height: 1,
                              ),
                            ),
                            Text(
                              'citas',
                              style: TextStyle(
                                fontSize: 11,
                                color: ac.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 6,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sections.map((s) {
                      final pct = total > 0 ? s.value / total : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: s.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    s.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ac.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${s.value}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: ac.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 5,
                                backgroundColor: s.color.withValues(
                                  alpha: 0.12,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  s.color,
                                ),
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
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart({required this.ac});
  final AppColors ac;

  static const _days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const _completadas = [8.0, 5.0, 9.0, 7.0, 11.0, 4.0, 2.0];
  static const _pendientes = [2.0, 3.0, 1.0, 4.0, 2.0, 1.0, 0.0];

  @override
  Widget build(BuildContext context) {
    final maxY =
        (_completadas
                    .asMap()
                    .entries
                    .map((e) => e.value + _pendientes[e.key])
                    .reduce((a, b) => a > b ? a : b) *
                1.25)
            .ceilToDouble();

    return _ChartCard(
      title: 'Esta semana',
      subtitle: 'Citas por día',
      legendItems: [
        _LegendItem(color: ac.green, label: 'Completadas'),
        _LegendItem(color: ac.indigo, label: 'Pendientes'),
      ],
      child: SizedBox(
        height: 160,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => ac.cardBg,
                tooltipBorder: BorderSide(color: ac.divider, width: 1),
                getTooltipItem: (group, gi, rod, ri) {
                  final label = ri == 0 ? 'Completadas' : 'Pendientes';
                  return BarTooltipItem(
                    '$label\n${rod.toY.toInt()}',
                    TextStyle(
                      color: ri == 0 ? ac.green : ac.indigo,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= _days.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _days[i],
                        style: TextStyle(
                          fontSize: 10,
                          color: ac.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                  reservedSize: 24,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: (maxY / 3).ceilToDouble(),
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox();
                    return Text(
                      '${value.toInt()}',
                      style: TextStyle(fontSize: 10, color: ac.textSecondary),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxY / 3).ceilToDouble(),
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: ac.divider, strokeWidth: 1, dashArray: [4, 4]),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(_days.length, (i) {
              return BarChartGroupData(
                x: i,
                barsSpace: 3,
                barRods: [
                  BarChartRodData(
                    toY: _completadas[i],
                    color: ac.green,
                    width: 9,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(5),
                    ),
                  ),
                  BarChartRodData(
                    toY: _pendientes[i],
                    color: ac.indigo.withValues(alpha: 0.55),
                    width: 9,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(5),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _MonthlyTrendChart extends StatelessWidget {
  const _MonthlyTrendChart({required this.ac});
  final AppColors ac;

  static const _weeks = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];
  static const _citasSemana = [32.0, 28.0, 41.0, 37.0];
  static const _nuevos = [5.0, 3.0, 8.0, 6.0];

  @override
  Widget build(BuildContext context) {
    final maxY = (_citasSemana.reduce((a, b) => a > b ? a : b) * 1.3)
        .ceilToDouble();

    return _ChartCard(
      title: 'Último mes',
      subtitle: 'Citas atendidas y pacientes nuevos por semana',
      legendItems: [
        _LegendItem(color: ac.primaryBlue, label: 'Citas atendidas'),
        _LegendItem(color: ac.teal, label: 'Pacientes nuevos', dashed: true),
      ],
      child: SizedBox(
        height: 170,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            clipData: const FlClipData.all(),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => ac.cardBg,
                tooltipBorder: BorderSide(color: ac.divider),
                getTooltipItems: (spots) => spots.map((spot) {
                  final isFirst = spot.barIndex == 0;
                  return LineTooltipItem(
                    '${isFirst ? 'Citas' : 'Nuevos'}: ${spot.y.toInt()}',
                    TextStyle(
                      color: isFirst ? ac.primaryBlue : ac.teal,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: 1.0,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (value != i.toDouble()) return const SizedBox();
                    if (i < 0 || i >= _weeks.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _weeks[i],
                        style: TextStyle(
                          fontSize: 10,
                          color: ac.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: (maxY / 4).ceilToDouble(),
                  getTitlesWidget: (value, _) {
                    if (value == 0) return const SizedBox();
                    return Text(
                      '${value.toInt()}',
                      style: TextStyle(fontSize: 10, color: ac.textSecondary),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxY / 4).ceilToDouble(),
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: ac.divider, strokeWidth: 1, dashArray: [4, 4]),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  _citasSemana.length,
                  (i) => FlSpot(i.toDouble(), _citasSemana[i]),
                ),
                isCurved: true,
                curveSmoothness: 0.35,
                color: ac.primaryBlue,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: ac.primaryBlue,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      ac.primaryBlue.withValues(alpha: 0.18),
                      ac.primaryBlue.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              LineChartBarData(
                spots: List.generate(
                  _nuevos.length,
                  (i) => FlSpot(i.toDouble(), _nuevos[i]),
                ),
                isCurved: true,
                curveSmoothness: 0.35,
                color: ac.teal,
                barWidth: 2,
                dashArray: [5, 4],
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                    radius: 3,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: ac.teal,
                  ),
                ),
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.legendItems,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<_LegendItem>? legendItems;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ac.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: ac.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (legendItems != null)
                Wrap(spacing: 14, children: legendItems!),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _ChartSection {
  const _ChartSection(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dashed
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 5, height: 2, color: color),
                  const SizedBox(width: 2),
                  Container(width: 5, height: 2, color: color),
                ],
              )
            : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: ac.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: ac.textSecondary, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
