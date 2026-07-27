import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/receta/data/datasources/receta_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/receta/data/models/receta_model.dart';
import 'package:salud_dental_clinic_management/features/receta/data/models/tem_receta_model.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/repositories/receta_repository.dart';

class RecetaRepositoryImpl implements RecetaRepository {
  final RecetaRemoteDatasource remoteDataSource;

  RecetaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<String> emitirReceta(Receta receta) {
    return runGuarded(() async {
      final model = RecetaModel.fromEntity(receta);
      final itemsModel = receta.items
          .map((i) => ItemRecetaModel.fromEntity(i))
          .toList();
      return await remoteDataSource.emitirRecetaCompleta(
        receta: model,
        items: itemsModel,
      );
    }, context: 'emitir la receta médica');
  }

  @override
  Future<void> reemitirRecetaModificada({
    required String recetaOriginalId,
    required String motivoReemplazo,
    required Receta nuevaReceta,
  }) {
    return runGuarded(() async {
      // 1. Marcar anterior como reemplazada
      await remoteDataSource.anularReceta(
        recetaId: recetaOriginalId,
        motivo: 'Reemplazada por nueva versión: $motivoReemplazo',
      );

      // 2. Emitir la nueva receta vinculada a la anterior
      final recetaConVinc = nuevaReceta.copyWith(
        recetaReemplazadaId: recetaOriginalId,
      );
      final model = RecetaModel.fromEntity(recetaConVinc);
      final itemsModel = nuevaReceta.items
          .map((i) => ItemRecetaModel.fromEntity(i))
          .toList();

      await remoteDataSource.emitirRecetaCompleta(
        receta: model,
        items: itemsModel,
      );
    }, context: 'reemitir versión corregida de la receta');
  }

  @override
  Future<void> anularReceta(String recetaId, String motivo) {
    return runGuarded(
      () => remoteDataSource.anularReceta(recetaId: recetaId, motivo: motivo),
      context: 'anular la receta médica',
    );
  }

  @override
  Future<List<Receta>> getHistorialRecetasPaciente(String pacienteId) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchRecetasByPaciente(pacienteId);
      return data.map((json) => RecetaModel.fromJson(json)).toList();
    }, context: 'cargar historial de recetas del paciente');
  }

  @override
  Future<List<Receta>> getRecetasConsulta(String consultaId) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchRecetasByConsulta(consultaId);
      return data.map((json) => RecetaModel.fromJson(json)).toList();
    }, context: 'cargar recetas de la consulta');
  }
}
