import 'package:salud_dental_clinic_management/features/item_cuenta/domain/entities/item_cuenta.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/data/models/tratamiento_model.dart';

class ItemCuentaModel extends ItemCuenta {
  ItemCuentaModel({
    required super.id,
    required super.cuentaId,
    required super.descripcion,
    required super.precioUnitario,
    required super.cantidad,
    super.tratamientosAplicados,
  });

  factory ItemCuentaModel.fromJson(Map<String, dynamic> json) {
    return ItemCuentaModel(
      id: json['id'] as String,
      cuentaId: json['cuenta_id'] ?? json['cuentaId'],
      descripcion: json['descripcion'] as String,
      precioUnitario: (json['precio_unitario'] ?? json['precioUnitario'] as num)
          .toDouble(),
      cantidad: (json['cantidad'] as num).toInt(),

      tratamientosAplicados:
          json['tratamientos_aplicados'] != null ||
              json['tratamientosAplicados'] != null
          ? (json['tratamientos_aplicados'] ??
                    json['tratamientosAplicados'] as List)
                .map(
                  (t) => TratamientoModel.fromJson(t as Map<String, dynamic>),
                )
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cuenta_id': cuentaId,
      'descripcion': descripcion,
      'precio_unitario': precioUnitario,
      'cantidad': cantidad,
      'tratamientos_aplicados': tratamientosAplicados
          .map((t) => (t as TratamientoModel).toJson())
          .toList(),
    };
  }
}
