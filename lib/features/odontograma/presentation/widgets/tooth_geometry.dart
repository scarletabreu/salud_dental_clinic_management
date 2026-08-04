import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

// ─────────────────────────────────────────────
//  Tooth type
// ─────────────────────────────────────────────

enum ToothType { incisor, canine, premolar, molar, wisdom }

enum DenticionArcada { permanente, mixta, temporal }

extension DenticionArcadaX on DenticionArcada {
  String get label => switch (this) {
    DenticionArcada.permanente => 'Permanente',
    DenticionArcada.mixta => 'Mixta',
    DenticionArcada.temporal => 'Temporal',
  };
}

ToothType toothTypeFor(int fdi) {
  final temporal = fdi >= 51 && fdi <= 85;
  return switch (fdi % 10) {
    1 || 2 => ToothType.incisor,
    3 => ToothType.canine,
    4 || 5 => temporal ? ToothType.molar : ToothType.premolar,
    6 || 7 => ToothType.molar,
    8 => ToothType.wisdom,
    _ => ToothType.molar,
  };
}

// ─────────────────────────────────────────────
//  Spanish tooth names (FDI)
// ─────────────────────────────────────────────

const Map<int, String> kFdiNames = {
  11: 'Incisivo central superior derecho',
  12: 'Incisivo lateral superior derecho',
  13: 'Canino superior derecho',
  14: 'Primer premolar superior derecho',
  15: 'Segundo premolar superior derecho',
  16: 'Primer molar superior derecho',
  17: 'Segundo molar superior derecho',
  18: 'Tercer molar superior derecho',
  21: 'Incisivo central superior izquierdo',
  22: 'Incisivo lateral superior izquierdo',
  23: 'Canino superior izquierdo',
  24: 'Primer premolar superior izquierdo',
  25: 'Segundo premolar superior izquierdo',
  26: 'Primer molar superior izquierdo',
  27: 'Segundo molar superior izquierdo',
  28: 'Tercer molar superior izquierdo',
  31: 'Incisivo central inferior izquierdo',
  32: 'Incisivo lateral inferior izquierdo',
  33: 'Canino inferior izquierdo',
  34: 'Primer premolar inferior izquierdo',
  35: 'Segundo premolar inferior izquierdo',
  36: 'Primer molar inferior izquierdo',
  37: 'Segundo molar inferior izquierdo',
  38: 'Tercer molar inferior izquierdo',
  41: 'Incisivo central inferior derecho',
  42: 'Incisivo lateral inferior derecho',
  43: 'Canino inferior derecho',
  44: 'Primer premolar inferior derecho',
  45: 'Segundo premolar inferior derecho',
  46: 'Primer molar inferior derecho',
  47: 'Segundo molar inferior derecho',
  48: 'Tercer molar inferior derecho',
  51: 'Incisivo central superior derecho temporal',
  52: 'Incisivo lateral superior derecho temporal',
  53: 'Canino superior derecho temporal',
  54: 'Primer molar superior derecho temporal',
  55: 'Segundo molar superior derecho temporal',
  61: 'Incisivo central superior izquierdo temporal',
  62: 'Incisivo lateral superior izquierdo temporal',
  63: 'Canino superior izquierdo temporal',
  64: 'Primer molar superior izquierdo temporal',
  65: 'Segundo molar superior izquierdo temporal',
  71: 'Incisivo central inferior izquierdo temporal',
  72: 'Incisivo lateral inferior izquierdo temporal',
  73: 'Canino inferior izquierdo temporal',
  74: 'Primer molar inferior izquierdo temporal',
  75: 'Segundo molar inferior izquierdo temporal',
  81: 'Incisivo central inferior derecho temporal',
  82: 'Incisivo lateral inferior derecho temporal',
  83: 'Canino inferior derecho temporal',
  84: 'Primer molar inferior derecho temporal',
  85: 'Segundo molar inferior derecho temporal',
};

// ─────────────────────────────────────────────
//  Arch ordering (around the rim, per arcada)
// ─────────────────────────────────────────────

/// Upper arch, left rim → top → right rim (viewer's perspective).
const List<int> kUpperOrder = [
  18,
  17,
  16,
  15,
  14,
  13,
  12,
  11,
  21,
  22,
  23,
  24,
  25,
  26,
  27,
  28,
];

/// Lower arch, left rim → bottom → right rim.
const List<int> kLowerOrder = [
  48,
  47,
  46,
  45,
  44,
  43,
  42,
  41,
  31,
  32,
  33,
  34,
  35,
  36,
  37,
  38,
];

const List<int> kUpperTemporalOrder = [55, 54, 53, 52, 51, 61, 62, 63, 64, 65];
const List<int> kLowerTemporalOrder = [85, 84, 83, 82, 81, 71, 72, 73, 74, 75];

