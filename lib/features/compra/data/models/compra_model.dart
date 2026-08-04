import 'package:salud_dental_clinic_management/features/compra/domain/entities/compra.dart';
import 'package:salud_dental_clinic_management/features/consumible_compra/data/models/consumible_compra_model.dart';
import 'package:salud_dental_clinic_management/features/compra/domain/enums/estado_compra.dart';

class CompraModel extends Compra {
  CompraModel({
    super.id,
    required super.fecha,
    required super.items,
    required super.estado,
  });

  factory CompraModel.fromJson(Map<String, dynamic> json) {
    final crudo = json['estado'] as String?;
    final estado = EstadoCompra.fromDb(crudo);
    if (estado == null) {
      // Antes caía en «pendiente»: una compra recibida se mostraba pendiente y
      // se ofrecía para recibir otra vez. Fallar aquí es visible y corregible.
      throw FormatException(
        'La compra ${json['id']} tiene un estado que la aplicación no conoce: '
        '"$crudo".',
      );
    }
    return CompraModel(
      id: json['id'] as String?,
      fecha: DateTime.parse(json['fecha'] as String),
      items: (json['items'] as List)
          .map((e) => ConsumibleCompraModel.fromJson(e))
          .toList(),
      estado: estado,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'fecha': fecha.toUtc().toIso8601String(),
      'estado': estado.dbValue,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
