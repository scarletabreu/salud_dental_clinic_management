abstract class ItemCuentaDatasource {
  Future<List<Map<String, dynamic>>> fetchItemsByCuenta(String cuentaId);
  Future<void> insertItem(Map<String, dynamic> data);
  Future<void> softDeleteItem(String id);
}
