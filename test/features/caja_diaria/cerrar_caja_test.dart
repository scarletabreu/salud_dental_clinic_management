import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/data/datasources/caja_diaria_datasource.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/data/repositories/caja_diaria_repository_impl.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/balance_caja.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/caja_diaria.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/repositories/caja_diaria_repository.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/presentation/cubit/caja_diaria_cubit.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/presentation/cubit/caja_diaria_state.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/entities/movimiento_caja.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/enums/tipo_movimiento.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/repositories/movimiento_caja_repository.dart';

/// Un día de caja realista de la clínica: apertura, cobros y gastos menores.
/// Es el mismo día que reproduce `supabase/seed.sql`, para que el cuadre que
/// verifican estas pruebas y el que se ve en la app sean el mismo número.
const _montoApertura = 5000.0;

final _movimientosDelDia = <Map<String, dynamic>>[
  _mov('ingreso', 3500, 'Cobro consulta y profilaxis'),
  _mov('egreso', 1250.50, 'Compra de insumos de esterilización'),
  _mov('ingreso', 18500, 'Cobro endodoncia multirradicular'),
  _mov('egreso', 800, 'Pago de mensajería'),
  _mov('ingreso', 2400.25, 'Abono a plan de cuotas'),
];

// 5000 + (3500 + 18500 + 2400.25) - (1250.50 + 800) = 27349.75
const _esperadoDelDia = 27349.75;

Map<String, dynamic> _mov(String tipo, num monto, String descripcion) => {
  'id': 'mov-${descripcion.hashCode}',
  'caja_diaria_id': 'caja-1',
  'tipo': tipo,
  'monto': monto,
  'descripcion': descripcion,
  'fecha': '2026-07-25T12:00:00.000Z',
};

MovimientoCaja _entidad(Map<String, dynamic> json) => MovimientoCaja(
  cajaDiariaId: json['caja_diaria_id'] as String,
  tipo: json['tipo'] == 'ingreso'
      ? TipoMovimiento.ingreso
      : TipoMovimiento.egreso,
  monto: (json['monto'] as num).toDouble(),
  descripcion: json['descripcion'] as String,
  fecha: DateTime.parse(json['fecha'] as String),
);

class _FakeDatasource implements CajaDiariaDatasource {
  @override
  Future<List<Map<String, dynamic>>> fetchCajasSinCerrarDeOtrosDias() async =>
      const [];

  _FakeDatasource({
    List<Map<String, dynamic>>? movimientos,
    this.hayCajaAbierta = true,
  }) : movimientos = movimientos ?? List.of(_movimientosDelDia);

  final double montoApertura = _montoApertura;
  final List<Map<String, dynamic>> movimientos;
  bool hayCajaAbierta;
  final List<Map<String, dynamic>> cierres = [];

  @override
  Future<Map<String, dynamic>?> fetchCajaAbierta() async => hayCajaAbierta
      ? {
          'id': 'caja-1',
          'fecha': '2026-07-25T09:00:00.000Z',
          'monto_apertura': montoApertura,
          'monto_cierre': 0,
          'monto_esperado': montoApertura,
          'monto_real': 0,
          'cerrada': false,
        }
      : null;

  @override
  Future<bool> isCajaAbierta() async => hayCajaAbierta;

  @override
  Future<List<Map<String, dynamic>>> fetchMovimientosDelDia() async =>
      hayCajaAbierta ? movimientos : [];

  /// Réplica del cálculo del datasource real: apertura + ingresos - egresos
  /// sobre los movimientos vivos.
  @override
  Future<double> getBalanceActual() async {
    if (!hayCajaAbierta) return 0;
    return BalanceCaja.esperado(
      montoApertura: montoApertura,
      movimientos: movimientos.map(_entidad),
    );
  }

  @override
  Future<void> cerrarCaja(Map<String, dynamic> datosCierre) async {
    if (!hayCajaAbierta) throw Exception('No hay caja abierta para cerrar.');
    cierres.add(datosCierre);
    hayCajaAbierta = false;
  }

  @override
  Future<void> abrirCaja(double montoInicial) async => hayCajaAbierta = true;

  @override
  Future<void> registrarMovimiento(Map<String, dynamic> movimientoData) async {}

  @override
  Stream<List<Map<String, dynamic>>> watchMovimientos(String cajaDiariaId) =>
      const Stream.empty();
}

