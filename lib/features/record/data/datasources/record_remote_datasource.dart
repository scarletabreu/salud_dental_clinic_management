abstract class RecordRemoteDatasource {
  Future<Map<String, dynamic>?> fetchRecordByPaciente(String pacienteId);
  Future<void> createRecord(Map<String, dynamic> data);
  Future<void> upsertRecord(Map<String, dynamic> data);
  Future<void> anularRecord(String id);

  Future<String?> fetchRecordId(String pacienteId);
  Future<String> getOrCreateRecordId(String pacienteId);
  Future<List<Map<String, dynamic>>> fetchAflicciones(String recordId);
  Future<void> addAfliccion(String recordId, String condicionId);
  Future<void> removeAfliccion(String recordId, String condicionId);

  Future<void> actualizarDetalleCondicion(
    Map<String, dynamic> recordCondicionData,
  );
}
