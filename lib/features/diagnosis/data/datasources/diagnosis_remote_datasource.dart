abstract class DiagnosisRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchCatalogoDiagnosis();
  Future<List<Map<String, dynamic>>> fetchDiagnosisByCategoria(
    String categoria,
  );
  Future<void> deleteDiagnosis(String id);
}
