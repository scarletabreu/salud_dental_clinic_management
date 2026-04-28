class ConsumibleCompra {
  final String id;
  final String consumibleId;
  final String compraId;
  final int cantidad;
  final String suplidorId;
  final double precioUnitario;

  ConsumibleCompra({
    required this.id,
    required this.consumibleId,
    required this.compraId,
    required this.cantidad,
    required this.suplidorId,
    required this.precioUnitario,
  });

  ConsumibleCompra copyWith({
    String? consumibleId,
    String? compraId,
    int? cantidad,
    String? suplidorId,
    double? precioUnitario,
  }) {
    return ConsumibleCompra(
      id: id,
      consumibleId: consumibleId ?? this.consumibleId,
      compraId: compraId ?? this.compraId,
      cantidad: cantidad ?? this.cantidad,
      suplidorId: suplidorId ?? this.suplidorId,
      precioUnitario: precioUnitario ?? this.precioUnitario,
    );
  }
}
