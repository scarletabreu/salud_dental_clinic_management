import 'package:salud_dental_clinic_management/features/consumible/domain/entities/consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/repositories/consumible_repository.dart';

class ObtenerArticulosBajoMinimo {
  final ConsumibleRepository repository;

  ObtenerArticulosBajoMinimo(this.repository);

  Future<List<Consumible>> call() async {
    final todos = await repository.getInventario();
    return todos.where((c) => c.estaBajoStock).toList();
  }
}
