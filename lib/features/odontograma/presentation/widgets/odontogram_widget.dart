import 'dart:math' as math;
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/historial_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/marca_clinica_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/proyeccion_odontograma.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'paleta_odontodiagrama.dart';
import 'panel_detalle_pieza.dart';
import 'tooth_geometry.dart';
import 'trazo_punteado.dart';

// La paleta, el estado clínico de una pieza y el panel de detalle viven en
// `panel_detalle_pieza.dart` porque el odontodiagrama los usa igual. Se
// reexportan para que quien ya importaba la arcada no tenga que cambiar nada.
export 'panel_detalle_pieza.dart';

/// Verde del punto indicador de «todos los tratamientos terminados». Solo lo
/// usa la arcada: el panel no dibuja ese indicador.
const _kToothGreen = Color(0xFF10B981);

// ─────────────────────────────────────────────
//  CustomPainter — arch
// ─────────────────────────────────────────────

class _OdontogramPainter extends CustomPainter {
  final Map<int, Diente> dientes;

  /// Lo que describe el estado de cada pieza. El color del diente sale de la
  /// clave clínica de esta marca —una caries se dibuja roja porque es una
  /// caries— y su firmeza, de la procedencia. Antes el tono lo decidía una
  /// escala de severidad propia de la arcada, de modo que la misma boca se
  /// coloreaba con un criterio en la arcada y con otro en el formulario.
  final Map<int, MarcaClinicaPieza?> marcaPorFdi;

  final int? selectedFdi;
  final int? hoveredFdi;
  final Color labelColor;
  final PaletaArcada paleta;
  final PaletaOdontodiagrama paletaClinica;
  final DenticionArcada denticion;

  const _OdontogramPainter({
    required this.dientes,
    required this.marcaPorFdi,
    required this.labelColor,
    required this.paleta,
    required this.paletaClinica,
    required this.denticion,
    this.selectedFdi,
    this.hoveredFdi,
  });

  EstiloMarcaClinica? _estilo(int fdi) {
    final marca = marcaPorFdi[fdi];
    if (marca == null) return null;
    return paletaClinica.estiloDe(marca.tintaClinica, marca.procedencia);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final layout = archLayout(size, denticion: denticion);
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
      final isAbsent = d != null && dienteEstaAusente(d);
      final estilo = isAbsent ? null : _estilo(fdi);
      final isSelected = fdi == selectedFdi;
      final isHovered = fdi == hoveredFdi && !isSelected;
      final hasStatus = estilo != null;
      final statusColor = isAbsent
          ? paleta.vacio
          : (estilo?.color ?? paleta.vacio);

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
            ..color = (hasStatus ? statusColor : paleta.vacio).withAlpha(
              hasStatus ? 140 : 255,
            )
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
      final trazo = Paint()
        ..color = outlineColor.withAlpha(strokeAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round;
      // Lo planificado se perfila discontinuo: todavía no está en la boca, y el
      // trazo lo dice aunque la pieza se imprima sin color.
      if (estilo != null && estilo.punteado && !isSelected && !isHovered) {
        dibujarContornoPunteado(canvas, path, trazo);
      } else {
        canvas.drawPath(path, trazo);
      }

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
      final isAbsent = d?.estaAusente ?? false;
      final isSelected = fdi == selectedFdi;
      final estilo = isAbsent ? null : _estilo(fdi);
      final hasStatus = estilo != null;
      final statusColor = isAbsent
          ? paleta.vacio
          : (estilo?.color ?? paleta.vacio);

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

      tp.paint(canvas, p.labelPos.translate(-tp.width / 2, -tp.height / 2));

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
      !mapEquals(old.marcaPorFdi, marcaPorFdi) ||
      old.selectedFdi != selectedFdi ||
      old.hoveredFdi != hoveredFdi ||
      old.labelColor != labelColor ||
      old.paleta != paleta ||
      old.paletaClinica != paletaClinica ||
      old.denticion != denticion;
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
  final void Function(Diente, int index, bool terminado)?
  onToggleTratamientoTerminado;
  final String Function(String tratamientoId)? nombreTratamiento;
  final String Function(String doctorId)? nombreDoctor;

  /// Actividades del plan que caen sobre cada pieza, indexadas por código FDI.
  final Map<int, List<ItemPlanTratamiento>> itemsPlan;

  /// La historia de cada pieza del paciente (SD-144). Al abrir una, su ficha
  /// muestra la línea de tiempo completa en vez de solo lo de este odontograma.
  final HistorialPiezas? historialPiezas;

  /// Anota una observación clínica sobre la pieza abierta.
  final void Function(Diente, String)? onNotasPiezaChanged;

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
    this.nombreDoctor,
    this.itemsPlan = const {},
    this.historialPiezas,
    this.onNotasPiezaChanged,
  });

