import 'package:salud_dental_clinic_management/features/procedimiento/domain/entities/procedimiento.dart';
import 'package:salud_dental_clinic_management/features/procedimiento/domain/repositories/procedimiento_repository.dart';
import 'package:salud_dental_clinic_management/features/procedimiento/data/datasources/procedimiento_remore_datasource.dart';
import 'package:salud_dental_clinic_management/features/procedimiento/data/models/procedimiento_model.dart';

class ProcedimientoRepositoryImpl implements ProcedimientoRepository {
  final ProcedimientoRemoteDatasource remoteDataSource;

  ProcedimientoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Procedimiento>> getCatalogoProcedimientos() async {
    try {
      final data = await remoteDataSource.fetchProcedimientos();
      return data.map((json) => ProcedimientoModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error en el repositorio al obtener procedimientos: $e');
    }
  }

  @override
  Future<void> guardarProcedimiento(Procedimiento procedimiento) async {
    try {
      final model = ProcedimientoModel.fromEntity(procedimiento);
      final data = model.toJson();

      data['deleted_at'] = null;
      data['updated_at'] = DateTime.now().toIso8601String();

      await remoteDataSource.upsertProcedimiento(data);
    } catch (e) {
      throw Exception('Error en el repositorio al guardar procedimiento: $e');
    }
  }

  @override
  Future<void> eliminarProcedimiento(String id) async {
    try {
      await remoteDataSource.softDeleteProcedimiento(id);
    } catch (e) {
      throw Exception('Error en el repositorio al eliminar procedimiento: $e');
    }
  }
}
