abstract class MedicinaRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchMedicinas();
  Future<Map<String, dynamic>> insertMedicina(Map<String, dynamic> data);
  Future<void> upsertMedicina(Map<String, dynamic> data);
  Future<void> softDeleteMedicina(String id);
}
