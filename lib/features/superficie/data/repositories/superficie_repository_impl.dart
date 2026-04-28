import 'package:salud_dental_clinic_management/features/superficie/data/datasources/superficie_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/superficie/data/models/superficie_model.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/entities/superficie.dart'
    as entity;
import 'package:salud_dental_clinic_management/features/superficie/domain/repositories/superficie_repository.dart';

class SuperficieRepositoryImpl implements SuperficieRepository {
  final SuperficieRemoteDatasource remoteDataSource;

  SuperficieRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> guardarEstadoSuperficie(entity.Superficie superficie) async {
    final model = SuperficieModel.fromEntity(superficie);
    final data = model.toJson();

    // Control de auditoría para la base de datos de Joseph
    data['deleted_at'] = null;
    data['updated_at'] = DateTime.now().toIso8601String();

    await remoteDataSource.actualizarSuperficie(data);
  }

  @override
  Future<void> eliminarSuperficie(String id) async {
    await remoteDataSource.eliminarSuperficie(id);
  }

  @override
  Future<List<entity.Superficie>> getSuperficiesDelDiente(
    String dienteId,
  ) async {
    final data = await remoteDataSource.fetchSuperficiesPorDiente(dienteId);
    return data.map((json) => SuperficieModel.fromJson(json)).toList();
  }
}
