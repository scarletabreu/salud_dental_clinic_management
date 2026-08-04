import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/consumible_compra/data/models/consumible_compra_model.dart';
import 'package:salud_dental_clinic_management/features/consumible_compra/domain/entities/consumible_compra.dart';
import 'package:salud_dental_clinic_management/features/consumible_compra/domain/repositories/consumible_compra_repository.dart';
import 'package:salud_dental_clinic_management/features/consumible_compra/data/datasources/consumible_compra_remote_datasource.dart';

class ConsumibleCompraRepositoryImpl implements ConsumibleCompraRepository {
  final ConsumibleCompraRemoteDatasource remoteDataSource;

  ConsumibleCompraRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ConsumibleCompra>> fetchItemsByCompraId(String compraId) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchItemsByCompra(compraId);
      return data.map((json) => ConsumibleCompraModel.fromJson(json)).toList();
    }, context: 'obtener los items de la compra');
  }

  @override
  Future<ConsumibleCompra?> getConsumibleById(String id) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchConsumibleById(id);
      return data == null ? null : ConsumibleCompraModel.fromJson(data);
    }, context: 'obtener el consumible');
  }

  @override
  Future<void> actualizarConsumible(ConsumibleCompra consumible) {
    return runGuarded(() async {
      final model = ConsumibleCompraModel(
        id: consumible.id,
        cantidad: consumible.cantidad,
        precioUnitario: consumible.precioUnitario,
        compraId: consumible.compraId,
        consumibleId: consumible.consumibleId,
        suplidorId: consumible.suplidorId,
      );
      await remoteDataSource.updateConsumible(model.toJson());
    }, context: 'actualizar el consumible');
  }

  @override
  Future<void> eliminarConsumibleDeCompra(String id) {
    return runGuarded(
      () => remoteDataSource.deleteConsumible(id),
      context: 'eliminar el consumible de la compra',
    );
  }
}
