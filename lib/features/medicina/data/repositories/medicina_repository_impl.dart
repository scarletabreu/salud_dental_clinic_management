import 'package:salud_dental_clinic_management/core/data/cache_catalogo.dart';
import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/contraindicacion.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/repositories/contraindicacion_repository.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';
import '../datasources/medicina_remote_datasource.dart';
import '../models/medicina_model.dart';

class MedicinaRepositoryImpl implements IMedicinaRepository {
  static const _clave = 'medicinas';

  final MedicinaRemoteDatasource remoteDataSource;
  final ContraindicacionRepository contraindicacionRepository;

  final CacheCatalogo _cache;

  MedicinaRepositoryImpl({
    required this.remoteDataSource,
    required this.contraindicacionRepository,
    CacheCatalogo? cache,
  }) : _cache = cache ?? CacheCatalogo();

  @override
  Future<List<Medicina>> getCatalogoMedicinas() {
    return _cache.obtener(
      _clave,
      () => runGuarded(() async {
        final data = await remoteDataSource.fetchMedicinas();
        return data.map((json) => MedicinaModel.fromJson(json)).toList();
      }, context: 'obtener el catálogo de medicinas'),
    );
  }

  @override
  Future<void> agregarMedicina(Medicina medicina) async {
    await guardarMedicina(medicina);
  }

  @override
  Future<void> guardarMedicina(Medicina medicina) {
    return runGuarded(() async {
      final model = MedicinaModel.fromEntity(medicina);
      final data = model.toJson();

      String medicinaIdFinal;

      if (medicina.id != null &&
          medicina.id!.isNotEmpty &&
          medicina.id!.length == 36 &&
          medicina.id!.contains('-')) {
        data['updated_at'] = DateTime.now().toIso8601String();
        await remoteDataSource.upsertMedicina(data);
        medicinaIdFinal = medicina.id!;
      } else {
        final insertedMap = await remoteDataSource.insertMedicina(data);
        medicinaIdFinal = insertedMap['id'] as String;
      }

      if (medicina.contraindicaciones.isNotEmpty) {
        for (final c in medicina.contraindicaciones) {
          final contraindicacionAjustada = Contraindicacion(
            id: (c.id != null && c.id!.length == 36 && c.id!.contains('-'))
                ? c.id
                : null,
            condicionId: c.condicionId,
            medicinaId: medicinaIdFinal,
            procedimientoId: null,
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

      _cache.invalidar(_clave);
    }, context: 'guardar la medicina');
  }

  @override
  Future<void> eliminarMedicina(String id) {
    return runGuarded(() async {
      await remoteDataSource.softDeleteMedicina(id);
      _cache.invalidar(_clave);
    }, context: 'eliminar la medicina');
  }
}
