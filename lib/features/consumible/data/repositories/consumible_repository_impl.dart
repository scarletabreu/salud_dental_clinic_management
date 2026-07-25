import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/entities/consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/enums/motivo_ajuste_stock.dart';
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
  Future<void> ajustarStock(
    String id,
    int nuevoStock,
    MotivoAjusteStock motivo,
  ) {
    if (nuevoStock < 0) {
      throw ArgumentError.value(
        nuevoStock,
        'nuevoStock',
        'No puede ser negativo',
      );
    }
    return runGuarded(
      () => remoteDataSource.adjustStock(id, nuevoStock, motivo.name),
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
        precio: consumible.precio,
        stockActual: consumible.stockActual,
        stockMinimo: consumible.stockMinimo,
        estado: consumible.estadoCalculado,
        suplidorId: consumible.suplidorId,
        suplidorNombre: consumible.suplidorNombre,
        activo: consumible.activo,
      );

      final data = model.toJson();
      if (consumible.id == null) {
        await remoteDataSource.createConsumible(data);
      } else {
        await remoteDataSource.updateConsumible(consumible.id!, data);
      }
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
