abstract class ConsumibleRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchConsumibles();
  Future<void> deleteConsumible(String id);
  Future<void> createConsumible(Map<String, dynamic> data);
  Future<void> updateConsumible(String id, Map<String, dynamic> data);
  Future<void> upsertConsumible(Map<String, dynamic> data);
  Future<void> updateStock(String id, int nuevoStock);
  Future<void> adjustStock(String id, int nuevoStock, String motivo);
  Future<void> registrarConsumoClinico(String consumibleId, int cantidad);
}
