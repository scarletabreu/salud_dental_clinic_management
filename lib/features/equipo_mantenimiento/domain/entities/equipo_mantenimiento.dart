class EquipoMantenimiento {
  final String? id;
  final String equipoId;
  final String? consumibleId;
  final String descripcion;
  final String? suplidorId;
  final double costo;
  final DateTime fechaMantenimiento;

  EquipoMantenimiento({
    this.id,
    required this.equipoId,
    this.consumibleId,
    required this.descripcion,
    this.suplidorId,
    required this.costo,
    required this.fechaMantenimiento,
  });

  EquipoMantenimiento copyWith({
    String? equipoId,
    String? consumibleId,
    String? descripcion,
    String? suplidorId,
    double? costo,
    DateTime? fechaMantenimiento,
  }) {
    return EquipoMantenimiento(
      id: id,
      equipoId: equipoId ?? this.equipoId,
      consumibleId: consumibleId ?? this.consumibleId,
      descripcion: descripcion ?? this.descripcion,
      suplidorId: suplidorId ?? this.suplidorId,
      costo: costo ?? this.costo,
      fechaMantenimiento: fechaMantenimiento ?? this.fechaMantenimiento,
    );
  }
}
