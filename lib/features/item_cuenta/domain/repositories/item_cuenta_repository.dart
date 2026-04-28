import '../entities/item_cuenta.dart';

abstract class ItemCuentaRepository {
  Future<List<ItemCuenta>> getItemsDeCuenta(String cuentaId);
  Future<void> agregarItemACuenta(ItemCuenta item);
  Future<void> eliminarItemDeCuenta(String id);
}
