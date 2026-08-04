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

    /// Lee `resumen_actividad_plan` filtrado por plan.
  Future<List<Map<String, dynamic>>> fetchResumenPorPlan(String planId);

  /// Lee `resumen_actividad_plan` filtrado por paciente (todas sus actividades,
  /// de todos sus planes).
  Future<List<Map<String, dynamic>>> fetchResumenPorPaciente(String pacienteId);

  /// `registrar_consentimiento_plan`: guarda la evidencia y aplica la decisión
  /// al plan en la misma transacción. Los precios aceptados los congela el
  /// servidor desde el plan vigente, no el cliente.
  Future<Map<String, dynamic>> registrarConsentimiento({
    required String planId,
    required String decision,
    required String persona,
    required String metodo,
    String relacion,
    String? motivo,
  });
}
