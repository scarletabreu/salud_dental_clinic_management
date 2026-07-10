import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/repositories/receta_repository.dart';
import 'package:salud_dental_clinic_management/features/receta/data/datasources/receta_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/receta/data/models/receta_model.dart';

class RecetaRepositoryImpl implements RecetaRepository {
  final RecetaRemoteDatasource remoteDataSource;

  RecetaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> emitirReceta(Receta receta) {
    return runGuarded(() async {
      final data = RecetaModel.fromEntity(receta).toJson();
      data['deleted_at'] = null;
      await remoteDataSource.crearReceta(data);
    }, context: 'emitir la receta');
  }

  @override
  Future<void> editarReceta(Receta receta) {
    return runGuarded(() async {
      final data = RecetaModel.fromEntity(receta).toJson();
      data['updated_at'] = DateTime.now().toIso8601String();
      await remoteDataSource.actualizarReceta(data);
    }, context: 'editar la receta');
  }

  @override
  Future<void> cancelarReceta(String id) {
    return runGuarded(
      () => remoteDataSource.anularReceta(id),
      context: 'cancelar la receta',
    );
  }

  @override
  Future<List<Receta>> getHistorialRecetas(String pacienteId) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchRecetasByPaciente(pacienteId);
      return data.map((json) => RecetaModel.fromJson(json)).toList();
    }, context: 'cargar el historial de recetas');
  }
}
