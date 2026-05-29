import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/design_tokens.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/entities/superficie.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'tooth_geometry.dart';

// ─────────────────────────────────────────────
//  Tooth status
// ─────────────────────────────────────────────

enum ToothStatus { empty, treated, mild, moderate, critical }

Color colorForStatus(ToothStatus s) => switch (s) {
      ToothStatus.empty => const Color(0xFFCBD5E1),
      ToothStatus.treated => kTeal,
      ToothStatus.mild => kIndigo,
      ToothStatus.moderate => kAmber,
      ToothStatus.critical => kRed,
    };

ToothStatus statusForDiente(Diente? d) {
  if (d == null) return ToothStatus.empty;
  if (d.estaAusente) return ToothStatus.empty;
  if (d.diagnosis.isNotEmpty) {
    var worst = SeveridadDiagnosis.leve;
    for (final diag in d.diagnosis) {
      if (diag.severidad == SeveridadDiagnosis.grave) return ToothStatus.critical;
      if (diag.severidad == SeveridadDiagnosis.moderada) worst = SeveridadDiagnosis.moderada;
    }
    return worst == SeveridadDiagnosis.moderada ? ToothStatus.moderate : ToothStatus.mild;
  }
  if (d.tratamientos.isNotEmpty) return ToothStatus.treated;
  if (d.superficies.any((s) => s.diagnosisId != null)) return ToothStatus.mild;
  return ToothStatus.empty;
}

// ─────────────────────────────────────────────
//  CustomPainter
// ─────────────────────────────────────────────

class _OdontogramPainter extends CustomPainter {
  final Map<int, Diente> dientes;
  final int? selectedFdi;
  final int? hoveredFdi;

  const _OdontogramPainter({
    required this.dientes,
    this.selectedFdi,
    this.hoveredFdi,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final layout = archLayout(size);
    final labelFontSize = size.width * 0.052 * 0.42;

    // Subtle vertical midline guide
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.10),
      Offset(size.width / 2, size.height * 0.90),
      Paint()
        ..color = const Color(0xFFEEF2F7)
        ..strokeWidth = 1.0,
    );

