abstract class ConsultaRemoteDatasource {
  Future<String> crearConsultaCompleta(Map<String, dynamic> params);

  /// Guarda el borrador clínico completo en una sola transacción
  /// (`guardar_borrador_consulta`).
  ///
  /// [payload] es el contrato versionado del ticket HFX-CLIN-002: una clave
  /// ausente no se toca, y una presente describe el conjunto completo deseado.
  /// Lo que desaparece de una colección se anula con `deleted_at`, nunca se
  /// borra: un expediente clínico no reescribe su historia.
  ///
  /// [version] es la versión que el cliente cree tener. Si el servidor tiene
  /// otra, no escribe nada y responde `CL001`.
  ///
  /// Devuelve, por FDI, los ids confirmados en el mismo orden en que llegaron,
  /// más la nueva versión de la consulta.
  Future<Map<String, dynamic>> guardarBorradorConsulta({
    required String consultaId,
    int? version,
    required Map<String, dynamic> payload,
  });

  /// Cierra la consulta en una única operación (`cerrar_consulta`): guarda el
  /// borrador final, descuenta inventario, emite recetas, crea la pre-factura
  /// y completa la cita. O se confirma todo, o no cambia nada.
  ///
  /// [idempotenciaKey] identifica el intento lógico: repetirlo devuelve el
  /// resultado existente en vez de descontar stock o facturar otra vez.
  Future<Map<String, dynamic>> cerrarConsulta({
    required String consultaId,
    int? version,
    Map<String, dynamic> payload,
    required String idempotenciaKey,
    String metodoPago,
    String? nota,
  });

  /// Registra la decisión clínica sobre una alerta (`resolver_alerta_clinica`).
  /// [estado] es `confirmada` o `documentada`; la segunda exige justificación.
  Future<void> resolverAlertaClinica({
    required String alertaId,
    required String estado,
    String? justificacion,
  });

  Future<List<Map<String, dynamic>>> fetchConsultas();
  Future<List<Map<String, dynamic>>> fetchConsultasByDoctor(String doctorId);
  Future<List<Map<String, dynamic>>> fetchConsultasByPaciente(
    String pacienteId,
  );
  Future<Map<String, dynamic>?> fetchConsultaById(String id);

  /// Filas `id, cita_id, finalizada` de las consultas de esas citas. Sirve
  /// tanto para enlazar la agenda con su consulta como para saber si queda
  /// alguna abierta (SD-160). Una lista vacía no consulta la red.
  Future<List<Map<String, dynamic>>> fetchConsultasPorCitaIds(
    List<String> citaIds,
  );

  Future<List<Map<String, dynamic>>> fetchTratamientosAplicadosPorIds(
    List<String> ids,
  );

  /// [incluyendoAnulados] trae también las ejecuciones con `deleted_at`. La
  /// capa que se dibuja sobre el diente no las quiere —no describen la boca—,
  /// pero la línea de tiempo de la pieza sí: anular es un hecho clínico.
  Future<List<Map<String, dynamic>>> fetchTratamientosHistoricosPaciente(
    String pacienteId, {
    String? excluyendoConsultaId,
    bool incluyendoAnulados = false,
  });

  /// Diagnósticos de las consultas anteriores del paciente, de la más reciente
  /// a la más antigua y con la clave del catálogo que los dibuja en el papel.
  Future<List<Map<String, dynamic>>> fetchDiagnosticosHistoricosPaciente(
    String pacienteId, {
    String? excluyendoConsultaId,
    bool incluyendoAnulados = false,
  });

  /// Actividades del plan que caen sobre alguna pieza del paciente, anuladas
  /// incluidas. Traen el código FDI de su diente y la consulta que originó el
  /// plan, que es lo que las sitúa en la línea de tiempo.
  Future<List<Map<String, dynamic>>> fetchItemsPlanPorPaciente(
    String pacienteId,
  );

  /// Índice de las consultas del paciente para encabezar su historial: fecha,
  /// motivo, tipo de atención y doctor. No filtra las anuladas a propósito, de
  /// modo que ningún evento se quede sin la visita a la que pertenece.
  Future<List<Map<String, dynamic>>> fetchReferenciasConsultasPaciente(
    String pacienteId,
  );

  /// Nombre de los doctores [ids], para que el historial diga quién anotó cada
  /// cosa en lugar de mostrar un uuid.
  Future<List<Map<String, dynamic>>> fetchNombresDoctores(List<String> ids);

  /// Odontodiagramas de las consultas anteriores del paciente, de la más
  /// reciente a la más antigua. Tras SD-150 el jsonb solo conserva los tejidos
  /// blandos: las piezas viven en `diagnosticos_aplicados`.
  Future<List<Map<String, dynamic>>> fetchEvaluacionesPaciente(
    String pacienteId, {
    String? excluyendoConsultaId,
  });

  Future<void> updateConsulta(String id, Map<String, dynamic> consultaData);
  Future<void> deleteConsulta(String id);
}
