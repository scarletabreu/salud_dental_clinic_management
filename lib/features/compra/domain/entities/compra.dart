import 'package:salud_dental_clinic_management/features/compra/domain/enums/estado_compra.dart';
import 'package:salud_dental_clinic_management/features/consumible_compra/domain/entities/consumible_compra.dart';

class Compra {
  final String? id;
  final DateTime fecha;
  final List<ConsumibleCompra> items;
  final EstadoCompra estado;

  Compra({
    this.id,
    required this.fecha,
    required this.items,
    required this.estado,
  });

  double get precioTotal =>
      items.fold(0, (sum, item) => sum + item.precioUnitario * item.cantidad);

  Compra copyWith({
    DateTime? fecha,
    List<ConsumibleCompra>? items,
    EstadoCompra? estado,
  }) {
    return Compra(
      id: id,
      fecha: fecha ?? this.fecha,
      items: items ?? this.items,
      estado: estado ?? this.estado,
    );
  }
}
