abstract class PagoRemoteDatasource {
  Future<void> registrarPago(Map<String, dynamic> data);
  Future<void> actualizarPago(Map<String, dynamic> data);
  Future<void> anularPago(String id);
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
}