    layout.forEach((fdi, p) {
      final type = toothTypeFor(fdi);
      final upper = isUpperTooth(fdi);
      final d = dientes[fdi];
      final status = statusForDiente(d);
      final isAbsent = d?.estaAusente ?? false;
      final isSelected = fdi == selectedFdi;
      final isHovered = fdi == hoveredFdi && !isSelected;
      final hasStatus = status != ToothStatus.empty && !isAbsent;
      final statusColor = isAbsent ? const Color(0xFFCBD5E1) : colorForStatus(status);

      final path = buildToothPath(type, p.size);
      final groove = buildGroovePath(type, p.size, upper: upper);

      canvas.save();
      canvas.translate(p.center.dx, p.center.dy);
      canvas.rotate(p.angle);

      // Fill — white base, tinted by status / interaction
      final fillColor = isAbsent
          ? const Color(0xFFF1F5F9)
          : isSelected
              ? statusColor.withAlpha(48)
              : isHovered
                  ? statusColor.withAlpha(hasStatus ? 42 : 22)
                  : hasStatus
                      ? statusColor.withAlpha(30)
                      : Colors.white;
      canvas.drawPath(path, Paint()..color = fillColor);

      // Occlusal grooves
      if (groove != null && !isAbsent) {
        canvas.drawPath(
          groove,
          Paint()
            ..color = (hasStatus ? statusColor : const Color(0xFFCBD5E1))
                .withAlpha(hasStatus ? 140 : 255)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }

      // Outline
      final outlineColor = isAbsent
          ? const Color(0xFFCBD5E1)
          : (isSelected || isHovered || hasStatus)
              ? statusColor
              : kTextDisabled;
      final strokeWidth = isSelected
          ? 2.2
          : isHovered
              ? 1.8
              : (hasStatus ? 1.5 : 1.2);
      final strokeAlpha = isSelected
          ? 255
          : isHovered
              ? 220
              : (hasStatus ? 200 : 150);
      canvas.drawPath(
        path,
        Paint()
          ..color = outlineColor.withAlpha(strokeAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeJoin = StrokeJoin.round,
      );

      // Absent tooth: X mark
      if (isAbsent) {
        final xPaint = Paint()
          ..color = const Color(0xFFCBD5E1)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round;
        final mx = p.size.width * 0.30;
        final my = p.size.height * 0.30;
        canvas.drawLine(Offset(-mx, -my), Offset(mx, my), xPaint);
        canvas.drawLine(Offset(mx, -my), Offset(-mx, my), xPaint);
      }

      canvas.restore();
    });

    // FDI labels — outside the arch, always horizontal
    layout.forEach((fdi, p) {
      final d = dientes[fdi];
      final status = statusForDiente(d);
      final isAbsent = d?.estaAusente ?? false;
      final isSelected = fdi == selectedFdi;
      final hasStatus = status != ToothStatus.empty && !isAbsent;
      final statusColor = isAbsent ? const Color(0xFFCBD5E1) : colorForStatus(status);

      final tp = TextPainter(
        text: TextSpan(
          text: fdi.toString(),
          style: TextStyle(
            fontSize: labelFontSize,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? statusColor
                : hasStatus
                    ? statusColor.withAlpha(200)
                    : kTextDisabled,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        p.labelPos.translate(-tp.width / 2, -tp.height / 2),
      );
    });
  }

  @override
  bool shouldRepaint(_OdontogramPainter old) =>
      old.dientes != dientes ||
      old.selectedFdi != selectedFdi ||
      old.hoveredFdi != hoveredFdi;
}

// ─────────────────────────────────────────────
//  Surface detail panel
// ─────────────────────────────────────────────

class _ToothDetailPanel extends StatefulWidget {
  final int fdi;
  final Diente? diente;
  final bool editMode;
  final VoidCallback onClose;
  final void Function(Diente, TipoSuperficie?)? onAddDiagnosis;
  final void Function(Diente, TipoSuperficie?)? onAddTratamiento;
  final void Function(Diente, bool)? onToggleAusente;

  const _ToothDetailPanel({
    super.key,
    required this.fdi,
    required this.diente,
    required this.editMode,
    required this.onClose,
    this.onAddDiagnosis,
    this.onAddTratamiento,
    this.onToggleAusente,
  });

  @override
  State<_ToothDetailPanel> createState() => _ToothDetailPanelState();
}

class _ToothDetailPanelState extends State<_ToothDetailPanel> {
  TipoSuperficie? _selectedSurface;

  @override
  Widget build(BuildContext context) {
    final name = kFdiNames[widget.fdi] ?? 'Diente ${widget.fdi}';
    final d = widget.diente;
    final isAbsent = d?.estaAusente ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgPage,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colorForStatus(statusForDiente(d)).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text(
                    '${widget.fdi}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colorForStatus(statusForDiente(d)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                ),
              ),
              if (widget.editMode && d != null)
                GestureDetector(
                  onTap: () => widget.onToggleAusente?.call(d, !isAbsent),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAbsent
                          ? kTeal.withValues(alpha: 0.10)
                          : kRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      isAbsent ? 'Restaurar' : 'Ausente',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isAbsent ? kTeal : kRed.withValues(alpha: 0.70),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.close_rounded, size: 15, color: kTextMuted),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: kDivider),
          const SizedBox(height: 16),

          // Surface map — centered
          Center(
            child: _SurfaceMap(
              fdi: widget.fdi,
              diente: d,
              editMode: widget.editMode,
              selectedSurface: _selectedSurface,
              onSurfaceSelected: (s) => setState(() {
                _selectedSurface = (_selectedSurface == s) ? null : s;
              }),
            ),
          ),
          const SizedBox(height: 16),

          // Clinical data
          _ToothInfoPanel(
            diente: d,
            editMode: widget.editMode,
            selectedSurface: _selectedSurface,
            onAddDiagnosis: widget.onAddDiagnosis,
            onAddTratamiento: widget.onAddTratamiento,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Surface map — classic connected 5-zone tooth cell
//  (Vestibular / Mesial / Distal / Lingual·Palatina / Oclusal·Incisal)
// ─────────────────────────────────────────────

class _SurfaceMap extends StatelessWidget {
  final int fdi;
  final Diente? diente;
  final bool editMode;
  final TipoSuperficie? selectedSurface;
  final ValueChanged<TipoSuperficie> onSurfaceSelected;

  const _SurfaceMap({
    required this.fdi,
    required this.diente,
    required this.editMode,
    required this.selectedSurface,
    required this.onSurfaceSelected,
  });

  static const double _size = 152;
  static const double _a = 0.32; // inner square edges
  static const double _b = 0.68;

  Map<TipoSuperficie, Superficie> _surfaceMap() {
    if (diente == null) return {};
    return {for (final s in diente!.superficies) s.tipoSuperficie: s};
  }

  TipoSuperficie get _centerSurface =>
      isAnteriorTooth(fdi) ? TipoSuperficie.incisal : TipoSuperficie.oclusal;
  TipoSuperficie get _bottomSurface =>
      isUpperTooth(fdi) ? TipoSuperficie.palatina : TipoSuperficie.lingual;

  TipoSuperficie? _regionAt(Offset p) {
    final x = p.dx / _size;
    final y = p.dy / _size;
    if (x < 0 || x > 1 || y < 0 || y > 1) return null;
    if (x >= _a && x <= _b && y >= _a && y <= _b) return _centerSurface;
    if (y < x && y < 1 - x) return TipoSuperficie.vestibular;
    if (y > x && y > 1 - x) return _bottomSurface;
    if (x < y && x < 1 - y) return TipoSuperficie.mesial;
    return TipoSuperficie.distal;
  }

  @override
  Widget build(BuildContext context) {
    Widget map = CustomPaint(
      size: const Size(_size, _size),
      painter: _SurfaceMapPainter(
        surfaces: _surfaceMap(),
        centerSurface: _centerSurface,
        bottomSurface: _bottomSurface,
        selected: selectedSurface,
        a: _a,
        b: _b,
      ),
    );

    if (editMode) {
      map = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapUp: (d) {
            final s = _regionAt(d.localPosition);
            if (s != null) onSurfaceSelected(s);
          },
          child: map,
        ),
      );
    }

    return SizedBox(width: _size, height: _size, child: map);
  }
}

class _SurfaceMapPainter extends CustomPainter {
  final Map<TipoSuperficie, Superficie> surfaces;
  final TipoSuperficie centerSurface;
  final TipoSuperficie bottomSurface;
  final TipoSuperficie? selected;
  final double a;
  final double b;

  const _SurfaceMapPainter({
    required this.surfaces,
    required this.centerSurface,
    required this.bottomSurface,
    required this.selected,
    required this.a,
    required this.b,
  });

  Color _baseColor(TipoSuperficie t) {
    final s = surfaces[t];
    if (s == null) return Colors.white;
    if (s.diagnosisId != null) return kAmber;
    if (s.tratamientos.isNotEmpty) return kTeal;
    return Colors.white;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final tl = Offset.zero;
    final tr = Offset(w, 0);
    final bl = Offset(0, h);
    final br = Offset(w, h);
    final itl = Offset(a * w, a * h);
    final itr = Offset(b * w, a * h);
    final ibl = Offset(a * w, b * h);
    final ibr = Offset(b * w, b * h);

    final regions = <TipoSuperficie, List<Offset>>{
      TipoSuperficie.vestibular: [tl, tr, itr, itl],
      bottomSurface: [bl, br, ibr, ibl],
      TipoSuperficie.mesial: [tl, itl, ibl, bl],
      TipoSuperficie.distal: [tr, itr, ibr, br],
      centerSurface: [itl, itr, ibr, ibl],
    };

    final labels = <TipoSuperficie, (String, Offset)>{
      TipoSuperficie.vestibular: ('V', Offset(w * 0.5, h * 0.16)),
      bottomSurface: (
        bottomSurface == TipoSuperficie.palatina ? 'P' : 'L',
        Offset(w * 0.5, h * 0.84),
      ),
      TipoSuperficie.mesial: ('M', Offset(w * 0.16, h * 0.5)),
      TipoSuperficie.distal: ('D', Offset(w * 0.84, h * 0.5)),
      centerSurface: (
        centerSurface == TipoSuperficie.incisal ? 'I' : 'O',
        Offset(w * 0.5, h * 0.5),
      ),
    };

    regions.forEach((t, poly) {
      final path = Path()..addPolygon(poly, true);
      final isSel = selected == t;
      final base = _baseColor(t);
      final hasData = base != Colors.white;

      canvas.drawPath(
        path,
        Paint()
          ..color = isSel
              ? kTeal.withAlpha(38)
              : hasData
                  ? base.withAlpha(46)
                  : Colors.white,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = isSel
              ? kTeal
              : hasData
                  ? base.withAlpha(150)
                  : const Color(0xFFE5E7EB)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSel ? 2.0 : 1.2
          ..strokeJoin = StrokeJoin.round,
      );
    });

    labels.forEach((t, lbl) {
      final isSel = selected == t;
      final base = _baseColor(t);
      final hasData = base != Colors.white;
      final tp = TextPainter(
        text: TextSpan(
          text: lbl.$1,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSel
                ? kTeal
                : hasData
                    ? base
                    : kTextDisabled,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, lbl.$2.translate(-tp.width / 2, -tp.height / 2));
    });
  }

  @override
  bool shouldRepaint(_SurfaceMapPainter old) =>
      old.surfaces != surfaces ||
      old.selected != selected ||
      old.centerSurface != centerSurface ||
      old.bottomSurface != bottomSurface;
}

// ─────────────────────────────────────────────
//  Tooth info panel (diagnosis + treatment lists)
// ─────────────────────────────────────────────

class _ToothInfoPanel extends StatelessWidget {
  final Diente? diente;
  final bool editMode;
  final TipoSuperficie? selectedSurface;
  final void Function(Diente, TipoSuperficie?)? onAddDiagnosis;
  final void Function(Diente, TipoSuperficie?)? onAddTratamiento;

  const _ToothInfoPanel({
    required this.diente,
    required this.editMode,
    required this.selectedSurface,
    required this.onAddDiagnosis,
    required this.onAddTratamiento,
  });

  @override
  Widget build(BuildContext context) {
    final d = diente;
    if (d == null || (d.diagnosis.isEmpty && d.tratamientos.isEmpty && !editMode)) {
      return const Text(
        'Sin datos registrados',
        style: TextStyle(fontSize: 12, color: kTextDisabled),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (d.diagnosis.isNotEmpty) ...[
          const Text(
            'DIAGNÓSTICOS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: kTextMuted,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 5,
            children: d.diagnosis.map((diag) {
              final color = switch (diag.severidad) {
                SeveridadDiagnosis.grave => kRed,
                SeveridadDiagnosis.moderada => kAmber,
                SeveridadDiagnosis.leve => kIndigo,
              };
              final label = switch (diag.severidad) {
                SeveridadDiagnosis.grave => 'Grave',
                SeveridadDiagnosis.moderada => 'Moderado',
                SeveridadDiagnosis.leve => 'Leve',
              };
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (d.tratamientos.isNotEmpty) const SizedBox(height: 12),
        ],
        if (d.tratamientos.isNotEmpty) ...[
          const Text(
            'TRATAMIENTOS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: kTextMuted,
            ),
          ),
          const SizedBox(height: 6),
          ...d.tratamientos.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    t.estaTerminado
                        ? Icons.check_circle_outline_rounded
                        : Icons.pending_outlined,
                    size: 14,
                    color: t.estaTerminado ? kGreen : kAmber,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      t.esContinuo ? 'Tratamiento continuo' : 'Tratamiento puntual',
                      style: const TextStyle(fontSize: 12, color: kTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (d.observaciones != null && d.observaciones!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            d.observaciones!,
            style: const TextStyle(
              fontSize: 12,
              color: kTextMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        if (editMode) ...[
          const SizedBox(height: 14),
          const Divider(height: 1, color: kDivider),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  onAddDiagnosis?.call(d, selectedSurface);
                  _showComingSoon(context);
                },
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text('Diagnóstico'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kIndigo,
                  side: BorderSide(color: kIndigo.withValues(alpha: 0.40)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  onAddTratamiento?.call(d, selectedSurface);
                  _showComingSoon(context);
                },
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text('Tratamiento'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kTeal,
                  side: BorderSide(color: kTeal.withValues(alpha: 0.40)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Próximamente disponible')),
    );
  }
}

// ─────────────────────────────────────────────
//  Main widget
// ─────────────────────────────────────────────

class OdontogramWidget extends StatefulWidget {
  final Odontograma? odontograma;
  final bool editMode;
  final ValueChanged<Diente>? onToothSelected;
  final void Function(Diente, TipoSuperficie?)? onAddDiagnosis;
  final void Function(Diente, TipoSuperficie?)? onAddTratamiento;
  final void Function(Diente, bool ausente)? onToggleAusente;

  const OdontogramWidget({
    super.key,
    this.odontograma,
    this.editMode = false,
    this.onToothSelected,
    this.onAddDiagnosis,
    this.onAddTratamiento,
    this.onToggleAusente,
  });

  @override
  State<OdontogramWidget> createState() => _OdontogramWidgetState();
}

class _OdontogramWidgetState extends State<OdontogramWidget> {
  int? _selectedFdi;
  int? _hoveredFdi;
  Size _canvasSize = Size.zero;

  Map<int, Diente> get _dienteMap {
    final odo = widget.odontograma;
    if (odo == null) return {};
    return {for (final d in odo.dientes) d.fdiCode: d};
  }

  Diente? _getDiente(int fdi) => _dienteMap[fdi];

  int? _fdiAtPosition(Offset pos, {double hitScale = 1.4}) {
    if (_canvasSize == Size.zero) return null;
    final layout = archLayout(_canvasSize);
    for (final entry in layout.entries) {
      final p = entry.value;
      final hitRect = Rect.fromCenter(
        center: p.center,
        width: p.size.width * hitScale,
        height: p.size.height * hitScale,
      );
      if (hitRect.contains(pos)) return entry.key;
    }
    return null;
  }

  /// Teeth on the viewer's left half of the arch (quadrants 1 & 4).
  bool _isLeftHalf(int fdi) =>
      (fdi >= 11 && fdi <= 18) || (fdi >= 41 && fdi <= 48);

  Widget _buildArch(double w, double h) {
    return MouseRegion(
      cursor: _hoveredFdi != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onHover: (e) {
        final fdi = _fdiAtPosition(e.localPosition, hitScale: 1.0);
        if (fdi != _hoveredFdi) setState(() => _hoveredFdi = fdi);
      },
      onExit: (_) {
        if (_hoveredFdi != null) setState(() => _hoveredFdi = null);
      },
      child: GestureDetector(
        onTapUp: (details) {
          final fdi = _fdiAtPosition(details.localPosition, hitScale: 1.5);
          setState(() {
            _selectedFdi = fdi == _selectedFdi ? null : fdi;
          });
          if (fdi != null) {
            final d = _getDiente(fdi);
            if (d != null) widget.onToothSelected?.call(d);
          }
        },
        child: CustomPaint(
          size: Size(w, h),
          painter: _OdontogramPainter(
            dientes: _dienteMap,
            selectedFdi: _selectedFdi,
            hoveredFdi: _hoveredFdi,
          ),
        ),
      ),
    );
  }

  Widget _buildPanel() => _ToothDetailPanel(
        key: ValueKey(_selectedFdi),
        fdi: _selectedFdi!,
        diente: _getDiente(_selectedFdi!),
        editMode: widget.editMode,
        onClose: () => setState(() => _selectedFdi = null),
        onAddDiagnosis: widget.onAddDiagnosis,
        onAddTratamiento: widget.onAddTratamiento,
        onToggleAusente: widget.onToggleAusente,
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final maxW = constraints.maxWidth;
        const sideMin = 300.0;
        const panelMaxW = 360.0;
        // Side layout only when there's room for the arch + a panel on each side.
        final useSide = _selectedFdi != null && maxW >= 520 + 2 * sideMin;

        final archW = useSide
            ? math.min(560.0, maxW - 2 * sideMin)
            : math.min(maxW, 560.0);
        final archH = archW * 0.95;
        _canvasSize = Size(archW, archH);

        final arch = SizedBox(
          width: archW,
          height: archH,
          child: _buildArch(archW, archH),
        );

        if (useSide) {
          final onLeft = _isLeftHalf(_selectedFdi!);
          final panel = ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: panelMaxW),
            child: _buildPanel(),
          );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: onLeft
                      ? Padding(
                          padding: const EdgeInsets.only(right: 24),
                          child: panel,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              arch,
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: onLeft
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(left: 24),
                          child: panel,
                        ),
                ),
              ),
            ],
          );
        }

        // Narrow layout — arch centered, panel expands below.
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: arch),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _selectedFdi == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _buildPanel(),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
