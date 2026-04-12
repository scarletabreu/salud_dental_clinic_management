import 'package:salud_dental_clinic_management/features/cuota/domain/enums/estado_cuota.dart';

class Cuota {
  final String id;
  final String cuentaId;
  final double monto;
  final DateTime fechaVencimiento;
  final EstadoCuota estado;

  Cuota({
    required this.id,
    required this.cuentaId,
    required this.monto,
    required this.fechaVencimiento,
    required this.estado,
  });

  bool get estaVencida {
    if (estado != EstadoCuota.pendiente) return false;
    final hoy = DateTime.now();
    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
    return hoySinHora.isAfter(fechaVencimiento);
  }

  Cuota copyWith({
    String? cuentaId,
    double? monto,
    DateTime? fechaVencimiento,
    EstadoCuota? estado,
  }) {
    return Cuota(
      id: id,
      cuentaId: cuentaId ?? this.cuentaId,
      monto: monto ?? this.monto,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      estado: estado ?? this.estado,
    );
  }
}
