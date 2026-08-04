import 'package:salud_dental_clinic_management/features/consumible/domain/repositories/consumible_repository.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/enums/motivo_ajuste_stock.dart';

class ActualizarExistencia {
  final ConsumibleRepository repository;

  ActualizarExistencia(this.repository);

  Future<void> call(String id, int nuevoStock, MotivoAjusteStock motivo) =>
      repository.ajustarStock(id, nuevoStock, motivo);
}
