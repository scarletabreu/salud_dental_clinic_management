abstract class CuentaRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchTodasLasCuentas();
  Future<List<Map<String, dynamic>>> fetchCuentasByPaciente(String pacienteId);
  Future<Map<String, dynamic>?> fetchCuentaById(String id);
  Future<void> registrarCuenta(Map<String, dynamic> data);
  Future<void> registrarPago(String cuentaId, Map<String, dynamic> pagoData);
  Future<void> deleteCuenta(String id);
}
