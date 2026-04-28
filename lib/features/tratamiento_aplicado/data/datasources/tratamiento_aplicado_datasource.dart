abstract class TratamientoAplicadoDatasource {
  Future<void> registrarTratamiento(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> fetchPorPaciente(String pacienteId);
  Future<void> marcarComoTerminado(String id);
  Future<void> eliminarTratamiento(String id);
}
