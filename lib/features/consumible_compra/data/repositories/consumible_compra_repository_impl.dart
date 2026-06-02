import 'package:salud_dental_clinic_management/features/consumible_compra/data/models/consumible_compra_model.dart';
import 'package:salud_dental_clinic_management/features/consumible_compra/domain/entities/consumible_compra.dart';
import 'package:salud_dental_clinic_management/features/consumible_compra/domain/repositories/consumible_compra_repository.dart';
import 'package:salud_dental_clinic_management/features/consumible_compra/data/datasources/consumible_compra_remote_datasource.dart';

class ConsumibleCompraRepositoryImpl implements ConsumibleCompraRepository {
  final ConsumibleCompraRemoteDatasource remoteDataSource;

  ConsumibleCompraRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ConsumibleCompra>> fetchItemsByCompraId(String compraId) async {
    try {
      final List<Map<String, dynamic>> data = await remoteDataSource
          .fetchItemsByCompra(compraId);
      return data.map((json) => ConsumibleCompraModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception(
        'Error en el repositorio al obtener items de la compra: $e',
      );
    }
  }

  @override
  Future<ConsumibleCompra?> getConsumibleById(String id) async {
    try {
      final data = await remoteDataSource.fetchConsumibleById(id);
      return data == null ? null : ConsumibleCompraModel.fromJson(data);
    } catch (e) {
      throw Exception(
        'Error en el repositorio al obtener consumible por ID: $e',
      );
    }
  }

  @override
  Future<void> actualizarConsumible(ConsumibleCompra consumible) async {
    try {
      final model = ConsumibleCompraModel(
        id: consumible.id,
        cantidad: consumible.cantidad,
        precioUnitario: consumible.precioUnitario,
        compraId: consumible.compraId,
        consumibleId: consumible.consumibleId,
        suplidorId: consumible.suplidorId,
      );
      await remoteDataSource.updateConsumible(model.toJson());
    } catch (e) {
      throw Exception('Error en el repositorio al actualizar consumible: $e');
    }
  }

  @override
  Future<void> eliminarConsumibleDeCompra(String id) async {
    try {
      await remoteDataSource.deleteConsumible(id);
    } catch (e) {
      throw Exception('No se pudo eliminar el consumible de la compra: $e');
    }
  }
}
