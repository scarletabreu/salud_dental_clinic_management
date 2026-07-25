/// Disposición del ODONTODIAGRAMA tal como está impreso en el formulario:
/// cuatro filas por hemiarcada, con la dentición temporal hacia la línea
/// media y la permanente hacia fuera.
///
/// ```
///   Cuadrante 1  18…11 │ 21…28  Cuadrante 2
///                55…51 │ 61…65
///   ───────────────────┼───────────────────
///                85…81 │ 71…75
///   Cuadrante 4  48…41 │ 31…38  Cuadrante 3
/// ```
///
/// El hemicampo izquierdo del papel es el lado derecho del paciente.
library;

import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

/// Permanentes superiores derechos (hemicampo izquierdo, fila exterior).
const List<int> kCuadrante1 = [18, 17, 16, 15, 14, 13, 12, 11];

/// Permanentes superiores izquierdos.
const List<int> kCuadrante2 = [21, 22, 23, 24, 25, 26, 27, 28];

/// Permanentes inferiores izquierdos.
const List<int> kCuadrante3 = [31, 32, 33, 34, 35, 36, 37, 38];

/// Permanentes inferiores derechos.
const List<int> kCuadrante4 = [48, 47, 46, 45, 44, 43, 42, 41];

/// Temporales superiores derechos.
const List<int> kCuadrante5 = [55, 54, 53, 52, 51];

/// Temporales superiores izquierdos.
const List<int> kCuadrante6 = [61, 62, 63, 64, 65];

/// Temporales inferiores izquierdos.
const List<int> kCuadrante7 = [71, 72, 73, 74, 75];

/// Temporales inferiores derechos.
const List<int> kCuadrante8 = [85, 84, 83, 82, 81];

/// Una hilera de piezas del diagrama.
class FilaOdontodiagrama {
  /// Piezas en el orden impreso, de fuera hacia la línea media.
  final List<int> piezas;

  /// La fila pertenece al maxilar (cuadrantes 1, 2, 5 y 6).
  final bool superior;

  /// La fila está en el hemicampo izquierdo del papel (lado derecho del
  /// paciente): la línea media —y por tanto la cara mesial— queda a la derecha.
  final bool hemicampoIzquierdo;

  /// Dentición temporal: se dibuja con glifo circular.
  final bool temporal;

  /// Rótulo impreso junto a la fila, solo en las cuatro filas permanentes.
  final String? rotulo;

  const FilaOdontodiagrama({
    required this.piezas,
    required this.superior,
    required this.hemicampoIzquierdo,
    required this.temporal,
    this.rotulo,
  });
}

/// Las ocho hileras, de arriba abajo y de izquierda a derecha del papel.
const List<List<FilaOdontodiagrama>> kFilasOdontodiagrama = [
  [
    FilaOdontodiagrama(
      piezas: kCuadrante1,
      superior: true,
      hemicampoIzquierdo: true,
      temporal: false,
      rotulo: 'Cuadrante 1',
    ),
    FilaOdontodiagrama(
      piezas: kCuadrante2,
      superior: true,
      hemicampoIzquierdo: false,
      temporal: false,
      rotulo: 'Cuadrante 2',
    ),
  ],
  [
    FilaOdontodiagrama(
      piezas: kCuadrante5,
      superior: true,
      hemicampoIzquierdo: true,
      temporal: true,
    ),
    FilaOdontodiagrama(
      piezas: kCuadrante6,
      superior: true,
      hemicampoIzquierdo: false,
      temporal: true,
    ),
  ],
  [
    FilaOdontodiagrama(
      piezas: kCuadrante8,
      superior: false,
      hemicampoIzquierdo: true,
      temporal: true,
    ),
    FilaOdontodiagrama(
      piezas: kCuadrante7,
      superior: false,
      hemicampoIzquierdo: false,
      temporal: true,
    ),
  ],
  [
    FilaOdontodiagrama(
      piezas: kCuadrante4,
      superior: false,
      hemicampoIzquierdo: true,
      temporal: false,
      rotulo: 'Cuadrante 4',
    ),
    FilaOdontodiagrama(
      piezas: kCuadrante3,
      superior: false,
      hemicampoIzquierdo: false,
      temporal: false,
      rotulo: 'Cuadrante 3',
    ),
  ],
];

/// Columnas por hemicampo: las filas temporales, de cinco piezas, se alinean
/// contra la línea media dejando tres huecos por fuera.
const int kColumnasPorHemicampo = 8;

/// Un diente anterior (incisivo o canino) tiene borde incisal en vez de
/// superficie oclusal.
bool esAnteriorFdi(int fdi) => fdi % 10 <= 3;

/// Superficie central del glifo: incisal en anteriores, oclusal en posteriores.
TipoSuperficie superficieCentral(int fdi) =>
    esAnteriorFdi(fdi) ? TipoSuperficie.incisal : TipoSuperficie.oclusal;

/// Cara lingual de la pieza: palatina en el maxilar, lingual en la mandíbula.
TipoSuperficie superficieLingual(bool superior) =>
    superior ? TipoSuperficie.palatina : TipoSuperficie.lingual;
