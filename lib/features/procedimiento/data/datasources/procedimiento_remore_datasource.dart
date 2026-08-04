abstract class ProcedimientoRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchProcedimientos();
  Future<Map<String, dynamic>> insertProcedimiento(Map<String, dynamic> data);
  Future<void> upsertProcedimiento(Map<String, dynamic> data);
  Future<void> softDeleteProcedimiento(String id);
}
