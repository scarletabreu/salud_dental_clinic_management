import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/data/datasources/caja_diaria_datasource.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/data/repositories/caja_diaria_repository_impl.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/caja_diaria.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/repositories/caja_diaria_repository.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/presentation/cubit/caja_diaria_cubit.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/presentation/cubit/caja_diaria_state.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/entities/movimiento_caja.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/repositories/movimiento_caja_repository.dart';

/// Datasource en memoria: representa el estado real de la tabla `cajas`, no una
/// grabadora de llamadas. Así el test comprueba la regla de negocio (no puede
/// haber dos cajas abiertas) y no el orden en que se invocaron los métodos.
class _FakeDatasource implements CajaDiariaDatasource {
  @override
  Future<List<Map<String, dynamic>>> fetchCajasSinCerrarDeOtrosDias() async =>
      const [];

  _FakeDatasource({this.cajaAbierta});

  Map<String, dynamic>? cajaAbierta;
  final List<double> aperturas = [];
  final List<Map<String, dynamic>> cierres = [];
  Object? errorAlAbrir;

  @override
  Future<void> abrirCaja(double montoInicial) async {
    if (errorAlAbrir != null) throw errorAlAbrir!;
    aperturas.add(montoInicial);
    cajaAbierta = {
      'id': 'caja-1',
      'fecha': '2026-07-25T09:00:00.000Z',
      'monto_apertura': montoInicial,
      'monto_cierre': 0,
      'monto_esperado': montoInicial,
      'monto_real': 0,
      'cerrada': false,
    };
  }

  @override
  Future<bool> isCajaAbierta() async => cajaAbierta != null;

  @override
  Future<Map<String, dynamic>?> fetchCajaAbierta() async => cajaAbierta;

  @override
  Future<double> getBalanceActual() async =>
      (cajaAbierta?['monto_apertura'] as num?)?.toDouble() ?? 0;

  @override
  Future<void> cerrarCaja(Map<String, dynamic> datosCierre) async {
    cierres.add(datosCierre);
    cajaAbierta = null;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMovimientosDelDia() async => [];

  @override
  Future<void> registrarMovimiento(Map<String, dynamic> movimientoData) async {}

  @override
  Stream<List<Map<String, dynamic>>> watchMovimientos(String cajaDiariaId) =>
      const Stream.empty();
}

class _FakeCajaRepository implements CajaDiariaRepository {
  @override
  Future<List<CajaDiaria>> getCajasSinCerrarDeOtrosDias() async => const [];

  CajaDiaria? caja;
  final movimientos = StreamController<List<MovimientoCaja>>.broadcast();
  final List<double> aperturas = [];
  bool fallaAlAbrir = false;

  @override
  Future<void> abrirCaja(double montoApertura) async {
    if (fallaAlAbrir) throw Exception('sin conexión');
    aperturas.add(montoApertura);
    caja = CajaDiaria(
      id: 'caja-1',
      fecha: DateTime(2026, 7, 25),
      montoApertura: montoApertura,
      montoCierre: 0,
      montoEsperado: montoApertura,
      montoReal: 0,
    );
  }

  @override
  Future<void> cerrarCaja({
    required double montoReal,
    required double montoCierre,
    String? observaciones,
  }) async {
    caja = null;
  }

  @override
  Future<CajaDiaria?> getCajaActual() async => caja;

  @override
  Future<double> getMontoEsperado() async => caja?.montoApertura ?? 0;

  @override
  Future<bool> isCajaAbierta() async => caja != null;

  @override
  Stream<List<MovimientoCaja>> watchMovimientos(String cajaDiariaId) =>
      movimientos.stream;
}

class _MovimientoRepositoryFake implements MovimientoCajaRepository {
  @override
  Future<void> crearMovimiento(MovimientoCaja movimiento) async {}

