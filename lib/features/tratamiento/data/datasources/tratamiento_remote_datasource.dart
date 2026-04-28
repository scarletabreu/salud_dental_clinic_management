abstract class TratamientoRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchTratamientos();
  Future<void> upsertTratamiento(Map<String, dynamic> data);
  Future<void> deleteTratamiento(String id);
}
