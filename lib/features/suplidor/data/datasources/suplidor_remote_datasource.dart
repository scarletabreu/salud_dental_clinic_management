abstract class SuplidorRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchSuplidores();
  Future<void> upsertSuplidor(Map<String, dynamic> data);
  Future<void> softDeleteSuplidor(String id);
}
