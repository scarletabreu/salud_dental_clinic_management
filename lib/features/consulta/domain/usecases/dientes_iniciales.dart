import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

/// Códigos FDI de la dentición permanente (32 dientes), por cuadrante.
const List<int> kFdiPermanentes = [
  // Cuadrante 1 — superior derecho
  11, 12, 13, 14, 15, 16, 17, 18,
  // Cuadrante 2 — superior izquierdo
  21, 22, 23, 24, 25, 26, 27, 28,
  // Cuadrante 3 — inferior izquierdo
  31, 32, 33, 34, 35, 36, 37, 38,
  // Cuadrante 4 — inferior derecho
  41, 42, 43, 44, 45, 46, 47, 48,
];

/// Diente anterior = incisivo o canino (último dígito FDI 1, 2 o 3).
bool _esAnterior(int fdi) {
  final ultimo = fdi % 10;
  return ultimo >= 1 && ultimo <= 3;
}

/// Diente del maxilar superior (cuadrantes 1 y 2).
bool _esSuperior(int fdi) => fdi >= 11 && fdi <= 28;

/// Superficies que corresponden a un diente según su código FDI.
///
/// Todos llevan Mesial, Distal, Vestibular y la cara interna (Palatina en
/// superiores, Lingual en inferiores). La quinta cara es Incisal en dientes
/// anteriores (incisivos/caninos) y Oclusal en posteriores (premolares/molares).
List<TipoSuperficie> superficiesParaFdi(int fdi) {
  return [
    TipoSuperficie.mesial,
    TipoSuperficie.distal,
    TipoSuperficie.vestibular,
    _esSuperior(fdi) ? TipoSuperficie.palatina : TipoSuperficie.lingual,
    _esAnterior(fdi) ? TipoSuperficie.incisal : TipoSuperficie.oclusal,
  ];
}
