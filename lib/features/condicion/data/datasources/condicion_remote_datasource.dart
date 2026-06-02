abstract class CondicionRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchCondiciones();
  Future<List<Map<String, dynamic>>> fetchCondicionesByTipo(String tipo);
  Future<void> createCondicion(Map<String, dynamic> condicionData);
  Future<void> deleteCondicion(String id);
}
