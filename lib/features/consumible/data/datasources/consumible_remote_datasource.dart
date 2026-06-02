abstract class ConsumibleRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchConsumibles();
  Future<void> updateStock(String id, int nuevoStock);
  Future<void> upsertConsumible(Map<String, dynamic> data);
  Future<void> deleteConsumible(String id);
  Future<void> createConsumible(Map<String, dynamic> data);
  Future<void> updateConsumible(String id, Map<String, dynamic> data);
}
