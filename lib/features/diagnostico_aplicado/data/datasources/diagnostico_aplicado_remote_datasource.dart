abstract class DiagnosticoAplicadoRemoteDatasource {
  Future<void> insertDiagnostico(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> fetchByConsulta(String consultaId);
  Future<void> deleteDiagnostico(String id);
}
