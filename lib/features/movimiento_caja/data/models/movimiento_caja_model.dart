import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/entities/movimiento_caja.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/enums/tipo_movimiento.dart';

class MovimientoCajaModel extends MovimientoCaja {
  MovimientoCajaModel({
    super.id,
    required super.cajaDiariaId,
    required super.tipo,
    required super.monto,
    required super.descripcion,
    required super.fecha,
    required super.referenciaId,
  });

  factory MovimientoCajaModel.fromJson(Map<String, dynamic> json) {
    return MovimientoCajaModel(
      id: json['id'] as String?,
      cajaDiariaId: json['caja_diaria_id'] ?? json['cajaDiariaId'],
      tipo: TipoMovimiento.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => TipoMovimiento.ingreso,
      ),
      monto: (json['monto'] as num).toDouble(),
      descripcion: json['descripcion'] as String,
      fecha: DateTime.parse(json['fecha'] as String).toLocal(),
      referenciaId: json['referencia_id'] ?? json['referenciaId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'caja_diaria_id': cajaDiariaId,
      'tipo': tipo.name,
      'monto': monto,
      'descripcion': descripcion,
      'fecha': fecha.toUtc().toIso8601String(),
      'referencia_id': referenciaId,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }

  factory MovimientoCajaModel.fromEntity(MovimientoCaja entidad) {
    return MovimientoCajaModel(
      id: entidad.id,
      cajaDiariaId: entidad.cajaDiariaId,
      tipo: entidad.tipo,
      monto: entidad.monto,
      descripcion: entidad.descripcion,
      fecha: entidad.fecha,
      referenciaId: entidad.referenciaId,
    );
  }
}
