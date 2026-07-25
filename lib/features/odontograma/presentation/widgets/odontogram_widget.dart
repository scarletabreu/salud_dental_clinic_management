import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';
import 'tooth_geometry.dart';

// ─────────────────────────────────────────────
//  Functional tooth status colors — el *rol* es dato clínico; el tono se
//  ajusta al tema para que un diente tratado no desaparezca sobre fondo oscuro.
// ─────────────────────────────────────────────

const _kToothTeal   = Color(0xFF0D9488);
const _kToothIndigo = Color(0xFF6366F1);
const _kToothAmber  = Color(0xFFF59E0B);
const _kToothRed    = Color(0xFFEF4444);
const _kToothGreen  = Color(0xFF10B981);
const _kToothEmpty  = Color(0xFFCBD5E1);
// Gris azulado para la capa "histórico" (tratamientos de consultas previas):
// presente pero apagado, claramente distinto del teal de "esta consulta".
const _kToothSlate  = Color(0xFF64748B);

// ─────────────────────────────────────────────
//  Tooth status
// ─────────────────────────────────────────────

enum ToothStatus { empty, treated, historico, mild, moderate, critical }

Color colorForStatus(ToothStatus s, {bool oscuro = false}) => oscuro
    ? switch (s) {
        ToothStatus.empty     => const Color(0xFF52627A),
        ToothStatus.treated   => const Color(0xFF2DD4BF),
        ToothStatus.historico => const Color(0xFF94A3B8),
        ToothStatus.mild      => const Color(0xFF818CF8),
        ToothStatus.moderate  => const Color(0xFFFBBF24),
        ToothStatus.critical  => const Color(0xFFFC6B6B),
      }
    : switch (s) {
        ToothStatus.empty     => _kToothEmpty,
        ToothStatus.treated   => _kToothTeal,
        ToothStatus.historico => _kToothSlate,
        ToothStatus.mild      => _kToothIndigo,
        ToothStatus.moderate  => _kToothAmber,
        ToothStatus.critical  => _kToothRed,
      };

/// Superficie sobre la que se dibuja la arcada. Los dientes se pintaban en
/// blanco fijo con filetes gris claro: sobre el papel oscuro del tema eso deja
/// una arcada deslumbrante y una línea media invisible.
@immutable
class PaletaArcada {
  /// Relleno de un diente sin hallazgos.
  final Color esmalte;

  /// Línea media y filetes de la cuadrícula de superficies.
  final Color regla;

  /// Contorno de un diente sin estado y relleno de uno ausente.
  final Color vacio;

  /// Halo bajo los puntos indicadores, para separarlos del contorno.
  final Color halo;

  final bool oscuro;

  const PaletaArcada({
    required this.esmalte,
    required this.regla,
    required this.vacio,
    required this.halo,
    required this.oscuro,
  });

  factory PaletaArcada.de(BuildContext context) {
    final ac = context.appColors;
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return PaletaArcada(
      esmalte: oscuro ? const Color(0xFF1C2537) : Colors.white,
      regla: oscuro ? const Color(0xFF2A3752) : const Color(0xFFEEF2F7),
      // El contorno se dibuja al 59 % de alfa cuando la pieza no tiene estado;
      // por debajo de este tono la arcada desaparece sobre la tarjeta oscura.
      vacio: oscuro ? const Color(0xFF6C7E97) : _kToothEmpty,
      halo: oscuro ? ac.cardBg : Colors.white,
      oscuro: oscuro,
    );
  }

  Color status(ToothStatus s) => colorForStatus(s, oscuro: oscuro);

  @override
  bool operator ==(Object other) =>
      other is PaletaArcada &&
      other.esmalte == esmalte &&
      other.regla == regla &&
      other.vacio == vacio &&
      other.halo == halo &&
      other.oscuro == oscuro;

  @override
  int get hashCode => Object.hash(esmalte, regla, vacio, halo, oscuro);
}

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
  // Tratamientos cargados como entidades o solo vinculados por id en la BD.
  if (d.tratamientos.isNotEmpty || d.tratamientosAplicadosIds.isNotEmpty) {
    return ToothStatus.treated;
  }
  // Sin trabajo en esta consulta pero con antecedentes: capa histórica.
  if (d.tratamientosHistoricos.isNotEmpty) return ToothStatus.historico;
  if (d.superficies.any((s) => s.diagnosisId != null)) return ToothStatus.mild;
  return ToothStatus.empty;
}

/// Estado clínico de una cara concreta, tal como se colorea en el mapa de
/// superficies.
enum EstadoSuperficie { sinDatos, historico, tratada, diagnosticada }

