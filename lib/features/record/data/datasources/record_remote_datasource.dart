abstract class RecordRemoteDatasource {
  Future<Map<String, dynamic>?> fetchRecordByPaciente(String pacienteId);
  Future<void> upsertRecord(Map<String, dynamic> data);
  Future<void> anularRecord(String id);
  Future<void> createRecord(Map<String, dynamic> data);

  // ── Condiciones del paciente (puente record_condicion) ────────────────────

  /// Id del expediente del paciente, o `null` si todavía no tiene uno.
  Future<String?> fetchRecordId(String pacienteId);

  /// Id del expediente del paciente; si no existe, crea un expediente mínimo
  /// (tipo_sangre = 'desconocido') para poder colgarle condiciones.
  Future<String> getOrCreateRecordId(String pacienteId);

  /// Filas de `record_condicion` del expediente, con la condición del catálogo
  /// embebida en la clave `condiciones`.
  Future<List<Map<String, dynamic>>> fetchAflicciones(String recordId);

  Future<void> addAfliccion(String recordId, String condicionId);

  Future<void> removeAfliccion(String recordId, String condicionId);
}
