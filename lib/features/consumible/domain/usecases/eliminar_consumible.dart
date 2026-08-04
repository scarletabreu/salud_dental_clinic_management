import 'package:salud_dental_clinic_management/features/consumible/domain/repositories/consumible_repository.dart';

class EliminarConsumible {
  final ConsumibleRepository repository;

  EliminarConsumible(this.repository);

  Future<void> call(String id) => repository.eliminarConsumible(id);
}
