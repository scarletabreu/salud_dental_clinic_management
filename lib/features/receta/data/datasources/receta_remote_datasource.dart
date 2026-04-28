abstract class RecetaRemoteDatasource {
  Future<void> crearReceta(Map<String, dynamic> data);
  Future<void> actualizarReceta(Map<String, dynamic> data);
  Future<void> anularReceta(String id);
  Future<List<Map<String, dynamic>>> fetchRecetasByPaciente(String pacienteId);
}
