abstract class ConsumibleCompraRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchItemsByCompra(String compraId);
  Future<Map<String, dynamic>?> fetchConsumibleById(String id);
  Future<void> updateConsumible(Map<String, dynamic> consumibleData);
  Future<void> deleteConsumible(String id);
}
