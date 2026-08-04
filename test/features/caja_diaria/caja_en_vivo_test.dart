import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/realtime/senales_realtime.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/caja_diaria.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/repositories/caja_diaria_repository.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/presentation/cubit/caja_diaria_cubit.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/presentation/cubit/caja_diaria_state.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/entities/movimiento_caja.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/repositories/movimiento_caja_repository.dart';

import '../../support/senales_de_prueba.dart';

/// MU-2 · El sobre de la caja también viaja entre sesiones: la apertura y el
/// cierre hechos en otra pantalla llegan por la señal de `cajas`, sin pasar
/// por `Loading` (nada parpadea) y sin degradar lo mostrado si el refresh
/// falla.

class _MovimientoRepositoryFake implements MovimientoCajaRepository {
  @override
  Future<void> crearMovimiento(MovimientoCaja movimiento) async {}

  @override
  Future<List<MovimientoCaja>> getMovimientosDeHoy(String cajaDiariaId) async =>
      [];
}

class _CajaRepositoryFake extends Fake implements CajaDiariaRepository {
  CajaDiaria? caja;
  final movimientos = StreamController<List<MovimientoCaja>>.broadcast();
  Object? error;

  @override
  Future<CajaDiaria?> getCajaActual() async {
    final e = error;
    if (e != null) throw e;
    return caja;
  }

  @override
  Future<List<CajaDiaria>> getCajasSinCerrarDeOtrosDias() async => const [];

  @override
  Stream<List<MovimientoCaja>> watchMovimientos(String cajaDiariaId) =>
      movimientos.stream;
}

CajaDiaria _caja() => CajaDiaria(
  id: 'caja-1',
  fecha: DateTime(2026, 8, 4),
  montoApertura: 5000,
  montoCierre: 0,
  montoEsperado: 5000,
  montoReal: 0,
);

Future<void> _asentar() =>
    Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  late _CajaRepositoryFake repo;
  late FabricaCanalesFalsa fabrica;
  late CajaDiariaCubit cubit;

  setUp(() {
    repo = _CajaRepositoryFake();
    fabrica = FabricaCanalesFalsa();
    cubit = CajaDiariaCubit(
      repo,
      _MovimientoRepositoryFake(),
      senales: SenalesRealtime(fabrica: fabrica, debounce: Duration.zero),
    );
  });

  tearDown(() async {
    await cubit.close();
    await repo.movimientos.close();
  });

  test('la apertura ajena pasa la pantalla de «sin abrir» a abierta', () async {
    await cubit.cargar();
    expect(cubit.state, isA<CajaDiariaSinAbrir>());

    final estados = <CajaDiariaState>[];
    final sub = cubit.stream.listen(estados.add);

    repo.caja = _caja();
    fabrica.cambios['cajas']!();
    await _asentar();

    expect(cubit.state, isA<CajaDiariaAbierta>());
    expect(
      estados.whereType<CajaDiariaLoading>(),
      isEmpty,
      reason: 'el refresh por señal no debe hacer parpadear la pantalla',
    );
    await sub.cancel();
  });

  test('el cierre ajeno se propaga a quien tenía la caja abierta', () async {
    repo.caja = _caja();
    await cubit.cargar();
    expect(cubit.state, isA<CajaDiariaAbierta>());

    repo.caja = null; // la caja de hoy quedó cerrada en otra sesión
    fabrica.cambios['cajas']!();
    await _asentar();

    expect(cubit.state, isA<CajaDiariaSinAbrir>());
  });

  test('si el refresh por señal falla, se conserva lo mostrado', () async {
    repo.caja = _caja();
    await cubit.cargar();
    expect(cubit.state, isA<CajaDiariaAbierta>());

    repo.error = Exception('se fue la red');
    fabrica.cambios['cajas']!();
    await _asentar();

    expect(
      cubit.state,
      isA<CajaDiariaAbierta>(),
      reason: 'la señal no puede degradar una pantalla que ya muestra datos',
    );
  });
}
