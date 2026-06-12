import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
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
    final ac = context.appColors;
    return Row(
      children: [
        _NavBtn(icon: Icons.chevron_left_rounded, onTap: onPrev),
        const SizedBox(width: 8),
        Text(
          '${current + 1} / $total',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ac.textPrimary),
        ),
        const SizedBox(width: 8),
        _NavBtn(icon: Icons.chevron_right_rounded, onTap: onNext),
        const SizedBox(width: 12),
        Text(
          _fmt(fecha),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ac.textMuted),
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

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
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
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: ac.textMuted),
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
    final ac = context.appColors;
    final withOdo = _withOdo;
    final clampedIdx = _idx.clamp(0, withOdo.isEmpty ? 0 : withOdo.length - 1);

    final Odontograma? currentOdo = withOdo.isEmpty
        ? null
        : _aggregate
            ? _buildAggregateOdontograma(withOdo)
            : withOdo[clampedIdx].odontograma;

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
                child: Icon(Icons.medical_services_outlined, size: 18, color: ac.teal),
              ),
              const SizedBox(width: 12),
              Text(
                'Odontograma',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ac.textPrimary),
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
              style: TextStyle(fontSize: 11, color: ac.textMuted, fontWeight: FontWeight.w500),
            ),
          ],

          if (currentOdo == null) ...[
            const SizedBox(height: 20),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Este paciente aún no tiene consultas con odontograma.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: ac.textMuted,
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            const _Legend(),
            const SizedBox(height: 4),

            OdontogramWidget(
              odontograma: currentOdo,
              editMode: false,
            ),
          ],
        ],
      ),
    );
  }
}
