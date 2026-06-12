import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';

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
  Future<Consulta?> getDetalleConsulta(String id);
  Future<void> eliminarConsulta(String id);
}
