import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

abstract class TratamientoAplicadoRepository {
  Future<void> realizarTratamiento(TratamientoAplicado tratamiento);
  Future<List<TratamientoAplicado>> getHistorialClinico(String pacienteId);
  Future<void> finalizarTratamiento(String id);
  Future<void> eliminarTratamientoAplicado(String id);
}
