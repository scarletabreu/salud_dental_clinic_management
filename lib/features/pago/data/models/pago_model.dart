import 'package:salud_dental_clinic_management/features/pago/domain/entities/pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/enums/estado_pago.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart';

class PagoModel extends Pago {
  PagoModel({
    required super.id,
    required super.cuentaId,
    required super.monto,
    required super.fecha,
    required super.estado,
    required super.metodoPago,
  });

  factory PagoModel.fromJson(Map<String, dynamic> json) {
    return PagoModel(
      id: json['id'] as String,
      cuentaId: json['cuenta_id'] ?? json['cuentaId'] as String,
      monto: (json['monto'] as num).toDouble(),
      fecha: DateTime.parse(json['fecha'] as String).toLocal(),
      estado: EstadoPago.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EstadoPago.pendiente,
      ),
      metodoPago: MetodoPago.values.firstWhere(
        (e) => e.name == json['metodo_pago'] || e.name == json['metodoPago'],
        orElse: () => MetodoPago.contado,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cuenta_id': cuentaId,
      'monto': monto,
      'fecha': fecha.toUtc().toIso8601String(),
      'estado': estado.name,
      'metodo_pago': metodoPago.name,
    };
  }

  factory PagoModel.fromEntity(Pago pago) {
    return PagoModel(
      id: pago.id,
      cuentaId: pago.cuentaId,
      monto: pago.monto,
      fecha: pago.fecha,
      estado: pago.estado,
      metodoPago: pago.metodoPago,
    );
  }
}
