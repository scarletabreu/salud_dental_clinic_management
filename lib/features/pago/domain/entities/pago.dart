import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/enums/estado_pago.dart';

class Pago {
  final String id;
  final String cuentaId;
  final double monto;
  final DateTime fecha;
  final EstadoPago estado;
  final MetodoPago metodoPago;

  Pago({
    required this.id,
    required this.cuentaId,
    required this.monto,
    required this.fecha,
    required this.estado,
    required this.metodoPago,
  });

  bool get fueExitoso => estado == EstadoPago.recibido;

  Pago copyWith({
    String? cuentaId,
    double? monto,
    DateTime? fecha,
    EstadoPago? estado,
    MetodoPago? metodoPago,
  }) {
    return Pago(
      id: id,
      cuentaId: cuentaId ?? this.cuentaId,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
      estado: estado ?? this.estado,
      metodoPago: metodoPago ?? this.metodoPago,
    );
  }
}
