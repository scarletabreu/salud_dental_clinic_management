abstract class CajaDiariaDatasource {
  Future<void> abrirCaja(double montoInicial);
  Future<void> registrarMovimiento(Map<String, dynamic> movimientoData);
  Future<List<Map<String, dynamic>>> fetchMovimientosDelDia();
  Future<void> cerrarCaja(Map<String, dynamic> datosCierre);
  Future<bool> isCajaAbierta();
  Future<double> getBalanceActual();
  Future<Map<String, dynamic>?> fetchCajaAbierta();
}
