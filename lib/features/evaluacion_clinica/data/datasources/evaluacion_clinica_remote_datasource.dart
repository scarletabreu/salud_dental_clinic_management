abstract class EvaluacionClinicaRemoteDatasource {
  /// Crea la evaluación de una consulta, o devuelve la existente. Es idempotente
  /// porque la consulta puede guardarse varias veces (autoguardado).
  Future<String> asegurarEvaluacionDeConsulta(Map<String, dynamic> data);

  Future<Map<String, dynamic>?> fetchPorConsulta(String consultaId);

  Future<List<Map<String, dynamic>>> fetchPorPaciente(String pacienteId);

  /// Cuelga los hallazgos sueltos de una consulta de su evaluación.
  Future<void> vincularHallazgos({
    required String evaluacionId,
    required String consultaId,
  });
}
