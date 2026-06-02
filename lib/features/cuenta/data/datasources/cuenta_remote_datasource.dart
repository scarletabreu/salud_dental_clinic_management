abstract class CuentaRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchCuentasByPaciente(String pacienteId);
  Future<void> registrarCuenta(Map<String, dynamic> data);
  Future<void> registrarPago(String cuentaId, Map<String, dynamic> pagoData);
  Future<void> deleteCuenta(String id);
}
