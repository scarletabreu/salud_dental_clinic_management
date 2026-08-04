abstract class CuotaRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchCuotasByCuenta(String cuentaId);
  Future<void> marcarCuotasVencidas(String cuentaId);
  Future<void> crearCuotas(List<Map<String, dynamic>> cuotasData);
}
