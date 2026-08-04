abstract class ConsumibleRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchConsumibles();
  Future<void> deleteConsumible(String id);
  Future<void> createConsumible(Map<String, dynamic> data);
  /// [data] sólo puede traer columnas con grant de UPDATE: `stock_actual` y
  /// `estado` no lo tienen y su presencia rechaza la petición entera (`42501`).
  Future<void> updateConsumible(String id, Map<String, dynamic> data);

  /// Mueve el stock a [nuevoStock] dejando el asiento correspondiente.
  ///
  /// No existe una vía que escriba `stock_actual` directamente: desde
  /// HFX-CLIN-007 esa columna no es escribible por el cliente y el stock sólo
  /// se mueve a través del libro de movimientos.
  Future<void> adjustStock(String id, int nuevoStock, String motivo);
}
