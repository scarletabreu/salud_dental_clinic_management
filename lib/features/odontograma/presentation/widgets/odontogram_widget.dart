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
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgPage,
        borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 14),

          // Body: responsive layout
          LayoutBuilder(
            builder: (ctx, constraints) {
              final isWide = constraints.maxWidth > 460;
              final diagram = _SurfaceDiagram(
                fdi: widget.fdi,
                diente: d,
                editMode: widget.editMode,
                selectedSurface: _selectedSurface,
                onSurfaceSelected: (s) => setState(() {
                  _selectedSurface = (_selectedSurface == s) ? null : s;
                }),
              );
              final info = _ToothInfoPanel(
                diente: d,
                editMode: widget.editMode,
                selectedSurface: _selectedSurface,
                onAddDiagnosis: widget.onAddDiagnosis,
                onAddTratamiento: widget.onAddTratamiento,
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    diagram,
                    const SizedBox(width: 16),
                    Expanded(child: info),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [diagram, const SizedBox(height: 14), info],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Surface diagram (5-section cross)
// ─────────────────────────────────────────────

class _SurfaceDiagram extends StatelessWidget {
  final int fdi;
  final Diente? diente;
  final bool editMode;
  final TipoSuperficie? selectedSurface;
  final ValueChanged<TipoSuperficie> onSurfaceSelected;

  const _SurfaceDiagram({
    required this.fdi,
    required this.diente,
    required this.editMode,
    required this.selectedSurface,
    required this.onSurfaceSelected,
  });

  // Build a map from surface type to Superficie for quick lookup
  Map<TipoSuperficie, Superficie> _surfaceMap() {
    if (diente == null) return {};
    return {for (final s in diente!.superficies) s.tipoSuperficie: s};
  }

  Color _colorForSurface(Superficie? s) {
    if (s == null) return const Color(0xFFE2E8F0);
    if (s.diagnosisId != null) return kAmber;
    if (s.tratamientos.isNotEmpty) return kTeal;
    return const Color(0xFFE2E8F0);
  }

  @override
  Widget build(BuildContext context) {
    final surfMap = _surfaceMap();
    final isUpper = isUpperTooth(fdi);
    final isAnterior = isAnteriorTooth(fdi);

    final centerSurface = isAnterior ? TipoSuperficie.incisal : TipoSuperficie.oclusal;
    final bottomSurface = isUpper ? TipoSuperficie.palatina : TipoSuperficie.lingual;

    const diagSize = 120.0;
    const centerSize = 46.0;
    const sideSize = 34.0;
    const offset = (diagSize - centerSize) / 2; // 37

    return SizedBox(
      width: diagSize,
      height: diagSize,
      child: Stack(
        children: [
          // Center: oclusal / incisal
          Positioned(
            left: offset,
            top: offset,
            child: _SurfaceTile(
              size: centerSize,
              radius: 5,
              label: isAnterior ? 'I' : 'O',
              surface: surfMap[centerSurface],
              type: centerSurface,
              selected: selectedSurface == centerSurface,
              editMode: editMode,
              onTap: editMode ? () => onSurfaceSelected(centerSurface) : null,
              color: _colorForSurface(surfMap[centerSurface]),
            ),
          ),
          // Top: vestibular
          Positioned(
            left: offset,
            top: 0,
            child: _SurfaceTile(
              size: sideSize,
              height: offset - 2,
              radius: 5,
              label: 'V',
              surface: surfMap[TipoSuperficie.vestibular],
              type: TipoSuperficie.vestibular,
              selected: selectedSurface == TipoSuperficie.vestibular,
              editMode: editMode,
              onTap: editMode ? () => onSurfaceSelected(TipoSuperficie.vestibular) : null,
              color: _colorForSurface(surfMap[TipoSuperficie.vestibular]),
            ),
          ),
          // Bottom: lingual / palatina
          Positioned(
            left: offset,
            top: offset + centerSize + 2,
            child: _SurfaceTile(
              size: sideSize,
              height: offset - 2,
              radius: 5,
              label: isUpper ? 'P' : 'L',
              surface: surfMap[bottomSurface],
              type: bottomSurface,
              selected: selectedSurface == bottomSurface,
              editMode: editMode,
              onTap: editMode ? () => onSurfaceSelected(bottomSurface) : null,
              color: _colorForSurface(surfMap[bottomSurface]),
            ),
          ),
          // Left: mesial
          Positioned(
            left: 0,
            top: offset,
            child: _SurfaceTile(
              size: offset - 2,
              height: centerSize,
              radius: 5,
              label: 'M',
              surface: surfMap[TipoSuperficie.mesial],
              type: TipoSuperficie.mesial,
              selected: selectedSurface == TipoSuperficie.mesial,
              editMode: editMode,
              onTap: editMode ? () => onSurfaceSelected(TipoSuperficie.mesial) : null,
              color: _colorForSurface(surfMap[TipoSuperficie.mesial]),
            ),
          ),
          // Right: distal
          Positioned(
            left: offset + centerSize + 2,
            top: offset,
            child: _SurfaceTile(
              size: offset - 2,
              height: centerSize,
              radius: 5,
              label: 'D',
              surface: surfMap[TipoSuperficie.distal],
              type: TipoSuperficie.distal,
              selected: selectedSurface == TipoSuperficie.distal,
              editMode: editMode,
              onTap: editMode ? () => onSurfaceSelected(TipoSuperficie.distal) : null,
              color: _colorForSurface(surfMap[TipoSuperficie.distal]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceTile extends StatelessWidget {
  final double size;
  final double? height;
  final double radius;
  final String label;
  final Superficie? surface;
  final TipoSuperficie type;
  final bool selected;
  final bool editMode;
  final VoidCallback? onTap;
  final Color color;

  const _SurfaceTile({
    required this.size,
    this.height,
    required this.radius,
    required this.label,
    required this.surface,
    required this.type,
    required this.selected,
    required this.editMode,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final w = size;
    final h = height ?? size;
    final hasData = surface != null &&
        (surface!.diagnosisId != null || surface!.tratamientos.isNotEmpty);
    final borderColor = selected
        ? kTeal
        : hasData
            ? color.withValues(alpha: 0.60)
            : const Color(0xFFCBD5E1);
    final fillColor = selected
        ? kTeal.withValues(alpha: 0.18)
        : hasData
            ? color.withValues(alpha: 0.20)
            : Colors.white;

    Widget tile = Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: selected ? 1.8 : 1.2),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected
                ? kTeal
                : hasData
                    ? color
                    : kTextDisabled,
          ),
        ),
      ),
    );

    if (onTap != null) {
      tile = GestureDetector(onTap: onTap, child: tile);
      if (editMode) {
        tile = MouseRegion(cursor: SystemMouseCursors.click, child: tile);
      }
    }
    return tile;
  }
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Arch canvas — centered, mouth-proportioned, capped width
        LayoutBuilder(
          builder: (ctx, constraints) {
            final w = math.min(constraints.maxWidth, 460.0);
            final h = w * 0.95;
            _canvasSize = Size(w, h);
            return Center(
              child: SizedBox(
                width: w,
                height: h,
                child: MouseRegion(
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
                    final fdi = _fdiAtPosition(details.localPosition, hitScale: 1.4);
                    setState(() {
                      _selectedFdi = fdi == _selectedFdi ? null : fdi;
                    });
                    if (fdi != null) {
                      final d = _getDiente(fdi);
                      if (d != null) widget.onToothSelected?.call(d);
                    }
                  },
                  child: CustomPaint(
                    size: _canvasSize,
                    painter: _OdontogramPainter(
                      dientes: _dienteMap,
                      selectedFdi: _selectedFdi,
                      hoveredFdi: _hoveredFdi,
                    ),
                  ),
                ),
                ),
              ),
            );
          },
        ),

        // Detail panel — animated show/hide
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _selectedFdi == null
                ? const SizedBox.shrink()
                : _ToothDetailPanel(
                    key: ValueKey(_selectedFdi),
                    fdi: _selectedFdi!,
                    diente: _getDiente(_selectedFdi!),
                    editMode: widget.editMode,
                    onClose: () => setState(() => _selectedFdi = null),
                    onAddDiagnosis: widget.onAddDiagnosis,
                    onAddTratamiento: widget.onAddTratamiento,
                    onToggleAusente: widget.onToggleAusente,
                  ),
          ),
        ),
      ],
    );
  }
}
