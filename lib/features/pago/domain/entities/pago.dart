import 'package:salud_dental_clinic_management/features/pago/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/enums/estado_pago.dart';

class Pago {
  final String? id;
  final String cuentaId;
  final String? cuotaId;
  final double monto;
  final DateTime fecha;
  final EstadoPago estado;
  final MetodoPago metodoPago;

  Pago({
    this.id,
    required this.cuentaId,
    this.cuotaId,
    required this.monto,
    required this.fecha,
    required this.estado,
    required this.metodoPago,
  });

  bool get fueExitoso => estado == EstadoPago.completado;

  Pago copyWith({
    String? cuentaId,
    String? cuotaId,
    double? monto,
    DateTime? fecha,
    EstadoPago? estado,
    MetodoPago? metodoPago,
  }) {
    return Pago(
      id: id,
      cuentaId: cuentaId ?? this.cuentaId,
      cuotaId: cuotaId ?? this.cuotaId,
      monto: monto ?? this.monto,
      fecha: fecha ?? this.fecha,
      estado: estado ?? this.estado,
      metodoPago: metodoPago ?? this.metodoPago,
    );
  }
}
