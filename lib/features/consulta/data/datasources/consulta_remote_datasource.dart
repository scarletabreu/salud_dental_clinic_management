abstract class ConsultaRemoteDatasource {
  Future<void> crearConsulta(Map<String, dynamic> consultaData);
  Future<List<Map<String, dynamic>>> fetchConsultasByPaciente(
    String pacienteId,
  );
  Future<Map<String, dynamic>?> fetchConsultaById(String id);
  Future<void> updateConsulta(String id, Map<String, dynamic> consultaData);
  Future<void> deleteConsulta(String id);
}
