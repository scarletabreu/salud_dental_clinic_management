import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/design_tokens.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'odontogram_widget.dart';

// ─────────────────────────────────────────────
//  Aggregate helper
// ─────────────────────────────────────────────

int _statusRank(Diente d) {
  final s = statusForDiente(d);
  return switch (s) {
    ToothStatus.critical => 4,
    ToothStatus.moderate => 3,
    ToothStatus.mild => 2,
    ToothStatus.treated => 1,
    ToothStatus.empty => 0,
  };
}

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
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextPrimary),
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
          color: onTap != null ? kTeal.withValues(alpha: 0.10) : const Color(0xFFF3F4F6),
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
      (ToothStatus.treated, 'Tratado'),
      (ToothStatus.mild, 'Leve'),
      (ToothStatus.moderate, 'Moderado'),
      (ToothStatus.critical, 'Grave'),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: items.map((item) {
        final color = colorForStatus(item.$1);
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
//  OdontogramArchWidget — multi-consultation wrapper
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
    return widget.consultas.where((c) => c.odontograma != null).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  @override
  Widget build(BuildContext context) {
    final withOdo = _withOdo;
    final clampedIdx = _idx.clamp(0, withOdo.isEmpty ? 0 : withOdo.length - 1);

    final Odontograma? currentOdo = withOdo.isEmpty
        ? null
        : _aggregate
            ? _buildAggregateOdontograma(withOdo)
            : withOdo[clampedIdx].odontograma;

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

          // Consultation navigation (only when not in aggregate mode)
          if (withOdo.length > 1 && !_aggregate) ...[
            const SizedBox(height: 14),
            _NavRow(
              current: clampedIdx,
              total: withOdo.length,
              fecha: withOdo[clampedIdx].fecha,
              onPrev: clampedIdx < withOdo.length - 1
                  ? () => setState(() => _idx = clampedIdx + 1)
                  : null,
              onNext: clampedIdx > 0 ? () => setState(() => _idx = clampedIdx - 1) : null,
            ),
          ] else if (_aggregate && withOdo.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${withOdo.length} consulta${withOdo.length > 1 ? 's' : ''} consolidada${withOdo.length > 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 11, color: kTextMuted, fontWeight: FontWeight.w500),
            ),
          ],

          const SizedBox(height: 12),
          const _Legend(),
          const SizedBox(height: 4),

          // Core widget — handles arch rendering + interaction
          OdontogramWidget(
            odontograma: currentOdo,
            editMode: false,
          ),
        ],
      ),
    );
  }
}
