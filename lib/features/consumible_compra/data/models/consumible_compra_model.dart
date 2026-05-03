import 'package:salud_dental_clinic_management/features/consumible_compra/domain/entities/consumible_compra.dart';

class ConsumibleCompraModel extends ConsumibleCompra {
  ConsumibleCompraModel({
    super.id,
    required super.consumibleId,
    required super.compraId,
    required super.cantidad,
    required super.suplidorId,
    required super.precioUnitario,
  });

  factory ConsumibleCompraModel.fromJson(Map<String, dynamic> json) {
    return ConsumibleCompraModel(
      id: json['id'] as String?,
      consumibleId: json['consumible_id'],
      compraId: json['compra_id'],
      cantidad: json['cantidad'],
      suplidorId: json['suplidor_id'],
      precioUnitario: (json['precio_unitario'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'consumible_id': consumibleId,
      'compra_id': compraId,
      'cantidad': cantidad,
      'suplidor_id': suplidorId,
      'precio_unitario': precioUnitario,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
