abstract class ConsultaRemoteDatasource {
  /// Invoca el RPC transaccional `crear_consulta_completa` con [params] y
  /// devuelve el id de la consulta creada.
  Future<String> crearConsultaCompleta(Map<String, dynamic> params);

  /// Persiste el trabajo clínico hecho en el workspace: inserta los
  /// tratamientos aplicados, los vincula a los dientes del odontograma de la
  /// consulta (`dientes.tratamientos_aplicados_ids`) y guarda las notas.
  /// [tratamientosPorFdi] mapea código FDI → filas de `tratamientos_aplicados`.
  Future<void> guardarResultadoConsulta({
    required String consultaId,
    required Map<int, List<Map<String, dynamic>>> tratamientosPorFdi,
    String? notas,
  });

  Future<List<Map<String, dynamic>>> fetchConsultas();
  Future<List<Map<String, dynamic>>> fetchConsultasByPaciente(
    String pacienteId,
  );
  Future<Map<String, dynamic>?> fetchConsultaById(String id);

  /// Tratamientos aplicados por ids, con el nombre del tratamiento del
  /// catálogo embebido (clave `tratamiento`).
  Future<List<Map<String, dynamic>>> fetchTratamientosAplicadosPorIds(
    List<String> ids,
  );

  Future<void> updateConsulta(String id, Map<String, dynamic> consultaData);
  Future<void> deleteConsulta(String id);
}
