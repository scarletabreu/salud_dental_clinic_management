import 'package:salud_dental_clinic_management/features/consulta/data/models/consulta_model.dart';

abstract class ConsultaRemoteDatasource {
  Future<void> crearConsulta(ConsultaModel consulta);
  Future<List<Map<String, dynamic>>> fetchConsultasByPaciente(
    String pacienteId,
  );
  Future<Map<String, dynamic>?> fetchConsultaById(String id);
  Future<void> updateConsulta(String id, Map<String, dynamic> consultaData);
  Future<void> deleteConsulta(String id);
}
