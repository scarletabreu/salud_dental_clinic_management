abstract class CuotaRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchCuotasByCuenta(String cuentaId);
  Future<void> actualizarEstadoCuota(String cuotaId, String nuevoEstado);
  Future<void> crearCuotas(List<Map<String, dynamic>> cuotasData);
  Future<void> deleteCuota(String id);
}
