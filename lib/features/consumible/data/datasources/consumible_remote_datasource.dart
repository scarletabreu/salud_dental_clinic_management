abstract class ConsumibleRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchConsumibles();
  Future<void> updateStock(String id, int nuevoStock);
  Future<void> upsertConsumible(Map<String, dynamic> data);
  Future<void> deleteConsumible(String id);
}
