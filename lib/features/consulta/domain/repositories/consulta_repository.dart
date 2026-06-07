import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';

abstract class ConsultaRepository {
  Future<void> registrarConsulta(Consulta consulta);
  Future<List<Consulta>> getConsultas();

  /// `paciente_id`s con al menos un tratamiento aplicado vigente. Usado por el
  /// listado para indicar (por paciente) si hay tratamientos aplicados.
  Future<Set<String>> getPacienteIdsConTratamientos();
  Future<List<Consulta>> getHistorialPaciente(String pacienteId);
  Future<Consulta?> getDetalleConsulta(String id);
  Future<void> eliminarConsulta(String id);
}
