import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/procedimiento/domain/entities/procedimiento.dart';
import 'package:salud_dental_clinic_management/features/procedimiento/domain/repositories/procedimiento_repository.dart';
import 'package:salud_dental_clinic_management/features/procedimiento/data/datasources/procedimiento_remore_datasource.dart';
import 'package:salud_dental_clinic_management/features/procedimiento/data/models/procedimiento_model.dart';

class ProcedimientoRepositoryImpl implements ProcedimientoRepository {
  final ProcedimientoRemoteDatasource remoteDataSource;

  ProcedimientoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Procedimiento>> getCatalogoProcedimientos() {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchProcedimientos();
      return data.map((json) => ProcedimientoModel.fromJson(json)).toList();
    }, context: 'obtener los procedimientos');
  }

  @override
  Future<void> guardarProcedimiento(Procedimiento procedimiento) {
    return runGuarded(() async {
      final data = ProcedimientoModel.fromEntity(procedimiento).toJson();
      data['deleted_at'] = null;
      data['updated_at'] = DateTime.now().toIso8601String();
      await remoteDataSource.upsertProcedimiento(data);
    }, context: 'guardar el procedimiento');
  }

  @override
  Future<void> eliminarProcedimiento(String id) {
    return runGuarded(
      () => remoteDataSource.softDeleteProcedimiento(id),
      context: 'eliminar el procedimiento',
    );
  }
}