  @override
  State<OdontogramWidget> createState() => _OdontogramWidgetState();
}

class _OdontogramWidgetState extends State<OdontogramWidget> {
  int? _selectedFdi;
  int? _hoveredFdi;
  Size _canvasSize = Size.zero;
  DenticionArcada _denticion = DenticionArcada.permanente;

  Map<int, Diente> get _dienteMap {
    final odo = widget.odontograma;
    if (odo == null) return {};
    return {for (final d in odo.dientes) d.fdiCode: d};
  }

  Diente? _getDiente(int fdi) => _dienteMap[fdi];

  /// Lo que describe el estado de cada pieza, resuelto una vez por construcción
  /// y no dentro del pintor: son 52 piezas y el pintor se repite en cada hover.
  Map<int, MarcaClinicaPieza?> get _marcaPorFdi => {
    for (final entry in _dienteMap.entries)
      entry.key: marcaDominante(
        marcasDelDiente(
          entry.value,
          itemsPlan: widget.itemsPlan[entry.key] ?? const [],
          nombreTratamiento: widget.nombreTratamiento,
        ),
      ),
  };

  int? _fdiAtPosition(Offset pos, {double hitScale = 1.4}) {
    if (_canvasSize == Size.zero) return null;
    final layout = archLayout(_canvasSize, denticion: _denticion);
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
        // La arcada se repinta entera con cada hover y cada selección. La
        // frontera evita que ese repintado —constante mientras se recorre la
        // boca con el ratón— arrastre al panel de detalle, la leyenda y el
        // resto de la pantalla de consulta, que no cambian.
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size(w, h),
            painter: _OdontogramPainter(
              dientes: _dienteMap,
              marcaPorFdi: _marcaPorFdi,
              selectedFdi: _selectedFdi,
              hoveredFdi: _hoveredFdi,
              labelColor: labelColor,
              paleta: PaletaArcada.de(context),
              paletaClinica: PaletaOdontodiagrama.de(context),
              denticion: _denticion,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel() => PanelDetallePieza(
    key: ValueKey(_selectedFdi),
    fdi: _selectedFdi!,
    diente: _getDiente(_selectedFdi!),
    itemsPlan: widget.itemsPlan[_selectedFdi!] ?? const [],
    historial: widget.historialPiezas?[_selectedFdi!],
    editMode: widget.editMode,
    onClose: () => setState(() => _selectedFdi = null),
    onNotasChanged: widget.onNotasPiezaChanged,
    onAddDiagnosis: widget.onAddDiagnosis,
    onAddTratamiento: widget.onAddTratamiento,
    onToggleAusente: widget.onToggleAusente,
    onQuitarTratamiento: widget.onQuitarTratamiento,
    onToggleTerminado: widget.onToggleTratamientoTerminado,
    nombreTratamiento: widget.nombreTratamiento,
    nombreDoctor: widget.nombreDoctor ?? widget.historialPiezas?.nombreDoctor,
  );

  Widget _selectorDenticion() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: SegmentedButton<DenticionArcada>(
      segments: [
        for (final denticion in DenticionArcada.values)
          ButtonSegment(value: denticion, label: Text(denticion.label)),
      ],
      selected: {_denticion},
      showSelectedIcon: false,
      onSelectionChanged: (seleccion) => setState(() {
        _denticion = seleccion.first;
        _selectedFdi = null;
        _hoveredFdi = null;
      }),
    ),
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
          final onLeft = piezaEnMitadIzquierda(_selectedFdi!);
          final panel = ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: panelMaxW),
            child: _buildPanel(),
          );
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _selectorDenticion(),
              Row(
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
              ),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _selectorDenticion(),
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
