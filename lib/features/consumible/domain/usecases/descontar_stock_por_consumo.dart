import 'package:salud_dental_clinic_management/features/consulta/domain/entities/insumo_utilizado.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/repositories/consumible_repository.dart';

/// Descuenta del inventario los insumos usados al cerrar una consulta y dejar
/// su rastro en `movimientos_stock_consumible`.
///
/// Deuda técnica conocida: esto corre en una llamada por insumo, no dentro de
/// la misma transacción que `finalizar_consulta`. Si el finalizado falla
/// después de este paso, el stock ya quedó descontado. Aceptable para el
/// plazo académico; evolución futura: mover a una RPC única que descuente
/// stock + finalice la consulta de forma atómica.
class DescontarStockPorConsumo {
  final ConsumibleRepository repository;

  DescontarStockPorConsumo(this.repository);

  Future<void> call(List<InsumoUtilizado> insumos) async {
    if (insumos.isEmpty) return;
    for (final insumo in insumos) {
      await repository.descontarPorConsumo(
        consumibleId: insumo.consumibleId,
        cantidad: insumo.cantidad,
      );
    }
  }
}