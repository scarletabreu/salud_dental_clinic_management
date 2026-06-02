import 'package:salud_dental_clinic_management/features/suplidor/domain/entities/suplidor.dart'
    as entity;
import 'package:salud_dental_clinic_management/features/suplidor/domain/repositories/suplidor_repository.dart';
import 'package:salud_dental_clinic_management/features/suplidor/data/datasources/suplidor_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/suplidor/data/models/suplidor_model.dart';

class SuplidorRepositoryImpl implements SuplidorRepository {
  final SuplidorRemoteDatasource remoteDataSource;

  SuplidorRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<entity.Suplidor>> getDirectorioSuplidores() async {
    try {
      final data = await remoteDataSource.fetchSuplidores();
      return data.map((json) => SuplidorModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error en el repositorio al obtener suplidores: $e');
    }
  }

  @override
  Future<void> guardarSuplidor(entity.Suplidor suplidor) async {
    try {
      final model = SuplidorModel.fromEntity(suplidor);
      final data = model.toJson();

      data['deleted_at'] = null;
      data['updated_at'] = DateTime.now().toIso8601String();

      await remoteDataSource.upsertSuplidor(data);
    } catch (e) {
      throw Exception('Error en el repositorio al guardar suplidor: $e');
    }
  }

  @override
  Future<void> eliminarSuplidor(String id) async {
    try {
      await remoteDataSource.softDeleteSuplidor(id);
    } catch (e) {
      throw Exception('Error en el repositorio al eliminar suplidor: $e');
    }
  }
}