// ─────────────────────────────────────────────
//  Mesio-distal width weight per tooth type
//  (controls how much arch each tooth occupies)
// ─────────────────────────────────────────────

double _widthWeight(int fdi) {
  return switch (toothTypeFor(fdi)) {
    ToothType.incisor =>
      fdi % 10 == 1 ? 1.05 : 0.85, // central wider than lateral
    ToothType.canine => 1.0,
    ToothType.premolar => 1.0,
    ToothType.molar => 1.45,
    ToothType.wisdom => 1.3,
  };
}

// ─────────────────────────────────────────────
//  Tooth placement (computed per canvas size)
// ─────────────────────────────────────────────

class ToothPlacement {
  final Offset center; // tooth center in canvas px
  final double angle; // rotation (rad) — crown faces outward
  final Size size; // tooth size in px
  final Offset labelPos; // FDI label center, outside the arch

  const ToothPlacement({
    required this.center,
    required this.angle,
    required this.size,
    required this.labelPos,
  });
}

/// Builds the full anatomical arch layout (32 permanent teeth) that fits
/// the given [canvas]. Two half-ellipses (upper/lower) share one center,
/// forming a horseshoe/mouth. Teeth are spaced by mesio-distal width and
/// rotated so each crown points radially outward.
Map<int, ToothPlacement> archLayout(
  Size canvas, {
  DenticionArcada denticion = DenticionArcada.permanente,
}) {
  final cx = canvas.width / 2;
  final cy = canvas.height / 2;
  final rx = canvas.width / 2 - canvas.width * 0.115;
  final ry = canvas.height / 2 - canvas.height * 0.085;

  final esMixta = denticion == DenticionArcada.mixta;
  final baseW = canvas.width * (esMixta ? 0.043 : 0.061);
  final baseH = canvas.height * (esMixta ? 0.076 : 0.104);
  final labelMargin = canvas.width * 0.056;

  final result = <int, ToothPlacement>{};

  void layArc(List<int> order, bool upper) {
    // Angular span across the rim, leaving a small gap near the midline
    // (so upper & lower molars don't collide at the sides).
    const gap = 0.20; // rad (~11°) at each end
    final spanStart = gap; // θ at one molar end
    final spanEnd = math.pi - gap; // θ at the other molar end
    final span = spanEnd - spanStart;

    final weights = order.map((f) => _widthWeight(f)).toList();
    final totalW = weights.fold<double>(0, (a, b) => a + b);

    double acc = 0;
    for (var i = 0; i < order.length; i++) {
      final fdi = order[i];
      // center of this tooth's slice (fraction along the span)
      final frac = (acc + weights[i] / 2) / totalW;
      acc += weights[i];
      // order goes left→right; θ goes spanEnd→spanStart so index 0 sits
      // at the left rim.
      final theta = spanEnd - frac * span;

      final px = cx + rx * math.cos(theta);
      final py = upper ? cy - ry * math.sin(theta) : cy + ry * math.sin(theta);
      final center = Offset(px, py);

      // outward radial unit vector (from arch center to tooth)
      final dx = px - cx;
      final dy = py - cy;
      final len = math.sqrt(dx * dx + dy * dy);
      final ox = len == 0 ? 0.0 : dx / len;
      final oy = len == 0 ? 0.0 : dy / len;

      // rotation so the tooth's local "up" (buccal) maps to outward radial
      final angle = math.atan2(ox, -oy);

      final type = toothTypeFor(fdi);
      final size = toothSizeFor(type, baseW, baseH);
      final labelPos = Offset(px + ox * labelMargin, py + oy * labelMargin);

      result[fdi] = ToothPlacement(
        center: center,
        angle: angle,
        size: size,
        labelPos: labelPos,
      );
    }
  }

  final superiores = switch (denticion) {
    DenticionArcada.permanente => kUpperOrder,
    DenticionArcada.temporal => kUpperTemporalOrder,
    DenticionArcada.mixta => [...kUpperOrder, ...kUpperTemporalOrder],
  };
  final inferiores = switch (denticion) {
    DenticionArcada.permanente => kLowerOrder,
    DenticionArcada.temporal => kLowerTemporalOrder,
    DenticionArcada.mixta => [...kLowerOrder, ...kLowerTemporalOrder],
  };
  layArc(superiores, true);
  layArc(inferiores, false);
  return result;
}

// ─────────────────────────────────────────────
//  Tooth size multipliers per type
// ─────────────────────────────────────────────

