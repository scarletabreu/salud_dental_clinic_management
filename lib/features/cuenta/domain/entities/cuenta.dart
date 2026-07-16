import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/estado_cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/item_cuenta/domain/entities/item_cuenta.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/entities/pago.dart';

class Cuenta {
  final String? id;
  final String consultaId;
  final DateTime fechaCreacion;
  final DateTime? fechaPago;
  final MetodoPago metodoPago;
  final List<Pago> pagos;
  final String? nota;
  final List<ItemCuenta> itemCuentas;

  Cuenta({
    this.id,
    required this.consultaId,
    required this.fechaCreacion,
    this.fechaPago,
    required this.metodoPago,
    this.pagos = const [],
    this.nota,
    this.itemCuentas = const [],
  });

  double get montoTotal =>
      itemCuentas.fold(0.0, (sum, item) => sum + item.precioTotal);

  double get montoPagado => pagos.fold(0.0, (sum, pago) => sum + pago.monto);

  double get balancePendiente => montoTotal - montoPagado;

  bool get estaPagada => balancePendiente <= 0;

  /// Estado derivado de la cuenta a partir de sus pagos. Centraliza la
  /// derivación que hoy repiten `cuenta_card.dart`,
  /// `resumen_financiero_paciente.dart` y `cuentas_por_cobrar_cubit.dart`.
  /// Nunca produce [EstadoCuenta.cancelada]: no hay flag de cancelación en la
  /// entidad todavía.
  EstadoCuenta get estadoCuenta {
    if (estaPagada) return EstadoCuenta.saldada;
    if (montoPagado > 0) return EstadoCuenta.pendiente;
    return EstadoCuenta.abierta;
  }

  Cuenta copyWith({
    String? consultaId,
    DateTime? fechaCreacion,
    DateTime? fechaPago,
    MetodoPago? metodoPago,
    List<Pago>? pagos,
    String? nota,
    List<ItemCuenta>? itemCuentas,
  }) {
    return Cuenta(
      id: id,
      consultaId: consultaId ?? this.consultaId,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaPago: fechaPago ?? this.fechaPago,
      metodoPago: metodoPago ?? this.metodoPago,
      pagos: pagos ?? List.from(this.pagos),
      itemCuentas: itemCuentas ?? List.from(this.itemCuentas),
      nota: nota ?? this.nota,
    );
  }
}
