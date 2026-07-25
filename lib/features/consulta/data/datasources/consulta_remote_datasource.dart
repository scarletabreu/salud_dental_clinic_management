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

  Future<List<Map<String, dynamic>>> fetchTratamientosHistoricosPaciente(
    String pacienteId, {
    String? excluyendoConsultaId,
  });

  /// Odontodiagramas de las consultas anteriores del paciente, de la más
  /// reciente a la más antigua.
  Future<List<Map<String, dynamic>>> fetchEvaluacionesPaciente(
    String pacienteId, {
    String? excluyendoConsultaId,
  });

  Future<void> updateConsulta(String id, Map<String, dynamic> consultaData);
  Future<void> deleteConsulta(String id);
}
