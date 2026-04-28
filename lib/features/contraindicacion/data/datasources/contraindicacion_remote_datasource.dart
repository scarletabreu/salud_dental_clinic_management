abstract class ContraindicacionRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchContraindicacionesByCondicion(
    String condicionId,
  );
  Future<void> registrarContraindicacion(Map<String, dynamic> data);
  Future<void> deleteContraindicacion(String id);
}
