class CajaDiaria {
  final String id;
  final DateTime fecha;
  final double montoApertura;
  final double montoCierre;
  final double montoEsperado;
  final double montoReal;
  final bool cerrada;

  CajaDiaria({
    required this.id,
    required this.fecha,
    required this.montoApertura,
    required this.montoCierre,
    required this.montoEsperado,
    required this.montoReal,
    this.cerrada = false,
  });

  double get diferencia => montoReal - montoEsperado;

  bool get tieneFaltante => diferencia < 0;

  CajaDiaria copyWith({
    DateTime? fecha,
    double? montoApertura,
    double? montoCierre,
    double? montoEsperado,
    double? montoReal,
    bool? cerrada,
  }) {
    return CajaDiaria(
      id: id,
      fecha: fecha ?? this.fecha,
      montoApertura: montoApertura ?? this.montoApertura,
      montoCierre: montoCierre ?? this.montoCierre,
      montoEsperado: montoEsperado ?? this.montoEsperado,
      montoReal: montoReal ?? this.montoReal,
      cerrada: cerrada ?? this.cerrada,
    );
  }
}
