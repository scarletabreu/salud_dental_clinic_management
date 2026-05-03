import 'package:salud_dental_clinic_management/features/item_cuenta/domain/entities/item_cuenta.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/data/models/tratamiento_model.dart';

class ItemCuentaModel extends ItemCuenta {
  ItemCuentaModel({
    super.id,
    required super.cuentaId,
    required super.descripcion,
    required super.precioUnitario,
    required super.cantidad,
    super.tratamientosAplicados,
  });

  factory ItemCuentaModel.fromJson(Map<String, dynamic> json) {
    return ItemCuentaModel(
      id: json['id'] as String?,
      cuentaId: json['cuenta_id'] ?? json['cuentaId'],
      descripcion: json['descripcion'] as String,
      precioUnitario: (json['precio_unitario'] ?? json['precioUnitario'] as num)
          .toDouble(),
      cantidad: (json['cantidad'] as num).toInt(),
      tratamientosAplicados: [],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'cuenta_id': cuentaId,
      'descripcion': descripcion,
      'precio_unitario': precioUnitario,
      'cantidad': cantidad,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
