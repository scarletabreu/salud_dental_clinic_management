import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/tratamiento_aplicado_detalle.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

abstract class ConsultaRepository {
  Future<List<Consulta>> getConsultas();
  Future<List<Consulta>> getConsultasByDoctor(String doctorId);

  Future<String> crearConsultaCompleta(Consulta consulta);

  Future<void> guardarResultadoConsulta({
    required String consultaId,
    required String? pacienteId,
    required Odontograma odontograma,
    String? notas,
    Map<String, dynamic>? signosVitales,
    bool? finalizada,
    List<Receta>? recetas,
  });

  /// Detalle (nombre del catálogo + precio congelado + superficie/notas) de los
  /// tratamientos aplicados que el odontograma de la consulta referencia por id.
  /// Devuelve un mapa `id de tratamiento_aplicado → detalle`.
  Future<Map<String, TratamientoAplicadoDetalle>>
  getDetalleTratamientosAplicados(List<String> ids);
  Future<List<Consulta>> getHistorialPaciente(String pacienteId);

  /// Tratamientos aplicados en consultas anteriores del paciente, agrupados por
  /// código FDI del diente. Sirve para pintar la capa "histórico" del
  /// odontograma de una consulta nueva.
  Future<Map<int, List<TratamientoAplicado>>> getTratamientosHistoricosPorDiente(
    String pacienteId, {
    String? excluyendoConsultaId,
  });
  Future<Consulta?> getDetalleConsulta(String id);
  Future<void> eliminarConsulta(String id);
}
