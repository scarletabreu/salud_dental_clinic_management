import 'package:salud_dental_clinic_management/features/consumible/domain/enums/estado_consumible.dart';

class Consumible {
  final String? id;
  final String nombre;
  final String descripcion;
  final int stockActual;
  final int stockMinimo;
  final EstadoConsumible estado;

  Consumible({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.stockActual,
    required this.stockMinimo,
    required this.estado,
  });

  bool get estaBajoStock => stockActual <= stockMinimo;
  bool get estaAgotado => stockActual <= 0;

  Consumible copyWith({int? stockActual, EstadoConsumible? estado}) {
    return Consumible(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      stockActual: stockActual ?? this.stockActual,
      stockMinimo: stockMinimo,
      estado: estado ?? this.estado,
    );
  }
}
