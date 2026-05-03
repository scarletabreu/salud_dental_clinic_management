import 'package:salud_dental_clinic_management/features/cuota/domain/entities/cuota.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/enums/estado_cuota.dart';

class CuotaModel extends Cuota {
  CuotaModel({
    super.id,
    required super.cuentaId,
    required super.monto,
    required super.fechaVencimiento,
    required super.estado,
  });

  factory CuotaModel.fromJson(Map<String, dynamic> json) {
    return CuotaModel(
      id: json['id'] as String?,
      cuentaId: json['cuenta_id'] as String,
      monto: (json['monto'] as num).toDouble(),
      fechaVencimiento: DateTime.parse(json['fecha_vencimiento'] as String),
      estado: EstadoCuota.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EstadoCuota.pendiente,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'cuenta_id': cuentaId,
      'monto': monto,
      'fecha_vencimiento': fechaVencimiento.toIso8601String(),
      'estado': estado.name,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
