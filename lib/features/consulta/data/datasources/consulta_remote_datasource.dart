import 'package:salud_dental_clinic_management/features/consulta/domain/entities/resultado_guardado_odontograma.dart';

abstract class ConsultaRemoteDatasource {
  Future<String> crearConsultaCompleta(Map<String, dynamic> params);

  /// Cierra la consulta y genera su pre-factura (cuenta + ítems) de forma
  /// atómica vía RPC. Devuelve el id de la cuenta creada.
  Future<String> finalizarConsulta({
    required String consultaId,
    String metodoPago,
    String? nota,
  });

  /// Persiste el trabajo clínico de la consulta.
  ///
  /// [dientesPorFdi] lleva, por código FDI, el estado completo de la pieza:
  /// `esta_ausente`, `observaciones` y la lista `tratamientos`. Cada
  /// tratamiento con `id` corresponde a una fila ya persistida y se actualiza
  /// en su sitio; los que no lo llevan se insertan. Lo que desaparece de la
  /// lista se anula con `deleted_at`, nunca se borra: un expediente clínico no
  /// reescribe su historia.
  ///
  /// Devuelve, por FDI, los ids de los tratamientos en el mismo orden en que
  /// llegaron, para que quien llama pueda sellarlos sobre su estado en memoria
  /// y el siguiente guardado los reconozca en vez de duplicarlos.
  Future<ResultadoGuardadoOdontograma> guardarResultadoConsulta({
    required String consultaId,
    required String? pacienteId,
    required Map<int, Map<String, dynamic>> dientesPorFdi,
    required List<Map<String, dynamic>> recetas,
    required Map<String, dynamic> evaluacionOdontologica,
    String? notas,
    Map<String, dynamic>? signosVitales,
    bool? finalizada,
  });

  Future<List<Map<String, dynamic>>> fetchConsultas();
  Future<List<Map<String, dynamic>>> fetchConsultasByDoctor(String doctorId);
  Future<List<Map<String, dynamic>>> fetchConsultasByPaciente(
    String pacienteId,
  );
  Future<Map<String, dynamic>?> fetchConsultaById(String id);

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
