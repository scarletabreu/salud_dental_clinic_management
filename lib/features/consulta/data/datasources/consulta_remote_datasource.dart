abstract class ConsultaRemoteDatasource {
  Future<String> crearConsultaCompleta(Map<String, dynamic> params);

  Future<void> guardarResultadoConsulta({
    required String consultaId,
    required Map<int, List<Map<String, dynamic>>> tratamientosPorFdi,
    String? notas,
  });

  Future<List<Map<String, dynamic>>> fetchConsultas();
  Future<List<Map<String, dynamic>>> fetchConsultasByDoctor(String doctorId);
  Future<List<Map<String, dynamic>>> fetchConsultasByPaciente(
    String pacienteId,
  );
  Future<Map<String, dynamic>?> fetchConsultaById(String id);

  /// Tratamientos aplicados por ids, con el nombre del tratamiento del
  /// catálogo embebido (clave `tratamiento`).
  Future<List<Map<String, dynamic>>> fetchTratamientosAplicadosPorIds(
    List<String> ids,
  );

  /// Tratamientos aplicados en consultas ANTERIORES del paciente, con el
  /// `fdi_code` del diente embebido (clave `diente`). Excluye, si se indica, la
  /// consulta en curso. Usado para proyectar el historial sobre un odontograma
  /// recién creado.
  Future<List<Map<String, dynamic>>> fetchTratamientosHistoricosPaciente(
    String pacienteId, {
    String? excluyendoConsultaId,
  });

  Future<void> updateConsulta(String id, Map<String, dynamic> consultaData);
  Future<void> deleteConsulta(String id);
}