Size toothSizeFor(ToothType type, double baseW, double baseH) {
  return switch (type) {
    ToothType.incisor => Size(baseW * 1.10, baseH * 0.80),
    ToothType.canine => Size(baseW * 1.04, baseH * 0.94),
    ToothType.premolar => Size(baseW * 1.04, baseH * 0.96),
    ToothType.molar => Size(baseW * 1.24, baseH * 0.92),
    ToothType.wisdom => Size(baseW * 1.10, baseH * 0.86),
  };
}

// ─────────────────────────────────────────────
//  SVG tooth shapes (occlusal view, viewBox 0–100)
//  Authored upright: buccal/outer edge toward top (-y),
//  lingual/inner edge toward bottom (+y).
// ─────────────────────────────────────────────

const String _incisorSvg =
    'M22,28 Q50,14 78,28 Q86,42 76,68 Q66,86 50,86 Q34,86 24,68 Q14,42 22,28 Z';
const String _canineSvg =
    'M50,12 Q64,18 70,40 Q74,60 60,82 L50,92 L40,82 Q26,60 30,40 Q36,18 50,12 Z';
const String _posteriorSvg =
    'M28,16 L72,16 Q84,16 84,28 L84,72 Q84,84 72,84 L28,84 Q16,84 16,72 L16,28 Q16,16 28,16 Z';

String _shapeSvgFor(ToothType type) {
  return switch (type) {
    ToothType.incisor => _incisorSvg,
    ToothType.canine => _canineSvg,
    ToothType.premolar || ToothType.molar || ToothType.wisdom => _posteriorSvg,
  };
}

// Groove patterns (occlusal surface detail)
const String _premolarGroove = 'M22,50 L78,50';
const String _molarUpperGroove = 'M50,46 L50,20 M50,46 L74,74 M50,46 L26,74';
const String _molarLowerGroove = 'M50,20 L50,80 M22,50 L78,50';
const String _wisdomGroove = 'M30,50 L70,50';

final Map<String, Path> _baseCache = {};

Path _parseCached(String svg) =>
    _baseCache.putIfAbsent(svg, () => parseSvgPathData(svg));

/// Trazos ya ajustados a un tamaño concreto, indexados por trazo y tamaño.
///
/// El parseo del SVG ya estaba memorizado, pero el ajuste no: `_fit` corre
/// dentro del bucle de `paint` de la arcada, una vez por pieza y por trazo.
/// Con 32 piezas eso son ~64 `Path` nuevos en cada repintado, y la arcada
/// repinta entera con solo mover el ratón por encima. Como la geometría
/// depende únicamente de la forma y del tamaño, el resultado se puede guardar.
///
/// La caché se mantiene acotada porque los tamaños distintos son pocos —los
/// que produzcan los breakpoints—, pero un `LayoutBuilder` con tamaños
/// continuos podría generar muchos: al pasarse del tope se vacía entera en vez
/// de crecer sin límite.
final Map<(String, Size), Path> _fittedCache = {};
const int _maxFitted = 128;

Path _fitCached(String svg, Size size) {
  final clave = (svg, size);
  final memorizado = _fittedCache[clave];
  if (memorizado != null) return memorizado;

  if (_fittedCache.length >= _maxFitted) _fittedCache.clear();
  return _fittedCache[clave] = _fit(_parseCached(svg), size);
}

/// Transform a 0–100 viewBox path to a [size]-sized path centered at origin.
Path _fit(Path base, Size size) {
  final m = Matrix4.identity()
    ..translateByDouble(-size.width / 2, -size.height / 2, 0, 1)
    ..scaleByDouble(size.width / 100.0, size.height / 100.0, 1, 1);
  return base.transform(m.storage);
}

/// Tooth outline path, centered at (0,0), sized to [size].
Path buildToothPath(ToothType type, Size size) {
  return _fitCached(_shapeSvgFor(type), size);
}

/// Occlusal groove path for [type], or null if the tooth has no groove
/// detail. [upper] selects the molar groove pattern (Y vs. cross).
Path? buildGroovePath(ToothType type, Size size, {required bool upper}) {
  final svg = switch (type) {
    ToothType.premolar => _premolarGroove,
    ToothType.molar => upper ? _molarUpperGroove : _molarLowerGroove,
    ToothType.wisdom => _wisdomGroove,
    ToothType.incisor || ToothType.canine => null,
  };
  if (svg == null) return null;
  return _fitCached(svg, size);
}

// ─────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────

/// True if the tooth belongs to the upper arch (FDI quadrant 1 or 2)
bool isUpperTooth(int fdi) =>
    (fdi >= 11 && fdi <= 28) || (fdi >= 51 && fdi <= 68);

/// True if the tooth is an anterior tooth (incisor or canine)
bool isAnteriorTooth(int fdi) {
  final type = toothTypeFor(fdi);
  return type == ToothType.incisor || type == ToothType.canine;
}
