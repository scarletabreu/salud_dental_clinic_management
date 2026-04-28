abstract class MovimientoCajaRemoteDatasource {
  Future<void> registrarMovimiento(Map<String, dynamic> data);
  Future<void> actualizarMovimiento(Map<String, dynamic> data);
  Future<void> eliminarMovimiento(String id);
  Future<List<Map<String, dynamic>>> fetchMovimientosPorCaja(
    String cajaDiariaId,
  );
}
