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
      consumibleId: json['consumibleId'],
      compraId: json['compraId'],
      cantidad: json['cantidad'],
      suplidorId: json['suplidorId'],
      precioUnitario: (json['precioUnitario'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'consumibleId': consumibleId,
      'compraId': compraId,
      'cantidad': cantidad,
      'suplidorId': suplidorId,
      'precioUnitario': precioUnitario,
    };
  }
}
