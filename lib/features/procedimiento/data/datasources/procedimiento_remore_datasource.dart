abstract class ProcedimientoRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchProcedimientos();
  Future<void> upsertProcedimiento(Map<String, dynamic> data);
  Future<void> softDeleteProcedimiento(String id);
}
