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
      suplidorId:
          json['suplidor_id'] as String? ?? json['suplidorId'] as String?,
      suplidorNombre: _nombreSuplidor(json),
      // `activo` es la baja lógica del catálogo: `deleteConsumible` lo pone en
      // false en vez de borrar la fila. Sin leerlo, un consumible dado de baja
      // seguía apareciendo como disponible y `estadoCalculado` nunca decía
      // «descontinuado».
      activo: json['activo'] as bool? ?? true,
    );
  }

  /// El nombre del suplidor llega del embed `suplidor:suplidores(nombre)`; se
  /// acepta también plano por si la fila viene de una consulta sin join.
  static String? _nombreSuplidor(Map<String, dynamic> json) {
    final suplidor = json['suplidor'] ?? json['suplidores'];
    if (suplidor is Map) return suplidor['nombre'] as String?;
    return json['suplidor_nombre'] as String?;
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
      // Sin estas dos, guardar un consumible desvinculaba su suplidor y lo
      // reactivaba: el formulario las recoge y aquí se perdían.
      'suplidor_id': suplidorId,
      'activo': activo,
    };

    if (id != null && id!.trim().isNotEmpty && id!.contains('-')) {
      data['id'] = id;
    }

    return data;
  }
}
