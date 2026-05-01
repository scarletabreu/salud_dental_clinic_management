import 'package:salud_dental_clinic_management/features/superficie/domain/entities/superficie.dart'
    as entity;
import 'package:salud_dental_clinic_management/features/superficie/domain/repositories/superficie_repository.dart';
import 'package:salud_dental_clinic_management/features/superficie/data/datasources/superficie_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/superficie/data/models/superficie_model.dart';

class SuperficieRepositoryImpl implements SuperficieRepository {
  final SuperficieRemoteDatasource remoteDataSource;

  SuperficieRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> guardarEstadoSuperficie(entity.Superficie superficie) async {
    try {
      final model = SuperficieModel.fromEntity(superficie);
      final data = model.toJson();

      data['deleted_at'] = null;
      data['updated_at'] = DateTime.now().toIso8601String();

      await remoteDataSource.actualizarSuperficie(data);
    } catch (e) {
      throw Exception(
        'Error en el repositorio al guardar estado de superficie: $e',
      );
    }
  }

  @override
  Future<void> eliminarSuperficie(String id) async {
    try {
      await remoteDataSource.eliminarSuperficie(id);
    } catch (e) {
      throw Exception('Error en el repositorio al eliminar superficie: $e');
    }
  }

  @override
  Future<List<entity.Superficie>> getSuperficiesDelDiente(
    String dienteId,
  ) async {
    try {
      final data = await remoteDataSource.fetchSuperficiesPorDiente(dienteId);
      return data.map((json) => SuperficieModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error en el repositorio al cargar superficies: $e');
    }
  }
}
