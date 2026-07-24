import 'package:salud_dental_clinic_management/features/consumible/domain/enums/estado_consumible.dart';

class Consumible {
  final String? id;
  final String nombre;
  final String descripcion;
  final double precio;
  final int stockActual;
  final int stockMinimo;
  final EstadoConsumible estado;
  final String? suplidorId;
  final String? suplidorNombre;
  final bool activo;

  Consumible({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.stockActual,
    required this.stockMinimo,
    required this.estado,
    this.suplidorId,
    this.suplidorNombre,
    this.activo = true,
  });

  bool get estaBajoStock => stockActual <= stockMinimo;
  bool get estaAgotado => stockActual <= 0;

  EstadoConsumible get estadoCalculado {
    if (!activo) return EstadoConsumible.descontinuado;
    if (estaAgotado) return EstadoConsumible.agotado;
    if (estaBajoStock) return EstadoConsumible.bajoStock;
    return EstadoConsumible.disponible;
  }

  Consumible copyWith({
    int? stockActual,
    EstadoConsumible? estado,
    bool? activo,
  }) {
    return Consumible(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      precio: precio,
      stockActual: stockActual ?? this.stockActual,
      stockMinimo: stockMinimo,
      estado: estado ?? this.estado,
      suplidorId: suplidorId,
      suplidorNombre: suplidorNombre,
      activo: activo ?? this.activo,
    );
  }
}
