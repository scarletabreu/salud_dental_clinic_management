import 'package:salud_dental_clinic_management/features/consumible_compra/domain/entities/consumible_compra.dart';

abstract class ConsumibleCompraRepository {
  Future<List<ConsumibleCompra>> fetchItemsByCompraId(String compraId);
  Future<ConsumibleCompra?> getConsumibleById(String id);
  Future<void> actualizarConsumible(ConsumibleCompra consumible);
  Future<void> eliminarConsumibleDeCompra(String id);
}
