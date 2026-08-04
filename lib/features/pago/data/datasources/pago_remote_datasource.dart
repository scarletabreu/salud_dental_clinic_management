/// Acceso a `pagos`.
///
/// Desde el audit del 2 ago 2026 **no hay escritura directa a la tabla**: la
/// migración `audit_002` revocó INSERT y UPDATE a `authenticated` y retiró sus
/// políticas. Un insert directo creaba el pago sin tocar el saldo ni el estado
/// de la cuenta —la sonda S1 lo consiguió con un token real de admin—, y una
/// anulación directa dejaba vivo su ingreso en caja. Toda escritura pasa por las
/// RPC transaccionales.
abstract class PagoRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchPagosPorCuenta(String cuentaId);

  /// Cobro atómico contra una cuenta vía RPC `registrar_pago`: valida el monto
  /// contra el saldo server-side, inserta el pago y cierra la cuenta si quedó
  /// saldada, todo en una sola transacción. Devuelve el id del pago creado.
  Future<String> registrarPagoTransaccional({
    required String cuentaId,
    required double monto,
    required String metodoPago,
    String? cuotaId,
  });

  /// Anula un cobro vía RPC `anular_pago`: revoca el pago, revierte su ingreso
  /// en caja —o deja el egreso compensatorio si esa caja ya cerró— y devuelve
  /// la cuenta a su estado real.
  Future<void> anularPago(String id, {String? motivo});
}
