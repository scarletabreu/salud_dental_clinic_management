import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';

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
        height: 200,
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
                  // El gráfico se redibuja en cada frame de su animación de
                  // entrada. Sin esta frontera, esos repintados arrastran a
                  // toda la capa del inicio —tarjetas, sombras y listas— que
                  // no ha cambiado en nada.
                  child: RepaintBoundary(
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
