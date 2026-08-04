import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/entities/suplidor.dart'
    as entity;
import 'package:salud_dental_clinic_management/features/suplidor/domain/repositories/suplidor_repository.dart';
import 'package:salud_dental_clinic_management/features/suplidor/data/datasources/suplidor_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/suplidor/data/models/suplidor_model.dart';

class SuplidorRepositoryImpl implements SuplidorRepository {
  final SuplidorRemoteDatasource remoteDataSource;

  SuplidorRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<entity.Suplidor>> getDirectorioSuplidores() {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchSuplidores();
      return data.map((json) => SuplidorModel.fromJson(json)).toList();
    }, context: 'obtener los suplidores');
  }

  @override
  Future<void> guardarSuplidor(entity.Suplidor suplidor) {
    return runGuarded(() async {
      final data = SuplidorModel.fromEntity(suplidor).toJson();
      data['deleted_at'] = null;
      data['updated_at'] = DateTime.now().toUtc().toIso8601String();
      await remoteDataSource.upsertSuplidor(data);
    }, context: 'guardar el suplidor');
  }

  @override
  Future<void> eliminarSuplidor(String id) {
    return runGuarded(
      () => remoteDataSource.softDeleteSuplidor(id),
      context: 'eliminar el suplidor',
    );
  }
}
