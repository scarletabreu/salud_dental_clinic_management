import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/entities/superficie.dart'
    as entity;
import 'package:salud_dental_clinic_management/features/superficie/domain/repositories/superficie_repository.dart';
import 'package:salud_dental_clinic_management/features/superficie/data/datasources/superficie_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/superficie/data/models/superficie_model.dart';

class SuperficieRepositoryImpl implements SuperficieRepository {
  final SuperficieRemoteDatasource remoteDataSource;

  SuperficieRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> guardarEstadoSuperficie(entity.Superficie superficie) {
    return runGuarded(() async {
      final data = SuperficieModel.fromEntity(superficie).toJson();
      data['deleted_at'] = null;
      data['updated_at'] = DateTime.now().toIso8601String();
      await remoteDataSource.actualizarSuperficie(data);
    }, context: 'guardar el estado de la superficie');
  }

  @override
  Future<void> eliminarSuperficie(String id) {
    return runGuarded(
      () => remoteDataSource.eliminarSuperficie(id),
      context: 'eliminar la superficie',
    );
  }

  @override
  Future<List<entity.Superficie>> getSuperficiesDelDiente(String dienteId) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchSuperficiesPorDiente(dienteId);
      return data.map((json) => SuperficieModel.fromJson(json)).toList();
    }, context: 'cargar las superficies');
  }
}
