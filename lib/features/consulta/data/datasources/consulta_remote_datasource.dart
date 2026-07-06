abstract class ConsultaRemoteDatasource {
  Future<String> crearConsultaCompleta(Map<String, dynamic> params);

  Future<void> guardarResultadoConsulta({
    required String consultaId,
    required String pacienteId,
    required Map<int, List<Map<String, dynamic>>> tratamientosPorFdi,
    required List<Map<String, dynamic>> recetas,
    String? notas,
  });

  Future<List<Map<String, dynamic>>> fetchConsultas();
  Future<List<Map<String, dynamic>>> fetchConsultasByDoctor(String doctorId);
  Future<List<Map<String, dynamic>>> fetchConsultasByPaciente(
    String pacienteId,
  );
  Future<Map<String, dynamic>?> fetchConsultaById(String id);

  Future<List<Map<String, dynamic>>> fetchTratamientosAplicadosPorIds(
    List<String> ids,
  );

  Future<List<Map<String, dynamic>>> fetchTratamientosHistoricosPaciente(
    String pacienteId, {
    String? excluyendoConsultaId,
  });

  Future<void> updateConsulta(String id, Map<String, dynamic> consultaData);
  Future<void> deleteConsulta(String id);
}
