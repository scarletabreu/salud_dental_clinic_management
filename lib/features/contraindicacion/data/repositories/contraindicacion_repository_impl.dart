import 'package:salud_dental_clinic_management/core/errors/guard.dart';
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
  ) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchContraindicacionesByCondicion(
        condicionId,
      );
      return data.map((json) => ContraindicacionModel.fromJson(json)).toList();
    }, context: 'obtener las contraindicaciones');
  }

  @override
  Future<List<Contraindicacion>> getContraindicacionesPorProcedimiento(
    String procedimientoId,
  ) {
    return runGuarded(() async {
      final data = await remoteDataSource
          .fetchContraindicacionesByProcedimiento(procedimientoId);
      return data.map((json) => ContraindicacionModel.fromJson(json)).toList();
    }, context: 'obtener las contraindicaciones');
  }

  @override
  Future<List<Contraindicacion>> getContraindicacionesPorTratamiento(
    String tratamientoId,
  ) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchContraindicacionesByTratamiento(
        tratamientoId,
      );
      return data.map((json) => ContraindicacionModel.fromJson(json)).toList();
    }, context: 'obtener las contraindicaciones');
  }

  @override
  Future<List<Contraindicacion>> getContraindicacionesPorMedicina(
    String medicinaId,
  ) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchContraindicacionesByMedicina(
        medicinaId,
      );
      return data.map((json) => ContraindicacionModel.fromJson(json)).toList();
    }, context: 'obtener las contraindicaciones');
  }

  @override
  Future<void> guardarContraindicacion(Contraindicacion contraindicacion) {
    return runGuarded(() async {
      final model = ContraindicacionModel(
        id: contraindicacion.id,
        condicionId: contraindicacion.condicionId,
        medicinaId: contraindicacion.medicinaId,
        procedimientoId: contraindicacion.procedimientoId,
        tratamientoId: contraindicacion.tratamientoId,
        descripcion: contraindicacion.descripcion,
        tipoContraindicacion: contraindicacion.tipoContraindicacion,
        efectosAdversos: contraindicacion.efectosAdversos,
      );
      await remoteDataSource.registrarContraindicacion(model.toJson());
    }, context: 'guardar la contraindicación');
  }

  @override
  Future<void> eliminarContraindicacion(String id) {
    return runGuarded(
      () => remoteDataSource.deleteContraindicacion(id),
      context: 'eliminar la contraindicación',
    );
  }
}
