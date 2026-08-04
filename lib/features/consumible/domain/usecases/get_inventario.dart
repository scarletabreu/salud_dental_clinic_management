import 'package:salud_dental_clinic_management/features/consumible/domain/entities/consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/repositories/consumible_repository.dart';

class GetInventario {
  final ConsumibleRepository repository;

  GetInventario(this.repository);

  Future<List<Consumible>> call() => repository.getInventario();
}
