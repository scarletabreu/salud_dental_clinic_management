import 'package:salud_dental_clinic_management/features/item_cuenta/data/datasources/item_cuenta_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/item_cuenta/domain/entities/item_cuenta.dart';
import 'package:salud_dental_clinic_management/features/item_cuenta/domain/repositories/item_cuenta_repository.dart';
import '../models/item_cuenta_model.dart';

class ItemCuentaRepositoryImpl implements ItemCuentaRepository {
  final ItemCuentaDatasource remoteDataSource;

  ItemCuentaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ItemCuenta>> getItemsDeCuenta(String cuentaId) async {
    final data = await remoteDataSource.fetchItemsByCuenta(cuentaId);
    return data.map((json) => ItemCuentaModel.fromJson(json)).toList();
  }

  @override
  Future<void> agregarItemACuenta(ItemCuenta item) async {
    final model = ItemCuentaModel(
      id: item.id,
      cuentaId: item.cuentaId,
      descripcion: item.descripcion,
      precioUnitario: item.precioUnitario,
      cantidad: item.cantidad,
      tratamientosAplicados: item.tratamientosAplicados,
    );

    final data = model.toJson();
    data['deleted_at'] = null;

    await remoteDataSource.insertItem(data);
  }

  @override
  Future<void> eliminarItemDeCuenta(String id) async {
    await remoteDataSource.softDeleteItem(id);
  }
}