  @override
  Future<List<MovimientoCaja>> getMovimientosDeHoy(String cajaDiariaId) async =>
      [];
}

void main() {
  group('CajaDiariaRepositoryImpl.abrirCaja', () {
    test('abre la caja cuando no hay ninguna abierta', () async {
      final datasource = _FakeDatasource();
      final repositorio = CajaDiariaRepositoryImpl(datasource);

      await repositorio.abrirCaja(5000);

      expect(datasource.aperturas, [5000]);
      expect(await repositorio.isCajaAbierta(), isTrue);
    });

    test('rechaza la segunda apertura mientras haya una caja abierta', () async {
      final datasource = _FakeDatasource();
      final repositorio = CajaDiariaRepositoryImpl(datasource);
      await repositorio.abrirCaja(5000);

      await expectLater(
        repositorio.abrirCaja(3000),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'mensaje',
            contains('Ya existe una caja abierta'),
          ),
        ),
      );

      // Lo importante no es el mensaje sino que la segunda apertura nunca
      // llegó a la base: dos cajas abiertas partirían la contabilidad del día.
      expect(datasource.aperturas, [5000]);
    });

    test(
      'rechaza la apertura si la caja abierta la dejó otro usuario',
      () async {
        final datasource = _FakeDatasource(
          cajaAbierta: {
            'id': 'caja-de-la-mañana',
            'fecha': '2026-07-25T08:00:00.000Z',
            'monto_apertura': 2000,
            'monto_cierre': 0,
            'monto_esperado': 2000,
            'monto_real': 0,
            'cerrada': false,
          },
        );
        final repositorio = CajaDiariaRepositoryImpl(datasource);

        await expectLater(repositorio.abrirCaja(5000), throwsA(isA<Exception>()));
        expect(datasource.aperturas, isEmpty);
      },
    );

    test('permite reabrir después de cerrar la caja del día', () async {
      final datasource = _FakeDatasource();
      final repositorio = CajaDiariaRepositoryImpl(datasource);

      await repositorio.abrirCaja(5000);
      await repositorio.cerrarCaja(montoReal: 5000, montoCierre: 5000);
      await repositorio.abrirCaja(1500);

      expect(datasource.aperturas, [5000, 1500]);
    });
  });

  group('CajaDiariaCubit.abrirCaja', () {
    test('rechaza un monto de apertura negativo sin tocar el repositorio', () async {
      final repositorio = _FakeCajaRepository();
      final cubit = CajaDiariaCubit(repositorio, _MovimientoRepositoryFake());

      final error = await cubit.abrirCaja(-1);

      expect(error, 'El monto inicial no puede ser negativo.');
      expect(repositorio.aperturas, isEmpty);
      await cubit.close();
      await repositorio.movimientos.close();
    });

    test('acepta abrir en cero (caja sin fondo inicial)', () async {
      final repositorio = _FakeCajaRepository();
      final cubit = CajaDiariaCubit(repositorio, _MovimientoRepositoryFake());

      expect(await cubit.abrirCaja(0), isNull);
      expect(repositorio.aperturas, [0]);
      expect(cubit.state, isA<CajaDiariaAbierta>());
      expect((cubit.state as CajaDiariaAbierta).montoEsperado, 0);

      await cubit.close();
      await repositorio.movimientos.close();
    });

    test('abre la caja y deja el estado en abierta', () async {
      final repositorio = _FakeCajaRepository();
      final cubit = CajaDiariaCubit(repositorio, _MovimientoRepositoryFake());

      expect(await cubit.abrirCaja(5000), isNull);

      final estado = cubit.state;
      expect(estado, isA<CajaDiariaAbierta>());
      expect((estado as CajaDiariaAbierta).caja.montoApertura, 5000);

      await cubit.close();
      await repositorio.movimientos.close();
    });

    test('un fallo al abrir devuelve error y deja el estado sin abrir', () async {
      final repositorio = _FakeCajaRepository()..fallaAlAbrir = true;
      final cubit = CajaDiariaCubit(repositorio, _MovimientoRepositoryFake());

      final error = await cubit.abrirCaja(5000);

      expect(error, isNotNull);
      expect(cubit.state, isA<CajaDiariaSinAbrir>());
      expect((cubit.state as CajaDiariaSinAbrir).error, isNotNull);

      await cubit.close();
      await repositorio.movimientos.close();
    });
  });
}
