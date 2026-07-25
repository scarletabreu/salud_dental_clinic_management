import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/proyeccion_odontograma.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';
import 'tooth_geometry.dart';

// ─────────────────────────────────────────────
//  Functional tooth status colors — el *rol* es dato clínico; el tono se
//  ajusta al tema para que un diente tratado no desaparezca sobre fondo oscuro.
// ─────────────────────────────────────────────

const _kToothTeal = Color(0xFF0D9488);
const _kToothIndigo = Color(0xFF6366F1);
const _kToothAmber = Color(0xFFF59E0B);
const _kToothRed = Color(0xFFEF4444);
const _kToothEmpty = Color(0xFFCBD5E1);
// Gris azulado para la capa "histórico" (tratamientos de consultas previas):
// presente pero apagado, claramente distinto del teal de "esta consulta".
const _kToothSlate = Color(0xFF64748B);

// ─────────────────────────────────────────────
//  Tooth status
// ─────────────────────────────────────────────

enum ToothStatus { empty, treated, historico, mild, moderate, critical }

Color colorForStatus(ToothStatus s, {bool oscuro = false}) => oscuro
    ? switch (s) {
        ToothStatus.empty => const Color(0xFF52627A),
        ToothStatus.treated => const Color(0xFF2DD4BF),
        ToothStatus.historico => const Color(0xFF94A3B8),
        ToothStatus.mild => const Color(0xFF818CF8),
        ToothStatus.moderate => const Color(0xFFFBBF24),
        ToothStatus.critical => const Color(0xFFFC6B6B),
      }
    : switch (s) {
        ToothStatus.empty => _kToothEmpty,
        ToothStatus.treated => _kToothTeal,
        ToothStatus.historico => _kToothSlate,
        ToothStatus.mild => _kToothIndigo,
        ToothStatus.moderate => _kToothAmber,
        ToothStatus.critical => _kToothRed,
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
  if (dienteEstaAusente(d)) return ToothStatus.empty;
  if (d.diagnosis.isNotEmpty) {
    var worst = SeveridadDiagnosis.leve;
    for (final diag in d.diagnosis) {
      if (diag.severidad == SeveridadDiagnosis.grave) {
        return ToothStatus.critical;
      }
      if (diag.severidad == SeveridadDiagnosis.moderada) {
        worst = SeveridadDiagnosis.moderada;
      }
    }
    return worst == SeveridadDiagnosis.moderada
        ? ToothStatus.moderate
        : ToothStatus.mild;
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
  if (d == null || dienteEstaAusente(d)) return EstadoSuperficie.sinDatos;
  if (d.diagnosis.any((diagnostico) => diagnostico.superficie == cara)) {
    return EstadoSuperficie.diagnosticada;
  }
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
  if (d == null || dienteEstaAusente(d) || d.tratamientos.isEmpty) {
    return TratamientoIndicador.ninguno;
  }
  final hayEnProceso = d.tratamientos.any((t) => !t.estaTerminado);
  return hayEnProceso
      ? TratamientoIndicador.enProceso
      : TratamientoIndicador.finalizado;
}

/// Si la pieza se dibuja en la mitad izquierda de la boca vista de frente.
///
/// Decide de qué lado se coloca el panel: pegado a su pieza, nunca tapándola.
/// Vale igual para la arcada y para el odontodiagrama porque ambos ordenan los
/// cuadrantes de la misma manera.
bool piezaEnMitadIzquierda(int fdi) =>
    (fdi >= 11 && fdi <= 18) ||
    (fdi >= 41 && fdi <= 48) ||
    (fdi >= 51 && fdi <= 55) ||
    (fdi >= 81 && fdi <= 85);

// ─────────────────────────────────────────────
//  Panel de detalle de una pieza
// ─────────────────────────────────────────────

/// Ficha flotante de una pieza: su mapa de caras, lo que tiene anotado y los
/// botones para añadir un diagnóstico o un tratamiento.
///
/// Es el único editor por pieza de la aplicación. La arcada y el
/// odontodiagrama lo montan igual —al lado de la pieza tocada— para que el
/// doctor no tenga que aprender dos interacciones para la misma boca.
class PanelDetallePieza extends StatefulWidget {
  final int fdi;
  final Diente? diente;
  final bool editMode;

  /// Claves anotadas sobre esta pieza en consultas anteriores. El diagrama ya
  /// no las dibuja en tinta tenue —llenaba el papel de marcas en una boca muy
  /// tratada—, así que este panel es donde se consultan.
  final List<HallazgoDental> hallazgosHistoricos;

  final VoidCallback onClose;
  final void Function(Diente, TipoSuperficie?)? onAddDiagnosis;
  final void Function(Diente, TipoSuperficie?)? onAddTratamiento;
  final void Function(Diente, bool)? onToggleAusente;
  final void Function(Diente, int index)? onQuitarTratamiento;
  final void Function(Diente, int index, bool terminado)? onToggleTerminado;
  final String Function(String tratamientoId)? nombreTratamiento;

  const PanelDetallePieza({
    super.key,
    required this.fdi,
    required this.diente,
    required this.editMode,
    required this.onClose,
    this.hallazgosHistoricos = const [],
    this.onAddDiagnosis,
    this.onAddTratamiento,
    this.onToggleAusente,
    this.onQuitarTratamiento,
    this.onToggleTerminado,
    this.nombreTratamiento,
  });

  @override
  State<PanelDetallePieza> createState() => _PanelDetallePiezaState();
}

class _PanelDetallePiezaState extends State<PanelDetallePieza> {
  TipoSuperficie? _selectedSurface;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final paleta = PaletaArcada.de(context);
    final name = kFdiNames[widget.fdi] ?? 'Diente ${widget.fdi}';
    final d = widget.diente;
    final isAbsent = d != null && dienteEstaAusente(d);

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
                  color: paleta
                      .status(statusForDiente(d))
                      .withValues(alpha: 0.12),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
                  child: Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: ac.textMuted,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(height: 1, color: ac.divider),
          const SizedBox(height: 16),

          Center(
            child: _MapaSuperficies(
              key: const ValueKey('mapa_superficies'),
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

          _InfoPieza(
            diente: d,
            hallazgosHistoricos: widget.hallazgosHistoricos,
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

class _MapaSuperficies extends StatelessWidget {
  final int fdi;
  final Diente? diente;
  final bool editMode;
  final TipoSuperficie? selectedSurface;
  final ValueChanged<TipoSuperficie> onSurfaceSelected;

  const _MapaSuperficies({
    super.key,
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
      painter: _MapaSuperficiesPainter(
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

class _MapaSuperficiesPainter extends CustomPainter {
  final Diente? diente;
  final TipoSuperficie centerSurface;
  final TipoSuperficie bottomSurface;
  final TipoSuperficie? selected;
  final double a;
  final double b;
  final Color labelColor;
  final PaletaArcada paleta;

  const _MapaSuperficiesPainter({
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
  bool shouldRepaint(_MapaSuperficiesPainter old) =>
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

class _InfoPieza extends StatelessWidget {
  final Diente? diente;
  final List<HallazgoDental> hallazgosHistoricos;
  final bool editMode;
  final TipoSuperficie? selectedSurface;
  final void Function(Diente, TipoSuperficie?)? onAddDiagnosis;
  final void Function(Diente, TipoSuperficie?)? onAddTratamiento;
  final void Function(Diente, int index)? onQuitarTratamiento;
  final void Function(Diente, int index, bool terminado)? onToggleTerminado;
  final String Function(String tratamientoId)? nombreTratamiento;

  const _InfoPieza({
    required this.diente,
    required this.hallazgosHistoricos,
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
    final tratamientosHistoricos =
        d?.tratamientosHistoricos ?? const <TratamientoAplicado>[];
    final hayHistorico =
        tratamientosHistoricos.isNotEmpty || hallazgosHistoricos.isNotEmpty;
    final hayAnotacionDeHoy =
        d != null && (d.diagnosis.isNotEmpty || d.tratamientos.isNotEmpty);
    // Sin pieza normalizada no hay nada que editar, pero sus antecedentes —que
    // el diagrama ya no dibuja— siguen mereciendo mostrarse.
    if (!hayAnotacionDeHoy && !hayHistorico && !(editMode && d != null)) {
      return Text(
        'Sin datos registrados',
        style: TextStyle(fontSize: 12, color: ac.textDisabled),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (d != null && d.diagnosis.isNotEmpty) ...[
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
            children: d.diagnosis.asMap().entries.map((entrada) {
              final diag = entrada.value;
              final color = switch (diag.severidad) {
                SeveridadDiagnosis.grave => ac.red,
                SeveridadDiagnosis.moderada => ac.amber,
                SeveridadDiagnosis.leve => ac.indigo,
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          conSuperficie(
                            diag.nombreDiagnostico ?? label,
                            diag.superficie,
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      origenClinico(diag.consultaId, diag.fechaAplicacion),
                      style: TextStyle(fontSize: 9, color: ac.textMuted),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (d.tratamientos.isNotEmpty) const SizedBox(height: 12),
        ],
        if (d != null && d.tratamientos.isNotEmpty) ...[
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
              nombre:
                  e.value.nombreTratamiento ??
                  nombreTratamiento?.call(e.value.tratamientoId) ??
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
        if (hayHistorico) ...[
          if (hayAnotacionDeHoy) const SizedBox(height: 12),
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
          ...hallazgosHistoricos.map((h) => _HallazgoHistoricoRow(hallazgo: h)),
          ...tratamientosHistoricos.map(
            (t) => _TratamientoHistoricoRow(
              nombre:
                  t.nombreTratamiento ??
                  nombreTratamiento?.call(t.tratamientoId) ??
                  'Tratamiento',
              tratamiento: t,
            ),
          ),
        ],
        if (d != null &&
            d.observaciones != null &&
            d.observaciones!.isNotEmpty) ...[
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
        if (editMode && d != null) ...[
          const SizedBox(height: 14),
          Divider(height: 1, color: ac.divider),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onAddDiagnosis == null
                    ? null
                    : () => onAddDiagnosis!(d, selectedSurface),
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text('Diagnóstico'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ac.indigo,
                  side: BorderSide(color: ac.indigo.withValues(alpha: 0.40)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onAddTratamiento == null
                    ? null
                    : () => onAddTratamiento!(d, selectedSurface),
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text('Tratamiento'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ac.teal,
                  side: BorderSide(color: ac.teal.withValues(alpha: 0.40)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Applied treatment row (name · estado · quitar)
// ─────────────────────────────────────────────

/// «Resina compuesta · Oclusal», o solo el nombre si la marca es de la pieza
/// entera. La cara es dato clínico: sin ella, dos resinas en el mismo diente se
/// leen como una repetición.
String conSuperficie(String nombre, TipoSuperficie? superficie) =>
    superficie == null ? nombre : '$nombre · ${superficie.name}';

String origenClinico(String? consultaId, DateTime? fecha) {
  final consulta = consultaId == null
      ? 'Esta consulta'
      : 'Consulta ${consultaId.length > 8 ? consultaId.substring(0, 8) : consultaId}';
  if (fecha == null) return consulta;
  return '$consulta · ${fecha.day}/${fecha.month}/${fecha.year}';
}

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
    final indicado = tratamiento.estado == EstadoTratamientoAplicado.indicado;
    final estadoColor = terminado ? ac.green : ac.amber;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            terminado
                ? Icons.check_circle_outline_rounded
                : indicado
                ? Icons.assignment_late_outlined
                : Icons.pending_outlined,
            size: 14,
            color: estadoColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              conSuperficie(nombre, tratamiento.superficie),
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
                  terminado
                      ? 'Terminado'
                      : indicado
                      ? 'Indicado'
                      : 'En proceso',
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
                terminado
                    ? 'Terminado'
                    : indicado
                    ? 'Indicado'
                    : 'En proceso',
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
//  Historic finding row (clave del odontodiagrama de consultas anteriores)
// ─────────────────────────────────────────────

/// «Restaurada · oclusal, mesial», o solo la clave cuando es de la pieza
/// entera. Es lo que antes se estampaba en tinta tenue sobre el papel.
class _HallazgoHistoricoRow extends StatelessWidget {
  final HallazgoDental hallazgo;

  const _HallazgoHistoricoRow({required this.hallazgo});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final caras = hallazgo.superficies.map((s) => s.name).join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.history_rounded, size: 14, color: ac.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              caras.isEmpty
                  ? hallazgo.estado.label
                  : '${hallazgo.estado.label} · $caras',
              style: TextStyle(fontSize: 12, color: ac.textMuted),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conSuperficie(nombre, tratamiento.superficie),
                  style: TextStyle(fontSize: 12, color: ac.textMuted),
                ),
                Text(
                  origenClinico(
                    tratamiento.consultaId,
                    tratamiento.fechaAplicacion,
                  ),
                  style: TextStyle(fontSize: 10, color: ac.textDisabled),
                ),
              ],
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
