import 'package:salud_dental_clinic_management/features/consumible/domain/entities/consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/enums/estado_consumible.dart';

class ConsumibleModel extends Consumible {
  ConsumibleModel({
    super.id,
    required super.nombre,
    required super.descripcion,
    required super.precio,
    required super.stockActual,
    required super.stockMinimo,
    required super.estado,
    super.suplidorId,
    super.suplidorNombre,
    super.activo,
  });

  factory ConsumibleModel.fromJson(Map<String, dynamic> json) {
    return ConsumibleModel(
      id: json['id'] as String?,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] ?? '',
      precio: (json['precio'] as num? ?? 0).toDouble(),
      stockActual: ((json['stock_actual'] ?? json['stockActual']) as num? ?? 0)
          .toInt(),
      stockMinimo: ((json['stock_minimo'] ?? json['stockMinimo']) as num? ?? 0)
          .toInt(),
      estado: EstadoConsumible.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EstadoConsumible.disponible,
      ),
      suplidorId: json['suplidor_id'] as String?,
      suplidorNombre: json['suplidor'] is Map<String, dynamic>
          ? json['suplidor']['nombre'] as String?
          : null,
      activo: json['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'stock_actual': stockActual,
      'stock_minimo': stockMinimo,
      'estado': estado.name,
      'suplidor_id': suplidorId,
      'activo': activo,
    };

    return data;
  }
}
