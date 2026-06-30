abstract class CondicionRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchCondiciones();
  Future<List<Map<String, dynamic>>> fetchCondicionesByTipo(String tipo);
  /// Inserta la condición y devuelve la fila creada (incluye el `id` generado).
  Future<Map<String, dynamic>> createCondicion(
    Map<String, dynamic> condicionData,
  );
  Future<void> deleteCondicion(String id);
}
