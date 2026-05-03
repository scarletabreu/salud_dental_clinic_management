import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/item_cuenta/data/models/item_cuenta_model.dart';
import 'package:salud_dental_clinic_management/features/pago/data/models/pago_model.dart';

class CuentaModel extends Cuenta {
  CuentaModel({
    super.id,
    required super.consultaId,
    required super.fechaCreacion,
    super.fechaPago,
    required super.metodoPago,
    super.pagos,
    super.nota,
    super.itemCuentas,
  });

  factory CuentaModel.fromJson(Map<String, dynamic> json) {
    return CuentaModel(
      id: json['id'] as String?,
      consultaId: json['consulta_id'] as String,
      fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
      fechaPago: json['fecha_pago'] != null
          ? DateTime.parse(json['fecha_pago'])
          : null,
      metodoPago: MetodoPago.values.firstWhere(
        (e) => e.name == json['metodo_pago'],
        orElse: () => MetodoPago.contado,
      ),
      pagos: [],
      itemCuentas: [],
      nota: json['nota'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'consulta_id': consultaId,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_pago': fechaPago?.toIso8601String(),
      'metodo_pago': metodoPago.name,
      'nota': nota,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
