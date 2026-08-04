import 'package:salud_dental_clinic_management/features/pago/domain/entities/pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/enums/metodo_pago.dart';

/// Los cobros sólo se crean y se deshacen por RPC transaccional: escribir
/// `pagos` a mano dejaba la cuenta y la caja diciendo cosas distintas del mismo
/// dinero, y desde `audit_002` la base ya no lo permite.
abstract class PagoRepository {
  /// Anula un cobro: lo revoca, revierte su ingreso en caja y recalcula la
  /// cuenta. [motivo] queda en la nota de la cuenta.
  Future<void> cancelarPago(String id, {String? motivo});
  Future<List<Pago>> getHistorialPagosCuenta(String cuentaId);

  /// Registra un cobro sobre una cuenta de forma atómica (inserta el pago y
  /// cierra la cuenta si quedó saldada). Devuelve el id del pago creado.
  Future<String> registrarPago({
    required String cuentaId,
    required double monto,
    required MetodoPago metodo,
    String? cuotaId,
  });
}