/// En qué estado está la cara [cara] del diente [d].
///
/// La fuente es `TratamientoAplicado.superficie`, que es donde la consulta
/// guarda realmente la cara elegida. Antes se leía `Superficie.tratamientos` /
/// `Superficie.diagnosisId`, dos campos que ningún camino de la app escribe:
/// el doctor asignaba un tratamiento a una cara y el mapa seguía en blanco.
EstadoSuperficie estadoDeSuperficie(Diente? d, TipoSuperficie cara) {
  if (d == null || d.estaAusente) return EstadoSuperficie.sinDatos;
  if (d.superficies.any(
    (s) => s.tipoSuperficie == cara && s.diagnosisId != null,
  )) {
    return EstadoSuperficie.diagnosticada;
  }
  if (d.tratamientos.any((t) => t.superficie == cara)) {
    return EstadoSuperficie.tratada;
  }
  if (d.tratamientosHistoricos.any((t) => t.superficie == cara)) {
    return EstadoSuperficie.historico;
  }
  return EstadoSuperficie.sinDatos;
}

/// Indicador de los tratamientos aplicados en vivo sobre un diente:
/// ámbar si hay alguno en proceso, verde si todos están terminados.
enum TratamientoIndicador { ninguno, enProceso, finalizado }

TratamientoIndicador indicadorTratamiento(Diente? d) {
  if (d == null || d.estaAusente || d.tratamientos.isEmpty) {
    return TratamientoIndicador.ninguno;
  }
  final hayEnProceso = d.tratamientos.any((t) => !t.estaTerminado);
  return hayEnProceso
      ? TratamientoIndicador.enProceso
      : TratamientoIndicador.finalizado;
}

// ─────────────────────────────────────────────
//  CustomPainter — arch
// ─────────────────────────────────────────────

class _OdontogramPainter extends CustomPainter {
  final Map<int, Diente> dientes;
  final int? selectedFdi;
  final int? hoveredFdi;
  final Color labelColor;
  final PaletaArcada paleta;

  const _OdontogramPainter({
    required this.dientes,
    required this.labelColor,
    required this.paleta,
    this.selectedFdi,
    this.hoveredFdi,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final layout = archLayout(size);
    final labelFontSize = size.width * 0.052 * 0.42;

    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.10),
      Offset(size.width / 2, size.height * 0.90),
      Paint()
        ..color = paleta.regla
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
      final statusColor = isAbsent ? paleta.vacio : paleta.status(status);

      final path = buildToothPath(type, p.size);
      final groove = buildGroovePath(type, p.size, upper: upper);

      canvas.save();
      canvas.translate(p.center.dx, p.center.dy);
      canvas.rotate(p.angle);

      final fillColor = isAbsent
          ? paleta.regla
          : isSelected
              ? statusColor.withAlpha(48)
              : isHovered
                  ? statusColor.withAlpha(hasStatus ? 42 : 22)
                  : hasStatus
                      ? statusColor.withAlpha(30)
                      : paleta.esmalte;
      canvas.drawPath(path, Paint()..color = fillColor);

      if (groove != null && !isAbsent) {
        canvas.drawPath(
          groove,
          Paint()
            ..color = (hasStatus ? statusColor : paleta.vacio)
                .withAlpha(hasStatus ? 140 : 255)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }

      final outlineColor = isAbsent
          ? paleta.vacio
          : (isSelected || isHovered || hasStatus)
              ? statusColor
              : labelColor;
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

      if (isAbsent) {
        final xPaint = Paint()
          ..color = paleta.vacio
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round;
        final mx = p.size.width * 0.30;
        final my = p.size.height * 0.30;
        canvas.drawLine(Offset(-mx, -my), Offset(mx, my), xPaint);
        canvas.drawLine(Offset(mx, -my), Offset(-mx, my), xPaint);
      }

      canvas.restore();
    });

