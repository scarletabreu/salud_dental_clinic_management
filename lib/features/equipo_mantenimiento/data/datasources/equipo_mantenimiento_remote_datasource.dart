abstract class EquipoMantenimientoRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchMantenimientosByEquipo(
    String equipoId,
  );
  Future<void> insertMantenimiento(Map<String, dynamic> data);
  Future<void> softDeleteMantenimiento(String id);
  Future<void> updateMantenimiento(String id, Map<String, dynamic> data);
}
