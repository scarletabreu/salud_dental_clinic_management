class OrdenMedica {
  final String? id;
  final DateTime fecha;
  final String procedimientoId;
  final String? notas;

  OrdenMedica({
    this.id,
    required this.fecha,
    required this.procedimientoId,
    this.notas,
  });

  OrdenMedica copyWith({
    DateTime? fecha,
    String? procedimientoId,
    String? notas,
  }) {
    return OrdenMedica(
      id: id,
      fecha: fecha ?? this.fecha,
      procedimientoId: procedimientoId ?? this.procedimientoId,
      notas: notas ?? this.notas,
    );
  }
}
