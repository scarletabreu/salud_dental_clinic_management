import 'package:salud_dental_clinic_management/features/consumible_compra/domain/entities/consumible_compra.dart';

class ConsumibleCompraModel extends ConsumibleCompra {
  ConsumibleCompraModel({
    required super.id,
    required super.consumibleId,
    required super.compraId,
    required super.cantidad,
    required super.suplidorId,
    required super.precioUnitario,
  });

  factory ConsumibleCompraModel.fromJson(Map<String, dynamic> json) {
    return ConsumibleCompraModel(
      id: json['id'],
      consumibleId: json['consumible_id'],
      compraId: json['compra_id'],
      cantidad: json['cantidad'],
      suplidorId: json['suplidor_id'],
      precioUnitario: (json['precio_unitario'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'consumible_id': consumibleId,
      'compra_id': compraId,
      'cantidad': cantidad,
      'suplidor_id': suplidorId,
      'precio_unitario': precioUnitario,
    };
  }
}