    layout.forEach((fdi, p) {
      final d = dientes[fdi];
      final status = statusForDiente(d);
      final isAbsent = d?.estaAusente ?? false;
      final isSelected = fdi == selectedFdi;
      final hasStatus = status != ToothStatus.empty && !isAbsent;
      final statusColor = isAbsent ? paleta.vacio : paleta.status(status);

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
                    : labelColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        p.labelPos.translate(-tp.width / 2, -tp.height / 2),
      );

      final indic = indicadorTratamiento(d);
      if (indic != TratamientoIndicador.ninguno) {
        final dotColor = indic == TratamientoIndicador.enProceso
            ? paleta.status(ToothStatus.moderate)
            : (paleta.oscuro ? const Color(0xFF34D399) : _kToothGreen);
        final dotCenter = p.center.translate(
          p.size.width * 0.34,
          -p.size.height * 0.34,
        );
        final r = (p.size.width * 0.12).clamp(2.2, 5.0);
        // Halo del color del papel para que el punto resalte sobre el contorno.
        canvas.drawCircle(dotCenter, r + 1.2, Paint()..color = paleta.halo);
        canvas.drawCircle(dotCenter, r, Paint()..color = dotColor);
      }

      // Marcador de la capa histórica: anillo hueco slate en la esquina opuesta
      // al punto de "esta consulta". Hueco = ya hecho antes; relleno = en curso.
      final tieneHistorico =
          !(d?.estaAusente ?? false) &&
          (d?.tratamientosHistoricos.isNotEmpty ?? false);
      if (tieneHistorico) {
        final markCenter = p.center.translate(
          -p.size.width * 0.34,
          p.size.height * 0.34,
        );
        final r = (p.size.width * 0.12).clamp(2.2, 5.0);
        canvas.drawCircle(markCenter, r + 1.2, Paint()..color = paleta.halo);
        canvas.drawCircle(
          markCenter,
          r,
          Paint()
            ..color = paleta.status(ToothStatus.historico)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
    });
  }

  @override
  bool shouldRepaint(_OdontogramPainter old) =>
      old.dientes != dientes ||
      old.selectedFdi != selectedFdi ||
      old.hoveredFdi != hoveredFdi ||
      old.labelColor != labelColor ||
      old.paleta != paleta;
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
  final void Function(Diente, int index)? onQuitarTratamiento;
  final void Function(Diente, int index, bool terminado)? onToggleTerminado;
  final String Function(String tratamientoId)? nombreTratamiento;

  const _ToothDetailPanel({
    super.key,
    required this.fdi,
    required this.diente,
    required this.editMode,
    required this.onClose,
    this.onAddDiagnosis,
    this.onAddTratamiento,
    this.onToggleAusente,
    this.onQuitarTratamiento,
    this.onToggleTerminado,
    this.nombreTratamiento,
  });

  @override
  State<_ToothDetailPanel> createState() => _ToothDetailPanelState();
}

