abstract class SuplidorRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchSuplidores();
  Future<void> upsertSuplidor(Map<String, dynamic> data);
  Future<void> softDeleteSuplidor(String id);
  Future<void> createSuplidor(Map<String, dynamic> data);
  Future<void> updateSuplidor(String id, Map<String, dynamic> data);
}
