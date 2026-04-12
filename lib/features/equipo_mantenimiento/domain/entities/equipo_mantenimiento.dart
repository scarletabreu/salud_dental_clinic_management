class EquipoMantenimiento {
  final String equipoId;
  final String consumibleId;
  final String descripcion;
  final String suplidorId;
  final double costo;

  EquipoMantenimiento({
    required this.equipoId,
    required this.consumibleId,
    required this.descripcion,
    required this.suplidorId,
    required this.costo,
  });

  EquipoMantenimiento copyWith({
    String? equipoId,
    String? consumibleId,
    String? descripcion,
    String? suplidorId,
    double? costo,
  }) {
    return EquipoMantenimiento(
      equipoId: equipoId ?? this.equipoId,
      consumibleId: consumibleId ?? this.consumibleId,
      descripcion: descripcion ?? this.descripcion,
      suplidorId: suplidorId ?? this.suplidorId,
      costo: costo ?? this.costo,
    );
  }
}
