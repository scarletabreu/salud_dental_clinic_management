abstract class OrdenMedicaRemoteDatasource {
  Future<void> insertarOrden(Map<String, dynamic> data);
  Future<void> actualizarOrden(Map<String, dynamic> data);
  Future<void> eliminarOrden(String id);
  Future<List<Map<String, dynamic>>> fetchOrdenesPorPaciente(String pacienteId);
}
