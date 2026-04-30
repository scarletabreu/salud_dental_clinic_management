import 'package:salud_dental_clinic_management/features/consumible/domain/entities/consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/enums/estado_consumible.dart';

class ConsumibleModel extends Consumible {
  ConsumibleModel({
    required super.id,
    required super.nombre,
    required super.descripcion,
    required super.stockActual,
    required super.stockMinimo,
    required super.estado,
  });

  factory ConsumibleModel.fromJson(Map<String, dynamic> json) {
    return ConsumibleModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] ?? '',
      stockActual: (json['stock_actual'] ?? json['stockActual'] as num).toInt(),
      stockMinimo: (json['stock_minimo'] ?? json['stockMinimo'] as num).toInt(),
      estado: EstadoConsumible.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EstadoConsumible.disponible,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'nombre': nombre,
      'descripcion': descripcion,
      'stock_actual': stockActual,
      'stock_minimo': stockMinimo,
      'estado': estado.name,
    };

    if (id.isNotEmpty) {
      json['id'] = id;
    }
    return json;
  }
}
