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
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      precio: (json['precio'] ?? 0 as num).toDouble(),
      stockActual: (json['stock_actual'] ?? json['stockActual'] ?? 0 as num)
          .toInt(),
      stockMinimo: (json['stock_minimo'] ?? json['stockMinimo'] ?? 0 as num)
          .toInt(),
      estado: _parseEstado(json['estado'] as String?),
    );
  }

  static EstadoConsumible _parseEstado(String? estadoStr) {
    if (estadoStr == null) return EstadoConsumible.disponible;
    switch (estadoStr) {
      case 'bajo_stock':
      case 'bajoStock':
        return EstadoConsumible.bajoStock;
      case 'agotado':
        return EstadoConsumible.agotado;
      case 'descontinuado':
        return EstadoConsumible.descontinuado;
      case 'disponible':
      default:
        return EstadoConsumible.disponible;
    }
  }

  static String _estadoToPg(EstadoConsumible estado) {
    switch (estado) {
      case EstadoConsumible.bajoStock:
        return 'bajo_stock';
      case EstadoConsumible.disponible:
        return 'disponible';
      case EstadoConsumible.agotado:
        return 'agotado';
      case EstadoConsumible.descontinuado:
        return 'descontinuado';
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'stock_actual': stockActual,
      'stock_minimo': stockMinimo,
      'estado': _estadoToPg(estado),
    };

    if (id != null && id!.trim().isNotEmpty && id!.contains('-')) {
      data['id'] = id;
    }

    return data;
  }
}
