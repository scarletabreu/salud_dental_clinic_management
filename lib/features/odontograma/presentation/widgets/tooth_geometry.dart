import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  Tooth type
// ─────────────────────────────────────────────

enum ToothType { incisor, canine, premolar, molar, wisdom }

ToothType toothTypeFor(int fdi) {
  return switch (fdi % 10) {
    1 || 2 => ToothType.incisor,
    3 => ToothType.canine,
    4 || 5 => ToothType.premolar,
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
};

// ─────────────────────────────────────────────
//  Normalized arch positions (0–1)
//  Origin: top-left of canvas (y increases down)
//  Upper arch teeth curve downward toward center gap
//  Lower arch teeth curve upward toward center gap
// ─────────────────────────────────────────────

const Map<int, Offset> kNorm = {
  // Q1 — upper right (viewer's left, patient's right)
  18: Offset(0.048, 0.065),
  17: Offset(0.132, 0.132),
  16: Offset(0.214, 0.196),
  15: Offset(0.289, 0.258),
  14: Offset(0.352, 0.313),
  13: Offset(0.404, 0.356),
  12: Offset(0.446, 0.383),
  11: Offset(0.479, 0.399),
  // Q2 — upper left
  21: Offset(0.521, 0.399),
  22: Offset(0.554, 0.383),
  23: Offset(0.596, 0.356),
  24: Offset(0.648, 0.313),
  25: Offset(0.711, 0.258),
  26: Offset(0.786, 0.196),
  27: Offset(0.868, 0.132),
  28: Offset(0.952, 0.065),
  // Q3 — lower left
  31: Offset(0.521, 0.601),
  32: Offset(0.554, 0.617),
  33: Offset(0.596, 0.644),
  34: Offset(0.648, 0.687),
  35: Offset(0.711, 0.742),
  36: Offset(0.786, 0.804),
  37: Offset(0.868, 0.868),
  38: Offset(0.952, 0.935),
  // Q4 — lower right
  41: Offset(0.479, 0.601),
  42: Offset(0.446, 0.617),
  43: Offset(0.404, 0.644),
  44: Offset(0.352, 0.687),
  45: Offset(0.289, 0.742),
  46: Offset(0.214, 0.804),
  47: Offset(0.132, 0.868),
  48: Offset(0.048, 0.935),
};

// ─────────────────────────────────────────────
//  Rotation angles (radians) per FDI
//  Approximate tangent to the arch curve at each tooth position
// ─────────────────────────────────────────────

const Map<int, double> kAngles = {
  // Upper right — curve from ~-50° at molar toward 0° at center
  18: -0.42, 17: -0.33, 16: -0.24, 15: -0.17, 14: -0.11, 13: -0.06, 12: -0.02, 11: 0.0,
  // Upper left — mirror
  21: 0.0, 22: 0.02, 23: 0.06, 24: 0.11, 25: 0.17, 26: 0.24, 27: 0.33, 28: 0.42,
  // Lower left — same as upper left (arch is symmetric)
  31: 0.0, 32: 0.02, 33: 0.06, 34: 0.11, 35: 0.17, 36: 0.24, 37: 0.33, 38: 0.42,
  // Lower right — mirror
  41: 0.0, 42: -0.02, 43: -0.06, 44: -0.11, 45: -0.17, 46: -0.24, 47: -0.33, 48: -0.42,
};

// ─────────────────────────────────────────────
//  Tooth size multipliers per type
// ─────────────────────────────────────────────

Size toothSizeFor(ToothType type, double baseW, double baseH) {
  return switch (type) {
    ToothType.incisor => Size(baseW * 0.85, baseH * 1.00),
    ToothType.canine => Size(baseW * 0.90, baseH * 1.10),
    ToothType.premolar => Size(baseW * 1.00, baseH * 0.95),
    ToothType.molar => Size(baseW * 1.18, baseH * 0.90),
    ToothType.wisdom => Size(baseW * 1.08, baseH * 0.85),
  };
}

// ─────────────────────────────────────────────
//  Path builders — all paths centered at (0,0)
// ─────────────────────────────────────────────

Path buildToothPath(ToothType type, double w, double h) {
  return switch (type) {
    ToothType.incisor => _incisorPath(w, h),
    ToothType.canine => _caninePath(w, h),
    ToothType.premolar => _premolarPath(w, h),
    ToothType.molar => _molarPath(w, h),
    ToothType.wisdom => _wisdomPath(w, h),
  };
}

// Incisor: slightly trapezoidal — wider at labial (top/outer), narrower incisal edge (bottom/inner).
// The "inner" edge (facing the arch gap) is slightly narrower to create a tapered look.
Path _incisorPath(double w, double h) {
  final hw = w / 2;
  final hh = h / 2;
  const taper = 0.10; // 10% narrower at incisal edge
  final path = Path()
    ..moveTo(-hw, -hh)                     // top-left (labial)
    ..lineTo(hw, -hh)                      // top-right
    ..lineTo(hw * (1 - taper), hh)         // bottom-right (incisal, slightly inward)
    ..lineTo(-hw * (1 - taper), hh)        // bottom-left (incisal)
    ..close();
  return _roundPath(path, 3.0);
}

// Canine: wider body tapering to a pointed cusp at the incisal (inner) edge.
Path _caninePath(double w, double h) {
  final hw = w / 2;
  final hh = h / 2;
  final path = Path()
    ..moveTo(-hw, -hh)           // top-left
    ..lineTo(hw, -hh)            // top-right
    ..lineTo(hw * 0.6, hh * 0.3) // right shoulder
    ..lineTo(0, hh)              // cusp tip (center, incisal point)
    ..lineTo(-hw * 0.6, hh * 0.3) // left shoulder
    ..close();
  return _roundPath(path, 3.5);
}

// Premolar: rectangular with two small cusp bumps on the oclusal (inner) edge.
Path _premolarPath(double w, double h) {
  final hw = w / 2;
  final hh = h / 2;
  final bumpH = h * 0.12;
  final bumpW = w * 0.25;

  final path = Path()
    ..moveTo(-hw, -hh)
    ..lineTo(hw, -hh)
    ..lineTo(hw, hh - bumpH)
    // Right cusp bump
    ..relativeArcToPoint(Offset(0, bumpH), radius: const Radius.circular(3), clockwise: false)
    ..lineTo(bumpW, hh)
    // Valley between cusps
    ..cubicTo(bumpW * 0.5, hh - bumpH * 0.5, -bumpW * 0.5, hh - bumpH * 0.5, -bumpW, hh)
    // Left cusp bump
    ..lineTo(-hw, hh - bumpH)
    ..relativeArcToPoint(Offset(0, bumpH), radius: const Radius.circular(3), clockwise: false)
    ..lineTo(-hw, hh)
    ..lineTo(-hw, -hh)
    ..close();
  return path;
}

// Molar: wide rounded rectangle with four corner cusp bumps on the oclusal edge.
Path _molarPath(double w, double h) {
  final hw = w / 2;
  final hh = h / 2;
  final bumpR = math.min(w * 0.13, h * 0.15);
  final cr = 4.0; // corner radius of main body

  final path = Path()
    // Top edge (labial/buccal — smooth)
    ..moveTo(-hw + cr, -hh)
    ..lineTo(hw - cr, -hh)
    ..arcToPoint(Offset(hw, -hh + cr), radius: Radius.circular(cr))
    // Right side
    ..lineTo(hw, hh - bumpR * 1.5)
    // Bottom-right cusp bump
    ..arcToPoint(Offset(hw - bumpR, hh), radius: Radius.circular(bumpR), clockwise: false)
    // Bottom between right and center-right
    ..lineTo(bumpR, hh)
    // Center-right cusp bump (slight dip in center)
    ..cubicTo(bumpR * 0.4, hh - bumpR * 0.6, -bumpR * 0.4, hh - bumpR * 0.6, -bumpR, hh)
    // Bottom between center-left and left cusp
    ..lineTo(-(hw - bumpR), hh)
    // Bottom-left cusp bump
    ..arcToPoint(Offset(-hw, hh - bumpR * 1.5), radius: Radius.circular(bumpR), clockwise: false)
    // Left side
    ..lineTo(-hw, -hh + cr)
    ..arcToPoint(Offset(-hw + cr, -hh), radius: Radius.circular(cr))
    ..close();
  return path;
}

// Wisdom: compact molar — same shape but drawn at a tighter profile
Path _wisdomPath(double w, double h) => _molarPath(w, h);

// ─────────────────────────────────────────────
//  Path corner-rounding utility (approximation via stroke join)
//  For simple polygonal paths (incisor, canine), round corners by
//  rebuilding the path with small arc at each vertex.
// ─────────────────────────────────────────────

Path _roundPath(Path src, double radius) {
  // Flutter's PathMetrics can extract points but re-rounding a polygon
  // programmatically is complex. For our simple shapes (4–5 vertices),
  // we achieve visual rounding by using a large stroke join radius in
  // the Paint — callers should use Paint()..strokeJoin = StrokeJoin.round.
  // This function returns the path as-is; the Paint handles rounding.
  return src;
}

// ─────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────

/// True if the tooth belongs to the upper arch (FDI quadrant 1 or 2)
bool isUpperTooth(int fdi) => fdi >= 11 && fdi <= 28;

/// True if the tooth is an anterior tooth (incisor or canine)
bool isAnteriorTooth(int fdi) {
  final type = toothTypeFor(fdi);
  return type == ToothType.incisor || type == ToothType.canine;
}
