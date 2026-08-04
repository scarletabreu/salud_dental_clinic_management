import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/data/cache_catalogo.dart';
import 'package:salud_dental_clinic_management/core/realtime/senales_realtime.dart';
import 'package:salud_dental_clinic_management/features/consumible/data/datasources/consumible_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/consumible/data/repositories/consumible_repository_impl.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/entities/consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/enums/estado_consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/usecases/actualizar_existencia.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/usecases/eliminar_consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/usecases/get_inventario.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/usecases/guardar_consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/repositories/consumible_repository.dart';
import 'package:salud_dental_clinic_management/features/consumible/presentation/cubit/inventario_cubit.dart';
import 'package:salud_dental_clinic_management/features/consumible/presentation/cubit/inventario_state.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/entities/suplidor.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/repositories/suplidor_repository.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/usecases/get_directorio_suplidores.dart';

import '../../support/senales_de_prueba.dart';

/// MU-4 · El consumo silencioso de las consultas llega al inventario: la
/// señal invalida la caché del repositorio (la próxima lectura ve el stock
/// real) y la pantalla recarga conservando búsqueda y filtro.

Consumible _consumible(String nombre, int stock) => Consumible(
  id: 'con-$nombre',
  nombre: nombre,
  descripcion: '',
  precio: 100,
  stockActual: stock,
  stockMinimo: 2,
  estado: EstadoConsumible.disponible,
);

class _DatasourceFalso extends Fake implements ConsumibleRemoteDatasource {
  int lecturas = 0;
  List<Map<String, dynamic>> filas = [];

  @override
  Future<List<Map<String, dynamic>>> fetchConsumibles() async {
    lecturas++;
    return filas;
  }
}

class _ConsumibleRepoFalso extends Fake implements ConsumibleRepository {
  List<Consumible> inventario = [];

  @override
  Future<List<Consumible>> getInventario() async => List.of(inventario);
}

class _SuplidorRepoFalso extends Fake implements SuplidorRepository {
  @override
  Future<List<Suplidor>> getDirectorioSuplidores() async => const [];
}

Future<void> _asentar() =>
    Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  test('la señal invalida la caché: la próxima lectura va a la red', () async {
    final datasource = _DatasourceFalso();
    final fabrica = FabricaCanalesFalsa();
    final senales = SenalesRealtime(
      fabrica: fabrica,
      debounce: Duration.zero,
    );
    final repo = ConsumibleRepositoryImpl(
      remoteDataSource: datasource,
      cache: CacheCatalogo(vigencia: const Duration(hours: 1)),
      senales: senales,
    );

    await repo.getInventario();
    await repo.getInventario();
    expect(datasource.lecturas, 1, reason: 'la segunda lectura sale del caché');

    fabrica.cambios['consumibles']!();
    await _asentar();

    await repo.getInventario();
    expect(
      datasource.lecturas,
      2,
      reason: 'tras la señal, el caché quedó invalidado y se vuelve a la red',
    );
    await senales.detener();
  });

  test('la pantalla recarga con la señal y conserva búsqueda y filtro',
      () async {
    final repo = _ConsumibleRepoFalso()
      ..inventario = [_consumible('Guantes', 10), _consumible('Resina', 1)];
    final fabrica = FabricaCanalesFalsa();
    final cubit = InventarioCubit(
      getInventario: GetInventario(repo),
      guardarConsumible: GuardarConsumible(repo),
      actualizarExistencia: ActualizarExistencia(repo),
      eliminarConsumible: EliminarConsumible(repo),
      getDirectorioSuplidores: GetDirectorioSuplidores(_SuplidorRepoFalso()),
      senales: SenalesRealtime(fabrica: fabrica, debounce: Duration.zero),
    );

    await cubit.cargar();
    cubit.filtrarPorBusqueda('resina');
    cubit.toggleFiltroCriticos(true);

    // Una consulta ajena consume el último frasco de resina.
    repo.inventario = [_consumible('Guantes', 10), _consumible('Resina', 0)];
    fabrica.cambios['consumibles']!();
    await _asentar();

    final estado = cubit.state as InventarioLoaded;
    expect(estado.busqueda, 'resina');
    expect(estado.soloCriticos, isTrue);
    expect(
      estado.consumibles.firstWhere((c) => c.nombre == 'Resina').stockActual,
      0,
      reason: 'las existencias frescas llegan sin resetear la vista',
    );

    await cubit.close();
  });
}
