abstract class AuditoriaRemoteDatasource {
  /// Eventos de la consulta y de su cita, en orden cronológico.
  Future<List<Map<String, dynamic>>> fetchLineaTiempo(String consultaId);
}
