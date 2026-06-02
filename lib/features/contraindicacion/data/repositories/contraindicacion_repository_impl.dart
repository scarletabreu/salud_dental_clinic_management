import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/contraindicacion.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/repositories/contraindicacion_repository.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/data/datasources/contraindicacion_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/data/models/contraindicacion_model.dart';

class ContraindicacionRepositoryImpl implements ContraindicacionRepository {
  final ContraindicacionRemoteDatasource remoteDataSource;

  ContraindicacionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Contraindicacion>> getContraindicacionesPorCondicion(
    String condicionId,
  ) async {
    try {
      final data = await remoteDataSource.fetchContraindicacionesByCondicion(
        condicionId,
      );
      return data.map((json) => ContraindicacionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception(
        'Error en el repositorio al obtener contraindicaciones: $e',
      );
    }
  }

  @override
  Future<void> guardarContraindicacion(
    Contraindicacion contraindicacion,
  ) async {
    try {
      final model = ContraindicacionModel(
        id: contraindicacion.id,
        condicionId: contraindicacion.condicionId,
        medicinaId: contraindicacion.medicinaId,
        contraindicacionId: contraindicacion.contraindicacionId,
        tratamientoId: contraindicacion.tratamientoId,
        descripcion: contraindicacion.descripcion,
        tipoContraindicacion: contraindicacion.tipoContraindicacion,
        efectosAdversos: contraindicacion.efectosAdversos,
      );
      await remoteDataSource.registrarContraindicacion(model.toJson());
    } catch (e) {
      throw Exception(
        'Error en el repositorio al guardar contraindicación: $e',
      );
    }
  }

  @override
  Future<void> eliminarContraindicacion(String id) async {
    try {
      await remoteDataSource.deleteContraindicacion(id);
    } catch (e) {
      throw Exception(
        'Error en el repositorio al eliminar contraindicación: $e',
      );
    }
  }
}
