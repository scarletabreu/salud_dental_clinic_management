import 'package:salud_dental_clinic_management/features/consulta/data/models/consulta_model.dart';

abstract class ConsultaRemoteDatasource {
  Future<void> crearConsulta(ConsultaModel consulta);

  /// Invoca el RPC transaccional `crear_consulta_completa` con [params].
  Future<void> crearConsultaCompleta(Map<String, dynamic> params);
  Future<List<Map<String, dynamic>>> fetchConsultas();

  /// Devuelve el conjunto de `paciente_id` que tienen al menos un tratamiento
  /// aplicado vigente. `tratamientos_aplicados` solo se vincula al paciente,
  /// por lo que el indicador de tratamientos del listado es por paciente.
  Future<Set<String>> fetchPacienteIdsConTratamientos();
  Future<List<Map<String, dynamic>>> fetchConsultasByPaciente(
    String pacienteId,
  );
  Future<Map<String, dynamic>?> fetchConsultaById(String id);
  Future<void> updateConsulta(String id, Map<String, dynamic> consultaData);
  Future<void> deleteConsulta(String id);
}
