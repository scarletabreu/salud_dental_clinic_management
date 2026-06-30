import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

abstract class ConsultaRepository {
  Future<List<Consulta>> getConsultas();
  Future<List<Consulta>> getConsultasByDoctor(String doctorId);

  Future<String> crearConsultaCompleta(Consulta consulta);

  Future<void> guardarResultadoConsulta({
    required String consultaId,
    required Odontograma odontograma,
    String? notas,
  });

  Future<Map<String, String>> getNombresTratamientosAplicados(
    List<String> ids,
  );
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
