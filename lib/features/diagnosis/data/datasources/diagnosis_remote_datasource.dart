abstract class DiagnosisRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchCatalogoDiagnosis();
  Future<List<Map<String, dynamic>>> fetchDiagnosisByCategoria(
    String categoria,
  );
  Future<void> deleteDiagnosis(String id);
  Future<void> createDiagnosis(Map<String, dynamic> data);
  Future<void> updateDiagnosis(String id, Map<String, dynamic> data);
}
