import 'package:salud_dental_clinic_management/features/cuota/domain/enums/estado_cuota.dart';

class Cuota {
  final String? id;
  final String cuentaId;
  final double monto;
  final double montoPagado;
  final DateTime fechaVencimiento;
  final EstadoCuota estado;

  Cuota({
    this.id,
    required this.cuentaId,
    required this.monto,
    this.montoPagado = 0,
    required this.fechaVencimiento,
    required this.estado,
  });

  double get saldoPendiente {
    final saldo = monto - montoPagado;
    return saldo < 0.01 ? 0 : saldo;
  }

  double get progreso => monto <= 0 ? 0 : (montoPagado / monto).clamp(0, 1);

  bool get estaVencida {
    if (estado != EstadoCuota.pendiente) return false;
    final hoy = DateTime.now();
    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
    return hoySinHora.isAfter(fechaVencimiento);
  }

  Cuota copyWith({
    String? cuentaId,
    double? monto,
    double? montoPagado,
    DateTime? fechaVencimiento,
    EstadoCuota? estado,
  }) {
    return Cuota(
      id: id,
      cuentaId: cuentaId ?? this.cuentaId,
      monto: monto ?? this.monto,
      montoPagado: montoPagado ?? this.montoPagado,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      estado: estado ?? this.estado,
    );
  }
}
