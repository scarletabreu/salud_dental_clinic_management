abstract class PlanTratamientoRemoteDatasource {
  /// Inserta el encabezado y devuelve su id.
  Future<String> insertPlan(Map<String, dynamic> data);

  Future<void> updatePlan(String id, Map<String, dynamic> data);

  /// Inserta las actividades del plan y devuelve las filas creadas.
  Future<List<Map<String, dynamic>>> insertItems(
    List<Map<String, dynamic>> items,
  );

  Future<Map<String, dynamic>> updateItem(String id, Map<String, dynamic> data);

  Future<void> deleteItem(String id);

  Future<List<Map<String, dynamic>>> fetchPlanesPorPaciente(String pacienteId);

  Future<Map<String, dynamic>?> fetchPlanPorConsulta(String consultaId);

  Future<List<Map<String, dynamic>>> fetchItemsEjecutables(String pacienteId);
}
