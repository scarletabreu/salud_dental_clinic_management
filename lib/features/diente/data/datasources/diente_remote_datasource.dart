abstract class DienteRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchDientesByOdontograma(
    String odontogramaId,
  );
  Future<void> updateDiente(String id, Map<String, dynamic> data);
  Future<void> deleteDienteData(String id);
}
