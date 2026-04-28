abstract class SuperficieRemoteDatasource {
  Future<void> actualizarSuperficie(Map<String, dynamic> data);
  Future<void> eliminarSuperficie(String id);
  Future<List<Map<String, dynamic>>> fetchSuperficiesPorDiente(String dienteId);
}
