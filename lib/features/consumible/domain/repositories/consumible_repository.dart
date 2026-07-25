import 'package:salud_dental_clinic_management/features/consumible/domain/entities/consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/enums/motivo_ajuste_stock.dart';

abstract class ConsumibleRepository {
  Future<List<Consumible>> getInventario();
  Future<void> ajustarStock(
    String id,
    int nuevoStock,
    MotivoAjusteStock motivo,
  );
  Future<void> guardarConsumible(Consumible consumible);
  Future<void> eliminarConsumible(String id);
  Future<void> descontarPorConsumo({
    required String consumibleId,
    required int cantidad,
  });
}
