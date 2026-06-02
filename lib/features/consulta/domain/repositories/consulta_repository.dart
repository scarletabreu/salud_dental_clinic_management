import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';

abstract class ConsultaRepository {
  Future<void> registrarConsulta(Consulta consulta);
  Future<List<Consulta>> getHistorialPaciente(String pacienteId);
  Future<Consulta?> getDetalleConsulta(String id);
  Future<void> eliminarConsulta(String id);
}
