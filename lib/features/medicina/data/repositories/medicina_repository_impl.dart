import 'package:salud_dental_clinic_management/core/data/cache_catalogo.dart';
import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';
import '../datasources/medicina_remote_datasource.dart';
import '../models/medicina_model.dart';

class MedicinaRepositoryImpl implements IMedicinaRepository {
  static const _clave = 'medicinas';

  final MedicinaRemoteDatasource remoteDataSource;

  /// El catálogo se reutiliza entre pantallas. Vive aquí y no en cada widget
  /// porque lo piden cuatro sitios distintos —inicio, detalle de consulta,
  /// receta y el propio listado— y ninguno tiene por qué saber de los otros.
  final CacheCatalogo _cache;

  MedicinaRepositoryImpl({
    required this.remoteDataSource,
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
      final data = MedicinaModel.fromEntity(medicina).toJson();
      data['deleted_at'] = null;
      data['updated_at'] = DateTime.now().toIso8601String();
      await remoteDataSource.upsertMedicina(data);
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
