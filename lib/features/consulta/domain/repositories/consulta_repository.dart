import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';

abstract class ConsultaRepository {
  Future<void> registrarConsulta(Consulta consulta);

  /// Crea la consulta junto a su odontograma, los 32 dientes con sus
  /// superficies y los documentos clínicos en una sola operación atómica (RPC).
  Future<void> crearConsultaCompleta(Consulta consulta);
  Future<List<Consulta>> getHistorialPaciente(String pacienteId);
  Future<Consulta?> getDetalleConsulta(String id);
  Future<void> eliminarConsulta(String id);
}
