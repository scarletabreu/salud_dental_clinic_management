abstract class ContraindicacionRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchContraindicacionesByCondicion(
    String condicionId,
  );
  Future<List<Map<String, dynamic>>> fetchContraindicacionesByProcedimiento(
    String procedimientoId,
  );
  Future<List<Map<String, dynamic>>> fetchContraindicacionesByTratamiento(
    String tratamientoId,
  );
  Future<List<Map<String, dynamic>>> fetchContraindicacionesByMedicina(
    String medicinaId,
  );
  Future<void> registrarContraindicacion(Map<String, dynamic> data);
  Future<void> deleteContraindicacion(String id);
}
