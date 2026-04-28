import 'package:salud_dental_clinic_management/features/compra/domain/entities/compra.dart';
import 'package:salud_dental_clinic_management/features/consumible_compra/data/models/consumible_compra_model.dart';
import 'package:salud_dental_clinic_management/features/compra/domain/enums/estado_compra.dart';

class CompraModel extends Compra {
  CompraModel({
    required super.id,
    required super.fecha,
    required super.items,
    required super.estado,
  });

  factory CompraModel.fromJson(Map<String, dynamic> json) {
    return CompraModel(
      id: json['id'],
      fecha: DateTime.parse(json['fecha']),
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
    return {
      'id': id,
      'fecha': fecha.toIso8601String(),
      'items': items.map((e) => (e as ConsumibleCompraModel).toJson()).toList(),
      'estado': estado.name,
    };
  }
}
