abstract class MedicinaRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchMedicinas();
  Future<void> insertMedicina(Map<String, dynamic> data);
  Future<void> upsertMedicina(Map<String, dynamic> data);
  Future<void> softDeleteMedicina(String id);
}
