import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/item_cuenta/domain/entities/item_cuenta.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/entities/pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/enums/estado_pago.dart';

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
    final pagosRaw = json['pagos'] as List<dynamic>? ?? [];
    final itemsRaw = json['items_cuenta'] as List<dynamic>? ?? [];

    final pagos = pagosRaw
        .whereType<Map<String, dynamic>>()
        .map((p) => _parsePago(p))
        .whereType<Pago>()
        .toList();

    final items = itemsRaw
        .whereType<Map<String, dynamic>>()
        .map((i) => _parseItemCuenta(i))
        .whereType<ItemCuenta>()
        .toList();

    return CuentaModel(
      id: json['id'] as String?,
      consultaId: json['consulta_id'] as String? ?? '',
      fechaCreacion:
          _parseDate(json['fecha_creacion']) ??
          _parseDate(json['created_at']) ??
          DateTime.now(),
      fechaPago: _parseDate(json['fecha_pago']),
      metodoPago: MetodoPago.values.firstWhere(
        (e) =>
            e.name.toLowerCase() ==
            (json['metodo_pago'] as String? ?? '').toLowerCase(),
        orElse: () => MetodoPago.contado,
      ),
      pagos: pagos,
      itemCuentas: items,
      nota: json['nota'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
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

  static Pago? _parsePago(Map<String, dynamic> p) {
    try {
      final monto = (p['monto'] as num?)?.toDouble() ?? 0.0;
      return Pago(
        id: p['id'] as String?,
        cuentaId: p['cuenta_id'] as String? ?? '',
        monto: monto,
        fecha:
            _parseDate(p['fecha']) ??
            _parseDate(p['created_at']) ??
            DateTime.now(),
        estado: EstadoPago.values.firstWhere(
          (e) =>
              e.name.toLowerCase() ==
              (p['estado'] as String? ?? '').toLowerCase(),
          orElse: () => EstadoPago.completado,
        ),
        metodoPago: MetodoPago.values.firstWhere(
          (e) =>
              e.name.toLowerCase() ==
              (p['metodo_pago'] as String? ?? '').toLowerCase(),
          orElse: () => MetodoPago.contado,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static ItemCuenta? _parseItemCuenta(Map<String, dynamic> i) {
    try {
      final precioUnitario = (i['precio_unitario'] as num?)?.toDouble() ?? 0.0;
      final cantidad = (i['cantidad'] as num?)?.toInt() ?? 1;
      return ItemCuenta(
        id: i['id'] as String?,
        cuentaId: i['cuenta_id'] as String? ?? '',
        descripcion: i['descripcion'] as String? ?? '',
        precioUnitario: precioUnitario,
        cantidad: cantidad,
      );
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value as String);
    } catch (_) {
      return null;
    }
  }
}
