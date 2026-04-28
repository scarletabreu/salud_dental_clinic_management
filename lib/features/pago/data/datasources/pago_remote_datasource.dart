abstract class PagoRemoteDatasource {
  Future<void> registrarPago(Map<String, dynamic> data);
  Future<void> actualizarPago(Map<String, dynamic> data);
  Future<void> anularPago(String id);
  Future<List<Map<String, dynamic>>> fetchPagosPorCuenta(String cuentaId);
}
