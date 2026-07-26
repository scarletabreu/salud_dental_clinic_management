import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/historial_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/proyeccion_odontograma.dart';
import 'odontogram_widget.dart';
import 'vistas_odontograma.dart';

// ─────────────────────────────────────────────
//  Aggregate helper
// ─────────────────────────────────────────────

int _statusRank(Diente d) {
  // Una pieza perdida se dibuja como sana (`empty`) pero no lo está: si no
  // gana el resumen, la consulta siguiente la borra del expediente.
  if (dienteEstaAusente(d)) return 5;
  final s = statusForDiente(d);
  return switch (s) {
    ToothStatus.critical => 4,
    ToothStatus.moderate => 3,
    ToothStatus.mild => 2,
    ToothStatus.treated => 1,
    ToothStatus.historico => 1,
    ToothStatus.empty => 0,
  };
}

/// Consolida el historial en un solo odontograma. [consultas] llega de la más
/// reciente a la más antigua: los tratamientos se resumen por gravedad y el
/// odontodiagrama se queda con la última anotación de cada pieza y tejido.
Odontograma _buildAggregateOdontograma(List<Consulta> consultas) {
  final Map<int, Diente> worst = {};

  for (final c in consultas) {
    final odo = c.odontograma;
    if (odo == null) continue;
    for (final d in odo.dientes) {
      final existing = worst[d.fdiCode];
      if (existing == null || _statusRank(d) > _statusRank(existing)) {
        worst[d.fdiCode] = d;
      }
    }
  }

  return Odontograma(
    consultaId: '',
    dientes: worst.values.toList(),
    // Las piezas salen de la proyección de [dientes]; de `evaluacion` solo
    // sobreviven los tejidos blandos, que no cuelgan de ninguna pieza.
    evaluacion: EvaluacionOdontologica.consolidar(
      consultas.map((c) => c.odontograma?.evaluacion).nonNulls,
    ),
  );
}

/// El odontograma de [consultas]`[indice]` con la capa histórica que le
/// corresponde: todo lo anotado en las consultas *anteriores* a esa. Como la
/// lista llega de la más reciente a la más antigua, lo anterior es la cola.
Odontograma _conHistorico(List<Consulta> consultas, int indice) {
  final odontograma = consultas[indice].odontograma!;
  // La capa histórica se lee de la proyección, igual que el dibujo: tras la
  // unificación `evaluacion` ya no guarda hallazgos por pieza.
  final anteriores = consultas
      .skip(indice + 1)
      .map((c) => c.odontograma?.evaluacionComoAntecedente)
      .nonNulls;
  return odontograma.copyWith(
    // Lo que ya está anotado hoy no se repite en tenue debajo.
    evaluacionHistorica: EvaluacionOdontologica.consolidar(
      anteriores,
    ).menos(odontograma.evaluacionProyectada),
  );
}

// ─────────────────────────────────────────────
//  Navigation row
// ─────────────────────────────────────────────

class _NavRow extends StatelessWidget {
  final int current;
  final int total;
  final DateTime fecha;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _NavRow({
    required this.current,
    required this.total,
    required this.fecha,
    required this.onPrev,
    required this.onNext,
  });

  String _fmt(DateTime d) {
    const m = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Row(
      children: [
        _NavBtn(icon: Icons.chevron_left_rounded, onTap: onPrev),
        const SizedBox(width: 8),
        Text(
          '${current + 1} / $total',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: ac.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        _NavBtn(icon: Icons.chevron_right_rounded, onTap: onNext),
        const SizedBox(width: 12),
        Text(
          _fmt(fecha),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: ac.textMuted,
          ),
        ),
      ],
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onTap != null ? ac.teal.withValues(alpha: 0.10) : ac.chipBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? ac.teal : ac.textDisabled,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Legend
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
//  Toggle pill
// ─────────────────────────────────────────────

class _TogglePill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TogglePill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? ac.teal : ac.chipBg,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : ac.textMuted,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  OdontogramArchWidget — multi-consultation wrapper
// ─────────────────────────────────────────────

class OdontogramArchWidget extends StatefulWidget {
  final List<Consulta> consultas;

  /// El historial no se pudo leer. Sin esto, un fallo de carga y un paciente
  /// nuevo se ven exactamente igual —«no tiene consultas»— y el doctor no sabe
  /// que le falta información.
  final bool historialNoDisponible;

  /// La línea de tiempo de cada pieza (SD-144). Es lo que permite que tocar un
  /// diente cuente su historia completa aunque se esté mirando la Vista
  /// General, que por definición se queda con una sola anotación por pieza.
  final HistorialPiezas? historialPiezas;

  const OdontogramArchWidget({
    super.key,
    required this.consultas,
    this.historialNoDisponible = false,
    this.historialPiezas,
  });

  @override
  State<OdontogramArchWidget> createState() => _OdontogramArchWidgetState();
}

class _OdontogramArchWidgetState extends State<OdontogramArchWidget> {
  bool _aggregate = false;
  int _idx = 0;

  List<Consulta> get _withOdo {
    return widget.consultas.where((c) => c.odontograma != null).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final withOdo = _withOdo;
    final clampedIdx = _idx.clamp(0, withOdo.isEmpty ? 0 : withOdo.length - 1);

    final Odontograma? currentOdo = withOdo.isEmpty
        ? null
        : _aggregate
        ? _buildAggregateOdontograma(withOdo)
        : _conHistorico(withOdo, clampedIdx);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        boxShadow: [ac.cardShadow],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: ac.teal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.medical_services_outlined,
                  size: 18,
                  color: ac.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Odontograma',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ac.textPrimary,
                  ),
                ),
              ),
              if (withOdo.length > 1)
                _TogglePill(
                  label: 'Vista General',
                  active: _aggregate,
                  onTap: () => setState(() => _aggregate = !_aggregate),
                ),
            ],
          ),

          if (withOdo.length > 1 && !_aggregate) ...[
            const SizedBox(height: 14),
            _NavRow(
              current: clampedIdx,
              total: withOdo.length,
              fecha: withOdo[clampedIdx].fecha,
              onPrev: clampedIdx < withOdo.length - 1
                  ? () => setState(() => _idx = clampedIdx + 1)
                  : null,
              onNext: clampedIdx > 0
                  ? () => setState(() => _idx = clampedIdx - 1)
                  : null,
            ),
          ] else if (_aggregate && withOdo.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${withOdo.length} consulta${withOdo.length > 1 ? 's' : ''} consolidada${withOdo.length > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 11,
                color: ac.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          if (currentOdo == null) ...[
            const SizedBox(height: 20),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      widget.historialNoDisponible
                          ? Icons.cloud_off_rounded
                          : Icons.medical_information_outlined,
                      size: 28,
                      color: ac.textDisabled,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.historialNoDisponible
                          ? 'No se pudo cargar el historial clínico.'
                          : 'Este paciente aún no tiene consultas con '
                                'odontograma.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.historialNoDisponible
                            ? ac.textSecondary
                            : ac.textMuted,
                      ),
                    ),
                    if (widget.historialNoDisponible) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Revisa la conexión y vuelve a abrir el expediente.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: ac.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            // La leyenda ya no se dibuja aquí: la trae cada vista desde
            // `LeyendaOdontograma`, con el mismo vocabulario que el color de
            // las piezas. La que había aquí describía una escala de severidad
            // que la arcada dejó de usar.
            VistasOdontograma(
              odontograma: currentOdo,
              historialPiezas: widget.historialPiezas,
            ),
          ],
        ],
      ),
    );
  }
}
