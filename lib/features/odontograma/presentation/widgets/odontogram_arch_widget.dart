import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/design_tokens.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';

// ─────────────────────────────────────────────
//  Tooth status types
// ─────────────────────────────────────────────

enum _ToothStatus { empty, treated, mild, moderate, critical }

Color _colorFor(_ToothStatus s) => switch (s) {
      _ToothStatus.empty => const Color(0xFFD1D5DB),
      _ToothStatus.treated => kTeal,
      _ToothStatus.mild => kIndigo,
      _ToothStatus.moderate => kAmber,
      _ToothStatus.critical => kRed,
    };

// ─────────────────────────────────────────────
//  FDI tooth positions (normalized 0–1 in canvas)
// ─────────────────────────────────────────────

const Map<int, Offset> _kNorm = {
  // Q1 — upper right
  18: Offset(0.050, 0.070), 17: Offset(0.135, 0.138),
  16: Offset(0.216, 0.204), 15: Offset(0.290, 0.266),
  14: Offset(0.353, 0.320), 13: Offset(0.405, 0.362),
  12: Offset(0.447, 0.390), 11: Offset(0.480, 0.406),
  // Q2 — upper left
  21: Offset(0.520, 0.406), 22: Offset(0.553, 0.390),
  23: Offset(0.595, 0.362), 24: Offset(0.647, 0.320),
  25: Offset(0.710, 0.266), 26: Offset(0.784, 0.204),
  27: Offset(0.865, 0.138), 28: Offset(0.950, 0.070),
  // Q3 — lower left
  31: Offset(0.520, 0.594), 32: Offset(0.553, 0.610),
  33: Offset(0.595, 0.638), 34: Offset(0.647, 0.680),
  35: Offset(0.710, 0.734), 36: Offset(0.784, 0.796),
  37: Offset(0.865, 0.862), 38: Offset(0.950, 0.930),
  // Q4 — lower right
  41: Offset(0.480, 0.594), 42: Offset(0.447, 0.610),
  43: Offset(0.405, 0.638), 44: Offset(0.353, 0.680),
  45: Offset(0.290, 0.734), 46: Offset(0.216, 0.796),
  47: Offset(0.135, 0.862), 48: Offset(0.050, 0.930),
};

// ─────────────────────────────────────────────
//  Status map helpers
// ─────────────────────────────────────────────

_ToothStatus _statusForDiente(Diente d) {
  if (d.diagnosis.isNotEmpty) {
    var worst = SeveridadDiagnosis.leve;
    for (final diag in d.diagnosis) {
      if (diag.severidad == SeveridadDiagnosis.grave) return _ToothStatus.critical;
      if (diag.severidad == SeveridadDiagnosis.moderada) worst = SeveridadDiagnosis.moderada;
    }
    return worst == SeveridadDiagnosis.moderada ? _ToothStatus.moderate : _ToothStatus.mild;
  }
  if (d.tratamientos.isNotEmpty) return _ToothStatus.treated;
  if (d.superficies.any((s) => s.diagnosisId != null)) return _ToothStatus.mild;
  return _ToothStatus.empty;
}

_ToothStatus _worstOf(List<_ToothStatus> statuses) {
  const order = [
    _ToothStatus.critical,
    _ToothStatus.moderate,
    _ToothStatus.mild,
    _ToothStatus.treated,
    _ToothStatus.empty,
  ];
  for (final s in order) {
    if (statuses.contains(s)) return s;
  }
  return _ToothStatus.empty;
}

Map<int, _ToothStatus> _buildMap(List<Diente> dientes) {
  final map = <int, _ToothStatus>{};
  for (final d in dientes) {
    map[d.fdiCode] = _statusForDiente(d);
  }
  return map;
}

Map<int, _ToothStatus> _buildAggregateMap(List<Consulta> consultas) {
  final grouped = <int, List<_ToothStatus>>{};
  for (final c in consultas) {
    final odo = c.odontograma;
    if (odo == null) continue;
    for (final d in odo.dientes) {
      grouped.putIfAbsent(d.fdiCode, () => []).add(_statusForDiente(d));
    }
  }
  return grouped.map((code, statuses) => MapEntry(code, _worstOf(statuses)));
}

// ─────────────────────────────────────────────
//  CustomPainter
// ─────────────────────────────────────────────

class _ArchPainter extends CustomPainter {
  final Map<int, _ToothStatus> toothStatus;
  const _ArchPainter(this.toothStatus);

