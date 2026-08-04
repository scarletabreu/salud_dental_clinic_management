import 'package:salud_dental_clinic_management/core/data/cache_catalogo.dart';
import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/core/realtime/senales_realtime.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/entities/consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/enums/motivo_ajuste_stock.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/repositories/consumible_repository.dart';
import 'package:salud_dental_clinic_management/features/consumible/data/datasources/consumible_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/consumible/data/models/consumible_model.dart';

class ConsumibleRepositoryImpl implements ConsumibleRepository {
  static const _clave = 'inventario';

  final ConsumibleRemoteDatasource remoteDataSource;

  /// El inventario lo piden el inicio, la sección de insumos de la consulta y
  /// el propio listado. Se comparte aquí en vez de que cada uno lo baje.
  ///
  /// La vigencia es corta y toda escritura lo invalida porque el stock sí
  /// cambia dentro de una sesión: servir existencias viejas llevaría a
  /// descontar sobre un número que ya no es cierto.
  final CacheCatalogo _cache;

  ConsumibleRepositoryImpl({
    required this.remoteDataSource,
    CacheCatalogo? cache,
    SenalesRealtime? senales,
  }) : _cache = cache ?? CacheCatalogo() {
    // El consumo de las consultas ajenas también invalida la copia local
    // (MU-4): la próxima pantalla que pida el inventario —incluida la sección
    // de insumos de una consulta— ve el stock real sin esperar la vigencia.
    senales
        ?.de(DominioSenal.inventario)
        .listen((_) => _cache.invalidar(_clave));
  }

  @override
  Future<List<Consumible>> getInventario() {
    return _cache.obtener(
      _clave,
      () => runGuarded(() async {
        final data = await remoteDataSource.fetchConsumibles();
        return data.map((json) => ConsumibleModel.fromJson(json)).toList();
      }, context: 'obtener el inventario'),
    );
  }

  @override
  Future<void> ajustarStock(
    String id,
    int nuevoStock,
    MotivoAjusteStock motivo,
  ) {
    if (nuevoStock < 0) {
      throw ArgumentError.value(
        nuevoStock,
        'nuevoStock',
        'No puede ser negativo',
      );
    }
    return runGuarded(() async {
      await remoteDataSource.adjustStock(id, nuevoStock, motivo.dbValue);
      _cache.invalidar(_clave);
    }, context: 'actualizar la existencia');
  }

  @override
  Future<void> guardarConsumible(Consumible consumible) {
    return runGuarded(() async {
      final model = ConsumibleModel(
        id: consumible.id,
        nombre: consumible.nombre,
        descripcion: consumible.descripcion,
        precio: consumible.precio,
        stockActual: consumible.stockActual,
        stockMinimo: consumible.stockMinimo,
        estado: consumible.estadoCalculado,
        suplidorId: consumible.suplidorId,
        suplidorNombre: consumible.suplidorNombre,
        activo: consumible.activo,
      );

      // El alta puede fijar el stock inicial; la edición no toca el stock ni su
      // estado derivado, que sólo se mueven por `ajustar_stock_consumible`.
      if (consumible.id == null) {
        await remoteDataSource.createConsumible(model.toJson());
      } else {
        await remoteDataSource.updateConsumible(
          consumible.id!,
          model.toUpdateJson(),
        );
      }
      _cache.invalidar(_clave);
    }, context: 'guardar el consumible');
  }

  @override
  Future<void> eliminarConsumible(String id) {
    return runGuarded(() async {
      await remoteDataSource.deleteConsumible(id);
      _cache.invalidar(_clave);
    }, context: 'eliminar el consumible');
  }
}