class _FakeCajaRepository implements CajaDiariaRepository {
  @override
  Future<List<CajaDiaria>> getCajasSinCerrarDeOtrosDias() async => const [];

  _FakeCajaRepository({this.caja});

  CajaDiaria? caja;
  final movimientos = StreamController<List<MovimientoCaja>>.broadcast();
  final List<Map<String, double>> cierres = [];
  bool fallaAlCerrar = false;

  @override
  Future<void> cerrarCaja({
    required double montoReal,
    required double montoCierre,
    String? observaciones,
  }) async {
    if (fallaAlCerrar) throw Exception('la caja ya fue cerrada');
    cierres.add({'montoReal': montoReal, 'montoCierre': montoCierre});
    caja = null;
  }

  @override
  Future<void> abrirCaja(double montoApertura) async {}

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

CajaDiaria _cajaAbierta() => CajaDiaria(
  id: 'caja-1',
  fecha: DateTime(2026, 7, 25),
  montoApertura: _montoApertura,
  montoCierre: 0,
  montoEsperado: _montoApertura,
  montoReal: 0,
);

void main() {
  // `runGuarded` consulta un check de conectividad global; si otra suite lo
  // dejó puesto, estos tests fallarían por una razón ajena al cierre.
  setUp(() => guardConnectivityCheck = null);

  group('CajaDiariaRepositoryImpl.cerrarCaja', () {
    test('calcula el esperado con ingresos y egresos mixtos', () async {
      final datasource = _FakeDatasource();
      final repositorio = CajaDiariaRepositoryImpl(datasource);

      await repositorio.cerrarCaja(
        montoReal: _esperadoDelDia,
        montoCierre: _esperadoDelDia,
      );

      expect(datasource.cierres, hasLength(1));
      expect(datasource.cierres.single['monto_esperado'], _esperadoDelDia);
      expect(datasource.cierres.single['monto_real'], _esperadoDelDia);
    });

    test('el esperado sale de los movimientos, no del monto que envía la app', () async {
      final datasource = _FakeDatasource();
      final repositorio = CajaDiariaRepositoryImpl(datasource);

      // El cajero cuenta 27000 en la gaveta: eso es el real, nunca el esperado.
      await repositorio.cerrarCaja(montoReal: 27000, montoCierre: 27000);

      expect(datasource.cierres.single['monto_esperado'], _esperadoDelDia);
      expect(datasource.cierres.single['monto_real'], 27000);
    });

    test('un cobro que entra mientras se cuenta el efectivo mueve el esperado', () async {
      final datasource = _FakeDatasource();
      final repositorio = CajaDiariaRepositoryImpl(datasource);

      datasource.movimientos.add(_mov('ingreso', 1000, 'Cobro de última hora'));
      await repositorio.cerrarCaja(montoReal: 27000, montoCierre: 27000);

      expect(
        datasource.cierres.single['monto_esperado'],
        _esperadoDelDia + 1000,
      );
    });

    test('registra una observación por defecto cuando no se envía', () async {
      final datasource = _FakeDatasource();
      final repositorio = CajaDiariaRepositoryImpl(datasource);

      await repositorio.cerrarCaja(montoReal: 100, montoCierre: 100);

      expect(datasource.cierres.single['observaciones'], isNotNull);
    });

    test('propaga la observación del cajero', () async {
      final datasource = _FakeDatasource();
      final repositorio = CajaDiariaRepositoryImpl(datasource);

      await repositorio.cerrarCaja(
        montoReal: 100,
        montoCierre: 100,
        observaciones: 'Faltan RD\$ 350, se revisa mañana',
      );

      expect(
        datasource.cierres.single['observaciones'],
        'Faltan RD\$ 350, se revisa mañana',
      );
    });

    test('cerrar sin caja abierta falla y no persiste nada', () async {
      final datasource = _FakeDatasource(hayCajaAbierta: false);
      final repositorio = CajaDiariaRepositoryImpl(datasource);

      await expectLater(
        repositorio.cerrarCaja(montoReal: 100, montoCierre: 100),
        throwsA(isA<Exception>()),
      );
      expect(datasource.cierres, isEmpty);
    });

    test('el balance de una caja sin movimientos es su apertura', () async {
      final datasource = _FakeDatasource(movimientos: []);
      final repositorio = CajaDiariaRepositoryImpl(datasource);

      expect(await repositorio.getMontoEsperado(), _montoApertura);
    });
  });

  group('CajaDiariaCubit — cuadre del día', () {
    test('el esperado en pantalla coincide con el del cierre', () async {
      final repositorio = _FakeCajaRepository(caja: _cajaAbierta());
      final cubit = CajaDiariaCubit(repositorio, _MovimientoRepositoryFake());
      await cubit.cargar();

      repositorio.movimientos.add(_movimientosDelDia.map(_entidad).toList());
      await Future<void>.delayed(Duration.zero);

      final estado = cubit.state as CajaDiariaAbierta;
      expect(estado.ingresos, 24400.25);
      expect(estado.egresos, 2050.50);
      expect(estado.montoEsperado, _esperadoDelDia);

      final resumen = cubit.obtenerResumenCierre()!;
      expect(resumen.totalIngresos, 24400.25);
      expect(resumen.totalEgresos, 2050.50);
      expect(resumen.montoEsperado, _esperadoDelDia);
      expect(resumen.movimientos, hasLength(5));

      await cubit.close();
      await repositorio.movimientos.close();
    });

    test('un faltante se refleja en la diferencia del cierre', () async {
      final repositorio = _FakeCajaRepository(caja: _cajaAbierta());
      final cubit = CajaDiariaCubit(repositorio, _MovimientoRepositoryFake());
      await cubit.cargar();

      repositorio.movimientos.add(_movimientosDelDia.map(_entidad).toList());
      await Future<void>.delayed(Duration.zero);

      final esperado = (cubit.state as CajaDiariaAbierta).montoEsperado;
      const contado = 27000.0;

      expect(
        BalanceCaja.diferencia(montoReal: contado, montoEsperado: esperado),
        closeTo(-349.75, 0.001),
      );

      await cubit.close();
      await repositorio.movimientos.close();
    });

    test('cerrar deja el estado sin caja abierta', () async {
      final repositorio = _FakeCajaRepository(caja: _cajaAbierta());
      final cubit = CajaDiariaCubit(repositorio, _MovimientoRepositoryFake());
      await cubit.cargar();

      final error = await cubit.cerrarCaja(montoReal: 27349.75);

      expect(error, isNull);
      expect(repositorio.cierres.single['montoReal'], 27349.75);
      // El monto de cierre replica el contado: la gaveta queda con lo contado.
      expect(repositorio.cierres.single['montoCierre'], 27349.75);
      expect(
        cubit.state,
        isA<CajaDiariaSinAbrir>(),
        reason: 'tras cerrar no puede seguir ofreciendo registrar movimientos',
      );

      await cubit.close();
      await repositorio.movimientos.close();
    });

    test('no cierra si no hay caja abierta', () async {
      final repositorio = _FakeCajaRepository();
      final cubit = CajaDiariaCubit(repositorio, _MovimientoRepositoryFake());
      await cubit.cargar();

      expect(await cubit.cerrarCaja(montoReal: 100), isNotNull);
      expect(repositorio.cierres, isEmpty);

      await cubit.close();
      await repositorio.movimientos.close();
    });

    test('rechaza un monto contado negativo', () async {
      final repositorio = _FakeCajaRepository(caja: _cajaAbierta());
      final cubit = CajaDiariaCubit(repositorio, _MovimientoRepositoryFake());
      await cubit.cargar();

      expect(await cubit.cerrarCaja(montoReal: -1), isNotNull);
      expect(repositorio.cierres, isEmpty);

      await cubit.close();
      await repositorio.movimientos.close();
    });

    test('un fallo al cerrar devuelve error y no deja la caja como cerrada', () async {
      final repositorio = _FakeCajaRepository(caja: _cajaAbierta())
        ..fallaAlCerrar = true;
      final cubit = CajaDiariaCubit(repositorio, _MovimientoRepositoryFake());
      await cubit.cargar();

      expect(await cubit.cerrarCaja(montoReal: 100), isNotNull);
      expect(cubit.state, isA<CajaDiariaAbierta>());

      await cubit.close();
      await repositorio.movimientos.close();
    });

    test('un egreso no puede vaciar la caja más allá del esperado', () async {
      final repositorio = _FakeCajaRepository(caja: _cajaAbierta());
      final cubit = CajaDiariaCubit(repositorio, _MovimientoRepositoryFake());
      await cubit.cargar();

      final error = await cubit.registrarEgreso(
        monto: _montoApertura + 1,
        descripcion: 'Gasto imposible',
      );

      expect(error, contains('supera el dinero esperado'));

      await cubit.close();
      await repositorio.movimientos.close();
    });
  });
}
