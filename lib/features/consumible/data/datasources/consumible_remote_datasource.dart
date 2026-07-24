abstract class ConsumibleRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchConsumibles();
  Future<void> adjustStock(String id, int nuevoStock, String motivo);
  Future<void> deleteConsumible(String id);
  Future<void> createConsumible(Map<String, dynamic> data);
  Future<void> updateConsumible(String id, Map<String, dynamic> data);
}
