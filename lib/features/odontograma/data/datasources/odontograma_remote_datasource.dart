abstract class OdontogramaRemoteDatasource {
  Future<Map<String, dynamic>?> fetchOdontogramaByConsulta(String consultaId);
  Future<void> crearOdontograma(Map<String, dynamic> data);
  Future<void> actualizarOdontograma(Map<String, dynamic> data);
  Future<void> eliminarOdontograma(String id);
}
