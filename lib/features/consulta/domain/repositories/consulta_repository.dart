import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/tratamiento_aplicado_detalle.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta_de_cita.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/resultado_guardado_odontograma.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/historial_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

abstract class ConsultaRepository {
  Future<List<Consulta>> getConsultas();
  Future<List<Consulta>> getConsultasByDoctor(String doctorId);

  /// Consulta asociada a cada cita, indexada por `citaId`. Ante datos corruptos
  /// con varias consultas para una misma cita, gana la que siga abierta: es la
  /// que condiciona tanto el enlace de la agenda como la cancelación (SD-160).
  Future<Map<String, ConsultaDeCita>> getConsultasPorCitaIds(
    List<String> citaIds,
  );

  Future<String> crearConsultaCompleta(Consulta consulta);

  /// Genera la pre-factura de la consulta (cuenta ABIERTA + ítems) y marca la
  /// cita como completada. Devuelve el id de la cuenta creada.
  Future<String> finalizarConsulta({required String consultaId, String? nota});

  /// Persiste el odontograma, las recetas y las notas de la consulta.
  ///
  /// Devuelve, por código FDI, los ids de los tratamientos aplicados en el
  /// mismo orden en que se enviaron: sellarlos sobre el estado en memoria es
  /// lo que permite que el siguiente guardado actualice esas filas en vez de
  /// crear duplicados.
  Future<ResultadoGuardadoOdontograma> guardarResultadoConsulta({
    required String consultaId,
    required String? pacienteId,
    required Odontograma odontograma,
    required List<Receta> recetas,
    String? notas,
    Map<String, dynamic>? signosVitales,
    bool? finalizada,
  });
  Future<Map<String, TratamientoAplicadoDetalle>>
  getDetalleTratamientosAplicados(List<String> ids);
  Future<List<Consulta>> getHistorialPaciente(String pacienteId);

  Future<Map<int, List<TratamientoAplicado>>>
  getTratamientosHistoricosPorDiente(
    String pacienteId, {
    String? excluyendoConsultaId,
  });

  /// Los hallazgos de consultas anteriores, agrupados por pieza y con su fecha,
  /// consulta y doctor intactos.
  ///
  /// Es la contraparte de [getEvaluacionHistorica]: aquella consolida los
  /// antecedentes en claves dibujables y pierde la procedencia de cada uno;
  /// esta los conserva para que la ficha de la pieza pueda mostrarla (SD-142).
  Future<Map<int, List<DiagnosticoAplicado>>>
  getDiagnosticosHistoricosPorDiente(
    String pacienteId, {
    String? excluyendoConsultaId,
  });

  /// La línea de tiempo de cada pieza del paciente: todo lo evaluado,
  /// planificado y ejecutado sobre ella en cualquier consulta, anulaciones
  /// incluidas y agrupado por visita (SD-144).
  ///
  /// No se deriva de los odontogramas: cada uno describe la boca de su día y
  /// consolidarlos —la Vista General del expediente lo hace— se queda con una
  /// sola anotación por pieza. El historial se arma de los tres ejes clínicos,
  /// que conservan una fila por cada cosa que ocurrió.
  Future<HistorialPiezas> getHistorialPiezas(String pacienteId);

  /// Consolida los odontodiagramas anteriores del paciente en una sola
  /// evaluación, para dibujarlos como capa histórica bajo la de hoy.
  Future<EvaluacionOdontologica> getEvaluacionHistorica(
    String pacienteId, {
    String? excluyendoConsultaId,
  });
  Future<Consulta?> getDetalleConsulta(String id);
  Future<void> eliminarConsulta(String id);
}
