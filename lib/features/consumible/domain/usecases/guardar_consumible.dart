import 'package:salud_dental_clinic_management/features/consumible/domain/entities/consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/repositories/consumible_repository.dart';

class GuardarConsumible {
  final ConsumibleRepository repository;

  GuardarConsumible(this.repository);

  Future<void> call(Consumible consumible) =>
      repository.guardarConsumible(consumible);
}
