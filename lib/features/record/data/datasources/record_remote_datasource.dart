abstract class RecordRemoteDatasource {
  Future<Map<String, dynamic>?> fetchRecordByPaciente(String pacienteId);
  Future<void> upsertRecord(Map<String, dynamic> data);
  Future<void> anularRecord(String id);
  Future<void> createRecord(Map<String, dynamic> data);
}
