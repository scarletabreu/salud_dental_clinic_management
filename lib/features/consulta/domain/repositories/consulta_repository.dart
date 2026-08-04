import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/tratamiento_aplicado_detalle.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta_de_cita.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/condicion_detectada.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/inicio_consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/insumo_utilizado.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/signos_vitales.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/resultado_borrador_consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/resultado_cierre_consulta.dart';
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

  /// Abre —o recupera— la consulta de una cita.
  ///
  /// La identidad, la fecha y el estado los resuelve la base a partir de la
  /// cita: el cliente ya no propone paciente ni doctor, así que no puede
  /// desalinearlos. Reintentar es seguro; el resultado dice si la consulta se
  /// creó, se reanudó o ya estaba cerrada.
  Future<InicioConsulta> iniciarConsultaDeCita(Consulta consulta);

  /// Guarda el borrador clínico completo en una sola transacción: odontograma,
  /// recetas, insumos declarados, notas y signos vitales.
  ///
  /// Devuelve, por código FDI, los ids de los tratamientos aplicados en el
  /// mismo orden en que se enviaron: sellarlos sobre el estado en memoria es
  /// lo que permite que el siguiente guardado actualice esas filas en vez de
  /// crear duplicados. [version] detecta que otra sesión escribió primero.
  ///
  /// Lanza `ConflictoVersionFailure` si la versión quedó obsoleta y
  /// `ConsultaCerradaFailure` si la consulta ya se finalizó. En ambos casos no
  /// se escribió nada.
  Future<ResultadoBorradorConsulta> guardarBorradorConsulta({
    required String consultaId,
    int? version,
    required Odontograma odontograma,
    required List<Receta> recetas,
    List<InsumoUtilizado> insumos,
    String? notas,
    SignosVitales? signosVitales,
    List<CondicionDetectada> condicionesDetectadas,
    List<TratamientoAplicado> tratamientosGenerales,
    List<DiagnosticoAplicado> diagnosticosGenerales,
  });

  /// Cierra la consulta como una sola operación: guarda el borrador final,
  /// descuenta inventario, emite las recetas, genera la pre-factura y completa
  /// la cita. O queda todo confirmado, o no cambia nada.
  ///
  /// [idempotenciaKey] identifica el intento lógico: repetir el mismo cierre
  /// devuelve el resultado existente sin volver a descontar ni facturar.
  Future<ResultadoCierreConsulta> cerrarConsulta({
    required String consultaId,
    int? version,
    required Odontograma odontograma,
    required List<Receta> recetas,
    List<InsumoUtilizado> insumos,
    String? notas,
    SignosVitales? signosVitales,
    List<CondicionDetectada> condicionesDetectadas,
    List<TratamientoAplicado> tratamientosGenerales,
    List<DiagnosticoAplicado> diagnosticosGenerales,
    required String idempotenciaKey,
    String? nota,
  });

  /// Deja constancia de la decisión clínica sobre una alerta (HFX-CLIN-003).
  /// `documentada` exige justificación; sin ella el cierre sigue bloqueado.
  Future<void> resolverAlerta({
    required String alertaId,
    required bool documentada,
    String? justificacion,
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
