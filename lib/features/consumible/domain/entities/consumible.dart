import 'package:salud_dental_clinic_management/features/consumible/domain/enums/consumible_estado.dart';

class Consumible {
  final String id;
  final String nombre;
  final String descripcion;
  final int stockActual;
  final int stockMinimo;
  final ConsumibleEstado estado;

  Consumible({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.stockActual,
    required this.stockMinimo,
    required this.estado,
  });

  bool get estaBajoStock => stockActual <= stockMinimo;
  bool get estaAgotado => stockActual <= 0;

  Consumible copyWith({int? stockActual, ConsumibleEstado? estado}) {
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
