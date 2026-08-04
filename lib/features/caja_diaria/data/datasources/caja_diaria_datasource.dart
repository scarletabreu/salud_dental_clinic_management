abstract class CajaDiariaDatasource {
  Future<void> abrirCaja(double montoInicial);
  Future<void> registrarMovimiento(Map<String, dynamic> movimientoData);
  Future<List<Map<String, dynamic>>> fetchMovimientosDelDia();
  Future<void> cerrarCaja(Map<String, dynamic> datosCierre);
  Future<bool> isCajaAbierta();
  Future<double> getBalanceActual();
  Future<Map<String, dynamic>?> fetchCajaAbierta();

  /// Cajas de días anteriores que quedaron sin cerrar. Ya no bloquean el
  /// trabajo de hoy, pero siguen siendo un pendiente contable.
  Future<List<Map<String, dynamic>>> fetchCajasSinCerrarDeOtrosDias();
  Stream<List<Map<String, dynamic>>> watchMovimientos(String cajaDiariaId);
}
