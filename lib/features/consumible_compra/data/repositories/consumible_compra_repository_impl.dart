import 'package:salud_dental_clinic_management/features/consumible_compra/domain/entities/consumible_compra.dart';
import 'package:salud_dental_clinic_management/features/consumible_compra/domain/repositories/consumible_compra_repository.dart';
import 'package:salud_dental_clinic_management/features/consumible_compra/data/datasources/consumible_compra_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/consumible_compra/data/models/consumible_compra_model.dart';

class ConsumibleCompraRepositoryImpl implements ConsumibleCompraRepository {
  final ConsumibleCompraRemoteDatasource remoteDataSource;

  ConsumibleCompraRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ConsumibleCompra>> fetchItemsByCompraId(String compraId) async {
    final List<Map<String, dynamic>> data = await remoteDataSource
        .fetchItemsByCompra(compraId);

    return data.map((json) => ConsumibleCompraModel.fromJson(json)).toList();
  }

  @override
  Future<ConsumibleCompra?> getConsumibleById(String id) async {
    final data = await remoteDataSource.fetchConsumibleById(id);
    if (data == null) return null;

    return ConsumibleCompraModel.fromJson(data);
  }

  @override
  Future<void> actualizarConsumible(ConsumibleCompra consumible) async {
    final model = ConsumibleCompraModel(
      id: consumible.id,
      cantidad: consumible.cantidad,
      precioUnitario: consumible.precioUnitario,
      compraId: consumible.compraId,
      consumibleId: consumible.consumibleId,
      suplidorId: consumible.suplidorId,
    );

    await remoteDataSource.updateConsumible(model.toJson());
  }

  @override
  Future<void> eliminarConsumibleDeCompra(String id) async {
    await remoteDataSource.deleteConsumible(id);
  }
}
