import 'package:salud_dental_clinic_management/features/consumible/domain/repositories/consumible_repository.dart';

class ActualizarExistencia {
  final ConsumibleRepository repository;

  ActualizarExistencia(this.repository);

  Future<void> call(String id, int nuevoStock) =>
      repository.actualizarExistencia(id, nuevoStock);
}
