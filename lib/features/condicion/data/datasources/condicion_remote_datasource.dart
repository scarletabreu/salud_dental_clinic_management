abstract class CondicionRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchCondiciones();
  Future<List<Map<String, dynamic>>> fetchCondicionesByTipo(String tipo);
  Future<Map<String, dynamic>> createCondicion(
    Map<String, dynamic> condicionData,
  );
  Future<void> deleteCondicion(String id);
}
