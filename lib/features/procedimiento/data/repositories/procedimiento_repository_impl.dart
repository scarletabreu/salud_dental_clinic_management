import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/contraindicacion.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/repositories/contraindicacion_repository.dart';
import 'package:salud_dental_clinic_management/features/procedimiento/data/datasources/procedimiento_remore_datasource.dart';
import 'package:salud_dental_clinic_management/features/procedimiento/data/models/procedimiento_model.dart';
import 'package:salud_dental_clinic_management/features/procedimiento/domain/entities/procedimiento.dart';
import 'package:salud_dental_clinic_management/features/procedimiento/domain/repositories/procedimiento_repository.dart';

class ProcedimientoRepositoryImpl implements ProcedimientoRepository {
  final ProcedimientoRemoteDatasource remoteDataSource;
  final ContraindicacionRepository contraindicacionRepository;

  ProcedimientoRepositoryImpl({
    required this.remoteDataSource,
    required this.contraindicacionRepository,
  });

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
      final model = ProcedimientoModel.fromEntity(procedimiento);
      final data = model.toJson();
      data['deleted_at'] = null;

      String procedimientoIdFinal;

      if (procedimiento.id != null &&
          procedimiento.id!.length == 36 &&
          procedimiento.id!.contains('-')) {
        await remoteDataSource.upsertProcedimiento(data);
        procedimientoIdFinal = procedimiento.id!;
      } else {
        final inserted = await remoteDataSource.insertProcedimiento(data);
        procedimientoIdFinal = inserted['id'] as String;
      }

      if (procedimiento.contraindicaciones.isNotEmpty) {
        for (final c in procedimiento.contraindicaciones) {
          final contraindicacionAjustada = Contraindicacion(
            id: (c.id != null && c.id!.length == 36 && c.id!.contains('-'))
                ? c.id
                : null,
            condicionId: c.condicionId,
            medicinaId: null,
            procedimientoId: procedimientoIdFinal,
            tratamientoId: null,
            descripcion: c.descripcion,
            tipoContraindicacion: c.tipoContraindicacion,
            efectosAdversos: c.efectosAdversos,
          );

          await contraindicacionRepository.guardarContraindicacion(
            contraindicacionAjustada,
          );
        }
      }
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
