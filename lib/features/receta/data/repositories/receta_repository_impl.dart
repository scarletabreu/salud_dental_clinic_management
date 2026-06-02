import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/repositories/receta_repository.dart';
import 'package:salud_dental_clinic_management/features/receta/data/datasources/receta_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/receta/data/models/receta_model.dart';

class RecetaRepositoryImpl implements RecetaRepository {
  final RecetaRemoteDatasource remoteDataSource;

  RecetaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> emitirReceta(Receta receta) async {
    try {
      final model = RecetaModel.fromEntity(receta);
      final data = model.toJson();
      data['deleted_at'] = null;
      await remoteDataSource.crearReceta(data);
    } catch (e) {
      throw Exception('Error en el repositorio al emitir receta: $e');
    }
  }

  @override
  Future<void> editarReceta(Receta receta) async {
    try {
      final model = RecetaModel.fromEntity(receta);
      final data = model.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();
      await remoteDataSource.actualizarReceta(data);
    } catch (e) {
      throw Exception('Error en el repositorio al editar receta: $e');
    }
  }

  @override
  Future<void> cancelarReceta(String id) async {
    try {
      await remoteDataSource.anularReceta(id);
    } catch (e) {
      throw Exception('Error en el repositorio al cancelar receta: $e');
    }
  }

  @override
  Future<List<Receta>> getHistorialRecetas(String pacienteId) async {
    try {
      final data = await remoteDataSource.fetchRecetasByPaciente(pacienteId);
      return data.map((json) => RecetaModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception(
        'Error en el repositorio al cargar historial de recetas: $e',
      );
    }
  }
}
