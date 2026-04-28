abstract class CompraRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchCompras();
  Future<Map<String, dynamic>?> fetchCompraById(String id);
  Future<void> createCompra(Map<String, dynamic> compraData);
  Future<void> updateCompraEstado(String id, String nuevoEstado);
  Future<void> deleteCompra(String id);
}
