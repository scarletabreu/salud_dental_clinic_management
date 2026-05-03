abstract class ItemCuentaDatasource {
  Future<List<Map<String, dynamic>>> fetchItemsByCuenta(String cuentaId);
  Future<void> insertItem(Map<String, dynamic> data);
  Future<void> softDeleteItem(String id);
  Future<void> updateItem(String id, Map<String, dynamic> data);
}
