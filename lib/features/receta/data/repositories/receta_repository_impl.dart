import 'package:salud_dental_clinic_management/features/receta/data/datasources/receta_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/receta/data/models/receta_model.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/repositories/receta_repository.dart';

class RecetaRepositoryImpl implements RecetaRepository {
  final RecetaRemoteDatasource remoteDataSource;

  RecetaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> emitirReceta(Receta receta) async {
    final model = RecetaModel.fromEntity(receta);
    final data = model.toJson();
    data['deleted_at'] = null;
    await remoteDataSource.crearReceta(data);
  }

  @override
  Future<void> editarReceta(Receta receta) async {
    final model = RecetaModel.fromEntity(receta);
    final data = model.toJson();
    data['updated_at'] = DateTime.now().toIso8601String();
    await remoteDataSource.actualizarReceta(data);
  }

  @override
  Future<void> cancelarReceta(String id) async {
    await remoteDataSource.anularReceta(id);
  }

  @override
  Future<List<Receta>> getHistorialRecetas(String pacienteId) async {
    final data = await remoteDataSource.fetchRecetasByPaciente(pacienteId);
    return data.map((json) => RecetaModel.fromJson(json)).toList();
  }
}