  @override
  void paint(Canvas canvas, Size size) {
    final toothW = size.width * 0.060;
    final toothH = size.height * 0.086;
    const r = Radius.circular(4);

    // Subtle jaw separator line
    final sepY = size.height * 0.500;
    canvas.drawLine(
      Offset(size.width * 0.08, sepY),
      Offset(size.width * 0.92, sepY),
      Paint()
        ..color = const Color(0xFFE5E7EB)
        ..strokeWidth = 1.0,
    );

    for (final entry in _kNorm.entries) {
      final fdi = entry.key;
      final norm = entry.value;
      final status = toothStatus[fdi] ?? _ToothStatus.empty;
      final color = _colorFor(status);
      final center = Offset(norm.dx * size.width, norm.dy * size.height);
      final rect = Rect.fromCenter(center: center, width: toothW, height: toothH);
      final rrect = RRect.fromRectAndRadius(rect, r);

      // Fill
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = status == _ToothStatus.empty
              ? const Color(0xFFF3F4F6)
              : color.withValues(alpha: 0.14),
      );

      // Border
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = status == _ToothStatus.empty
              ? const Color(0xFFD1D5DB)
              : color.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );

      // FDI number
      final tp = TextPainter(
        text: TextSpan(
          text: fdi.toString(),
          style: TextStyle(
            fontSize: toothW * 0.40,
            fontWeight: FontWeight.w600,
            color: status == _ToothStatus.empty ? kTextDisabled : color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        center - Offset(tp.width / 2, tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_ArchPainter old) => old.toothStatus != toothStatus;
}

// ─────────────────────────────────────────────
//  Navigation helper row
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
    const m = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _NavBtn(icon: Icons.chevron_left_rounded, onTap: onPrev),
        const SizedBox(width: 8),
        Text(
          '${current + 1} / $total',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: kTextPrimary,
          ),
        ),
        const SizedBox(width: 8),
        _NavBtn(icon: Icons.chevron_right_rounded, onTap: onNext),
        const SizedBox(width: 12),
        Text(
          _fmt(fecha),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTextMuted),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onTap != null
              ? kTeal.withValues(alpha: 0.10)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? kTeal : kTextDisabled,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Legend
// ─────────────────────────────────────────────

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    const items = [
      (_ToothStatus.treated, 'Tratado'),
      (_ToothStatus.mild, 'Leve'),
      (_ToothStatus.moderate, 'Moderado'),
      (_ToothStatus.critical, 'Grave'),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: items.map((item) {
        final color = _colorFor(item.$1);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: color.withValues(alpha: 0.60), width: 1.2),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              item.$2,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: kTextMuted),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────
//  Toggle pill
// ─────────────────────────────────────────────

class _TogglePill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TogglePill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? kTeal : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : kTextMuted,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Main widget
// ─────────────────────────────────────────────

class OdontogramArchWidget extends StatefulWidget {
  final List<Consulta> consultas;
  const OdontogramArchWidget({super.key, required this.consultas});

  @override
  State<OdontogramArchWidget> createState() => _OdontogramArchWidgetState();
}

class _OdontogramArchWidgetState extends State<OdontogramArchWidget> {
  bool _aggregate = false;
  int _idx = 0;

  List<Consulta> get _withOdo {
    final list = widget.consultas.where((c) => c.odontograma != null).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final withOdo = _withOdo;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: [kCardShadow],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kTeal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.medical_services_outlined, size: 18, color: kTeal),
              ),
              const SizedBox(width: 12),
              const Text(
                'Odontograma',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kTextPrimary),
              ),
              const Spacer(),
              if (withOdo.length > 1)
                _TogglePill(
                  label: 'Vista General',
                  active: _aggregate,
                  onTap: () => setState(() => _aggregate = !_aggregate),
                ),
            ],
          ),

          if (withOdo.isEmpty) ...[
            const SizedBox(height: 32),
            const Center(
              child: Column(
                children: [
                  Icon(Icons.medical_services_outlined, size: 32, color: Color(0xFFD1D5DB)),
                  SizedBox(height: 8),
                  Text(
                    'Sin odontograma registrado',
                    style: TextStyle(fontSize: 13, color: kTextDisabled, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ] else ...[
            // Navigation row (only if showing specific consulta)
            if (!_aggregate) ...[
              const SizedBox(height: 14),
              _NavRow(
                current: _idx.clamp(0, withOdo.length - 1),
                total: withOdo.length,
                fecha: withOdo[_idx.clamp(0, withOdo.length - 1)].fecha,
                onPrev: _idx < withOdo.length - 1
                    ? () => setState(() => _idx++)
                    : null,
                onNext: _idx > 0 ? () => setState(() => _idx--) : null,
              ),
            ] else ...[
              const SizedBox(height: 6),
              Text(
                '${withOdo.length} consulta${withOdo.length > 1 ? 's' : ''} consolidada${withOdo.length > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 11, color: kTextMuted, fontWeight: FontWeight.w500),
              ),
            ],

            const SizedBox(height: 14),
            const _Legend(),
            const SizedBox(height: 16),

            // Arch
            AspectRatio(
              aspectRatio: 1.22,
              child: CustomPaint(
                painter: _ArchPainter(
                  _aggregate
                      ? _buildAggregateMap(withOdo)
                      : _buildMap(
                          withOdo[_idx.clamp(0, withOdo.length - 1)]
                              .odontograma!
                              .dientes,
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