class _ToothDetailPanelState extends State<_ToothDetailPanel> {
  TipoSuperficie? _selectedSurface;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final paleta = PaletaArcada.de(context);
    final name = kFdiNames[widget.fdi] ?? 'Diente ${widget.fdi}';
    final d = widget.diente;
    final isAbsent = d?.estaAusente ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ac.bgPage,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: paleta.status(statusForDiente(d)).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text(
                    '${widget.fdi}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: paleta.status(statusForDiente(d)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ac.textPrimary,
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
                          ? ac.teal.withValues(alpha: 0.12)
                          : ac.red.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      isAbsent ? 'Restaurar' : 'Ausente',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isAbsent ? ac.teal : ac.red,
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
                    color: ac.chipBg,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(Icons.close_rounded, size: 15, color: ac.textMuted),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(height: 1, color: ac.divider),
          const SizedBox(height: 16),

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

          _ToothInfoPanel(
            diente: d,
            editMode: widget.editMode,
            selectedSurface: _selectedSurface,
            onAddDiagnosis: widget.onAddDiagnosis,
            onAddTratamiento: widget.onAddTratamiento,
            onQuitarTratamiento: widget.onQuitarTratamiento,
            onToggleTerminado: widget.onToggleTerminado,
            nombreTratamiento: widget.nombreTratamiento,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Surface map
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
  static const double _a = 0.32;
  static const double _b = 0.68;

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
    final labelColor = context.appColors.textDisabled;

    Widget map = CustomPaint(
      size: const Size(_size, _size),
      painter: _SurfaceMapPainter(
        diente: diente,
        centerSurface: _centerSurface,
        bottomSurface: _bottomSurface,
        selected: selectedSurface,
        a: _a,
        b: _b,
        labelColor: labelColor,
        paleta: PaletaArcada.de(context),
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
  final Diente? diente;
  final TipoSuperficie centerSurface;
  final TipoSuperficie bottomSurface;
  final TipoSuperficie? selected;
  final double a;
  final double b;
  final Color labelColor;
  final PaletaArcada paleta;

  const _SurfaceMapPainter({
    required this.diente,
    required this.centerSurface,
    required this.bottomSurface,
    required this.selected,
    required this.a,
    required this.b,
    required this.labelColor,
    required this.paleta,
  });

  Color get _sinDatos => paleta.esmalte;
  Color get _tealActivo => paleta.status(ToothStatus.treated);

  Color _baseColor(TipoSuperficie t) => switch (estadoDeSuperficie(diente, t)) {
    EstadoSuperficie.diagnosticada => paleta.status(ToothStatus.moderate),
    EstadoSuperficie.tratada => _tealActivo,
    EstadoSuperficie.historico => paleta.status(ToothStatus.historico),
    EstadoSuperficie.sinDatos => _sinDatos,
  };

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
      final hasData = base != _sinDatos;

      canvas.drawPath(
        path,
        Paint()
          ..color = isSel
              ? _tealActivo.withAlpha(38)
              : hasData
                  ? base.withAlpha(46)
                  : _sinDatos,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = isSel
              ? _tealActivo
              : hasData
                  ? base.withAlpha(150)
                  : paleta.regla
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSel ? 2.0 : 1.2
          ..strokeJoin = StrokeJoin.round,
      );
    });

    labels.forEach((t, lbl) {
      final isSel = selected == t;
      final base = _baseColor(t);
      final hasData = base != _sinDatos;
      final tp = TextPainter(
        text: TextSpan(
          text: lbl.$1,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSel
                ? _tealActivo
                : hasData
                    ? base
                    : labelColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, lbl.$2.translate(-tp.width / 2, -tp.height / 2));
    });
  }

  @override
  bool shouldRepaint(_SurfaceMapPainter old) =>
      !identical(old.diente, diente) ||
      old.selected != selected ||
      old.centerSurface != centerSurface ||
      old.bottomSurface != bottomSurface ||
      old.labelColor != labelColor ||
      old.paleta != paleta;
}

// ─────────────────────────────────────────────
//  Tooth info panel
// ─────────────────────────────────────────────

class _ToothInfoPanel extends StatelessWidget {
  final Diente? diente;
  final bool editMode;
  final TipoSuperficie? selectedSurface;
  final void Function(Diente, TipoSuperficie?)? onAddDiagnosis;
  final void Function(Diente, TipoSuperficie?)? onAddTratamiento;
  final void Function(Diente, int index)? onQuitarTratamiento;
  final void Function(Diente, int index, bool terminado)? onToggleTerminado;
  final String Function(String tratamientoId)? nombreTratamiento;

  const _ToothInfoPanel({
    required this.diente,
    required this.editMode,
    required this.selectedSurface,
    required this.onAddDiagnosis,
    required this.onAddTratamiento,
    this.onQuitarTratamiento,
    this.onToggleTerminado,
    this.nombreTratamiento,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final d = diente;
    if (d == null ||
        (d.diagnosis.isEmpty &&
            d.tratamientos.isEmpty &&
            d.tratamientosHistoricos.isEmpty &&
            !editMode)) {
      return Text(
        'Sin datos registrados',
        style: TextStyle(fontSize: 12, color: ac.textDisabled),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (d.diagnosis.isNotEmpty) ...[
          Text(
            'DIAGNÓSTICOS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: ac.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 5,
            children: d.diagnosis.map((diag) {
              final color = switch (diag.severidad) {
                SeveridadDiagnosis.grave    => ac.red,
                SeveridadDiagnosis.moderada => ac.amber,
                SeveridadDiagnosis.leve     => ac.indigo,
              };
              final label = switch (diag.severidad) {
                SeveridadDiagnosis.grave    => 'Grave',
                SeveridadDiagnosis.moderada => 'Moderado',
                SeveridadDiagnosis.leve     => 'Leve',
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
          Text(
            'TRATAMIENTOS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: ac.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          ...d.tratamientos.asMap().entries.map(
            (e) => _TratamientoAplicadoRow(
              nombre: nombreTratamiento?.call(e.value.tratamientoId) ??
                  'Tratamiento',
              tratamiento: e.value,
              editMode: editMode,
              onToggleTerminado: onToggleTerminado == null
                  ? null
                  : () => onToggleTerminado!(d, e.key, !e.value.estaTerminado),
              onQuitar: onQuitarTratamiento == null
                  ? null
                  : () => onQuitarTratamiento!(d, e.key),
            ),
          ),
        ],
        if (d.tratamientosHistoricos.isNotEmpty) ...[
          if (d.diagnosis.isNotEmpty || d.tratamientos.isNotEmpty)
            const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.history_rounded, size: 13, color: ac.textMuted),
              const SizedBox(width: 5),
              Text(
                'HISTÓRICO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: ac.textMuted,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'consultas anteriores',
                style: TextStyle(fontSize: 10, color: ac.textDisabled),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...d.tratamientosHistoricos.map(
            (t) => _TratamientoHistoricoRow(
              nombre: nombreTratamiento?.call(t.tratamientoId) ?? 'Tratamiento',
              tratamiento: t,
            ),
          ),
        ],
        if (d.observaciones != null && d.observaciones!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            d.observaciones!,
            style: TextStyle(
              fontSize: 12,
              color: ac.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        if (editMode) ...[
          const SizedBox(height: 14),
          Divider(height: 1, color: ac.divider),
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
                  foregroundColor: ac.indigo,
                  side: BorderSide(color: ac.indigo.withValues(alpha: 0.40)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => onAddTratamiento?.call(d, selectedSurface),
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text('Tratamiento'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ac.teal,
                  side: BorderSide(color: ac.teal.withValues(alpha: 0.40)),
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
//  Applied treatment row (name · estado · quitar)
// ─────────────────────────────────────────────

/// «Resina compuesta · Oclusal», o solo el nombre si el tratamiento es de la
/// pieza entera.
String _conSuperficie(String nombre, TipoSuperficie? superficie) =>
    superficie == null ? nombre : '$nombre · ${superficie.name}';

class _TratamientoAplicadoRow extends StatelessWidget {
  final String nombre;
  final TratamientoAplicado tratamiento;
  final bool editMode;
  final VoidCallback? onToggleTerminado;
  final VoidCallback? onQuitar;

  const _TratamientoAplicadoRow({
    required this.nombre,
    required this.tratamiento,
    required this.editMode,
    this.onToggleTerminado,
    this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final terminado = tratamiento.estaTerminado;
    final estadoColor = terminado ? ac.green : ac.amber;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            terminado
                ? Icons.check_circle_outline_rounded
                : Icons.pending_outlined,
            size: 14,
            color: estadoColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              // La cara tratada es dato clínico: sin ella, dos resinas en el
              // mismo diente se leen como una repetición.
              _conSuperficie(nombre, tratamiento.superficie),
              style: TextStyle(fontSize: 12, color: ac.textSecondary),
            ),
          ),
          if (editMode) ...[
            GestureDetector(
              onTap: onToggleTerminado,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: estadoColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  terminado ? 'Terminado' : 'En proceso',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: estadoColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onQuitar,
              child: Icon(
                Icons.delete_outline_rounded,
                size: 16,
                color: ac.red,
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: estadoColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                terminado ? 'Terminado' : 'En proceso',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: estadoColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Historic treatment row (read-only · capa histórico)
// ─────────────────────────────────────────────

class _TratamientoHistoricoRow extends StatelessWidget {
  final String nombre;
  final TratamientoAplicado tratamiento;

  const _TratamientoHistoricoRow({
    required this.nombre,
    required this.tratamiento,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final terminado = tratamiento.estaTerminado;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.history_rounded, size: 14, color: ac.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _conSuperficie(nombre, tratamiento.superficie),
              style: TextStyle(fontSize: 12, color: ac.textMuted),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ac.textMuted.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              terminado ? 'Terminado' : 'En proceso',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: ac.textMuted,
              ),
            ),
          ),
        ],
      ),
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
  final void Function(Diente, int index)? onQuitarTratamiento;
  final void Function(Diente, int index, bool terminado)? onToggleTratamientoTerminado;
  final String Function(String tratamientoId)? nombreTratamiento;

  const OdontogramWidget({
    super.key,
    this.odontograma,
    this.editMode = false,
    this.onToothSelected,
    this.onAddDiagnosis,
    this.onAddTratamiento,
    this.onToggleAusente,
    this.onQuitarTratamiento,
    this.onToggleTratamientoTerminado,
    this.nombreTratamiento,
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

  bool _isLeftHalf(int fdi) =>
      (fdi >= 11 && fdi <= 18) || (fdi >= 41 && fdi <= 48);

  Widget _buildArch(BuildContext context, double w, double h) {
    final labelColor = context.appColors.textDisabled;
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
            labelColor: labelColor,
            paleta: PaletaArcada.de(context),
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
        onQuitarTratamiento: widget.onQuitarTratamiento,
        onToggleTerminado: widget.onToggleTratamientoTerminado,
        nombreTratamiento: widget.nombreTratamiento,
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final maxW = constraints.maxWidth;
        const sideMin = 300.0;
        const panelMaxW = 360.0;
        const archMax = 760.0;
        final useSide = _selectedFdi != null && maxW >= 520 + 2 * sideMin;

        final archW = useSide
            ? math.min(archMax, maxW - 2 * sideMin)
            : math.min(maxW, archMax);
        final archH = archW * 0.95;
        _canvasSize = Size(archW, archH);

        final arch = SizedBox(
          width: archW,
          height: archH,
          child: _buildArch(ctx, archW, archH),
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
