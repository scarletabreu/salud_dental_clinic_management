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
    super.referenciaId,
  });

  factory MovimientoCajaModel.fromJson(Map<String, dynamic> json) {
    final rawMonto = json['monto'];
    final double montoParsed = rawMonto is num
        ? rawMonto.toDouble()
        : double.tryParse(rawMonto?.toString() ?? '0') ?? 0.0;

    final rawFecha = json['fecha'] ?? json['created_at'];
    final DateTime fechaParsed = rawFecha != null
        ? DateTime.parse(rawFecha.toString()).toLocal()
        : DateTime.now();

    final rawReferencia = json['referencia_id'] ?? json['referenciaId'];

    return MovimientoCajaModel(
      id: json['id'] as String?,
      cajaDiariaId: (json['caja_diaria_id'] ?? json['cajaDiariaId'] ?? '')
          .toString(),
      tipo: TipoMovimiento.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => TipoMovimiento.ingreso,
      ),
      monto: montoParsed,
      descripcion: (json['descripcion'] ?? json['concepto'] ?? '').toString(),
      fecha: fechaParsed,
      referenciaId: rawReferencia?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'caja_diaria_id': cajaDiariaId,
      'tipo': tipo.name,
      'monto': monto,
      'descripcion': descripcion,
      'fecha': fecha.toUtc().toIso8601String(),
    };

    if (referenciaId != null) {
      data['referencia_id'] = referenciaId;
    }

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
