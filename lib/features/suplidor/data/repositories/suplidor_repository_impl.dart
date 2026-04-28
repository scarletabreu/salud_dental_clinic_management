import 'package:salud_dental_clinic_management/features/suplidor/data/datasources/suplidor_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/suplidor/data/models/suplidor_model.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/entities/suplidor.dart'
    as entity;
import 'package:salud_dental_clinic_management/features/suplidor/domain/repositories/suplidor_repository.dart';

class SuplidorRepositoryImpl implements SuplidorRepository {
  final SuplidorRemoteDatasource remoteDataSource;

  SuplidorRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<entity.Suplidor>> getDirectorioSuplidores() async {
    final data = await remoteDataSource.fetchSuplidores();
    return data.map((json) => SuplidorModel.fromJson(json)).toList();
  }

  @override
  Future<void> guardarSuplidor(entity.Suplidor suplidor) async {
    final model = SuplidorModel.fromEntity(suplidor);
    final data = model.toJson();

    data['deleted_at'] = null;
    data['updated_at'] = DateTime.now().toIso8601String();

    await remoteDataSource.upsertSuplidor(data);
  }

  @override
  Future<void> eliminarSuplidor(String id) async {
    await remoteDataSource.softDeleteSuplidor(id);
  }
}
