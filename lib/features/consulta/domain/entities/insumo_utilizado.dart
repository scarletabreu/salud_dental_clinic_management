/// Un consumible descontado del inventario como parte del cierre de una
/// consulta. Vive en memoria dentro de `Consulta` igual que las recetas: se
/// autoguarda con el resto y solo se descuenta stock al finalizar.
class InsumoUtilizado {
  final String consumibleId;

  /// Copia del nombre en el momento de agregarlo, para no depender del
  /// catálogo al reconstruir la UI (p. ej. al reanudar una consulta).
  final String nombre;
  final int cantidad;

  const InsumoUtilizado({
    required this.consumibleId,
    required this.nombre,
    required this.cantidad,
  });

  InsumoUtilizado copyWith({int? cantidad}) => InsumoUtilizado(
    consumibleId: consumibleId,
    nombre: nombre,
    cantidad: cantidad ?? this.cantidad,
  );

  Map<String, dynamic> toJson() => {
    'consumible_id': consumibleId,
    'cantidad': cantidad,
  };
}