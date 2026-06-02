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
    return CompraModel(
      id: json['id'] as String?,
      fecha: DateTime.parse(json['fecha'] as String),
      items: (json['items'] as List)
          .map((e) => ConsumibleCompraModel.fromJson(e))
          .toList(),
      estado: EstadoCompra.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EstadoCompra.pendente,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'fecha': fecha.toIso8601String(),
      'estado': estado.name,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
