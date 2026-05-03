abstract class EquipoRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchEquipos();
  Future<void> upsertEquipo(Map<String, dynamic> data);
  Future<void> softDeleteEquipo(String id);
  Future<void> createEquipo(Map<String, dynamic> data);
}
