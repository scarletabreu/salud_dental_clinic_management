import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/item_cuenta/data/models/item_cuenta_model.dart';
import 'package:salud_dental_clinic_management/features/pago/data/models/pago_model.dart';

class CuentaModel extends Cuenta {
  CuentaModel({
    required super.id,
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
      id: json['id'],
      consultaId: json['consulta_id'] ?? json['consultaId'],
      fechaCreacion: DateTime.parse(
        json['fecha_creacion'] ?? json['fechaCreacion'],
      ),
      fechaPago: json['fecha_pago'] != null || json['fechaPago'] != null
          ? DateTime.parse(json['fecha_pago'] ?? json['fechaPago'])
          : null,
      metodoPago: MetodoPago.values.firstWhere(
        (e) => e.name == json['metodo_pago'] || e.name == json['metodoPago'],
        orElse: () => MetodoPago.contado,
      ),
      pagos: json['pagos'] != null
          ? (json['pagos'] as List).map((p) => PagoModel.fromJson(p)).toList()
          : [],
      nota: json['nota'],
      itemCuentas: json['item_cuentas'] != null || json['itemCuentas'] != null
          ? (json['item_cuentas'] ?? json['itemCuentas'] as List)
                .map((i) => ItemCuentaModel.fromJson(i))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'consulta_id': consultaId,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_pago': fechaPago?.toIso8601String(),
      'metodo_pago': metodoPago.name,
      'pagos': pagos.map((p) => (p as PagoModel).toJson()).toList(),
      'nota': nota,
      'item_cuentas': itemCuentas
          .map((i) => (i as ItemCuentaModel).toJson())
          .toList(),
    };
  }
}
