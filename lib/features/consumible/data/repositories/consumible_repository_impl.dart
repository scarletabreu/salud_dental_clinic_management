import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/entities/consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/repositories/consumible_repository.dart';
import 'package:salud_dental_clinic_management/features/consumible/data/datasources/consumible_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/consumible/data/models/consumible_model.dart';

class ConsumibleRepositoryImpl implements ConsumibleRepository {
  final ConsumibleRemoteDatasource remoteDataSource;

  ConsumibleRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Consumible>> getInventario() {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchConsumibles();
      return data.map((json) => ConsumibleModel.fromJson(json)).toList();
    }, context: 'obtener el inventario');
  }

  @override
  Future<void> actualizarExistencia(String id, int nuevoStock) {
    return runGuarded(
      () => remoteDataSource.updateStock(id, nuevoStock),
      context: 'actualizar la existencia',
    );
  }

  @override
  Future<void> guardarConsumible(Consumible consumible) {
    return runGuarded(() async {
      final model = ConsumibleModel(
        id: consumible.id,
        nombre: consumible.nombre,
        descripcion: consumible.descripcion,
        stockActual: consumible.stockActual,
        stockMinimo: consumible.stockMinimo,
        estado: consumible.estado,
      );

      await remoteDataSource.upsertConsumible(model.toJson());
    }, context: 'guardar el consumible');
  }

  @override
  Future<void> eliminarConsumible(String id) {
    return runGuarded(
      () => remoteDataSource.deleteConsumible(id),
      context: 'eliminar el consumible',
    );
  }
}
