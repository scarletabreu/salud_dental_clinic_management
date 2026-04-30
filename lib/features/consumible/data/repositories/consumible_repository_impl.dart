import 'package:salud_dental_clinic_management/features/consumible/domain/entities/consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/repositories/consumible_repository.dart';
import 'package:salud_dental_clinic_management/features/consumible/data/datasources/consumible_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/consumible/data/models/consumible_model.dart';

class ConsumibleRepositoryImpl implements ConsumibleRepository {
  final ConsumibleRemoteDatasource remoteDataSource;

  ConsumibleRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Consumible>> getInventario() async {
    try {
      final data = await remoteDataSource.fetchConsumibles();
      return data.map((json) => ConsumibleModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error en el repositorio al obtener inventario: $e');
    }
  }

  @override
  Future<void> actualizarExistencia(String id, int nuevoStock) async {
    try {
      await remoteDataSource.updateStock(id, nuevoStock);
    } catch (e) {
      throw Exception('Error en el repositorio al actualizar existencia: $e');
    }
  }

  @override
  Future<void> guardarConsumible(Consumible consumible) async {
    try {
      final model = ConsumibleModel(
        id: consumible.id,
        nombre: consumible.nombre,
        descripcion: consumible.descripcion,
        stockActual: consumible.stockActual,
        stockMinimo: consumible.stockMinimo,
        estado: consumible.estado,
      );

      await remoteDataSource.upsertConsumible(model.toJson());
    } catch (e) {
      throw Exception('Error en el repositorio al guardar consumible: $e');
    }
  }

  @override
  Future<void> eliminarConsumible(String id) async {
    try {
      await remoteDataSource.deleteConsumible(id);
    } catch (e) {
      throw Exception('Error en el repositorio al eliminar consumible: $e');
    }
  }
}
