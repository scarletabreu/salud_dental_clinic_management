import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/data/datasources/caja_diaria_datasource.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/data/repositories/caja_diaria_repository_impl.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/balance_caja.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/arqueo_pendiente.dart';
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

/// El arqueo que nadie cuadró: 3000 de apertura, 7200 cobrados y 900 gastados.
/// Es el mismo día que siembra `supabase/seed.sql`.
const _idArqueoViejo = 'caja-anteayer';
const _aperturaArqueoViejo = 3000.0;
const _esperadoArqueoViejo = 9300.0;

Map<String, dynamic> _cajaJson(
  String id,
  String fecha,
  double apertura,
) => {
  'id': id,
  'fecha': fecha,
  'monto_apertura': apertura,
  'monto_cierre': 0,
  'monto_esperado': apertura,
  'monto_real': 0,
  'cerrada': false,
};

List<Map<String, dynamic>> _movimientosArqueoViejo() => [
  _movDe(_idArqueoViejo, 'ingreso', 5200, 'Cobro de dos resinas'),
  _movDe(_idArqueoViejo, 'ingreso', 2000, 'Abono a plan de cuotas'),
  _movDe(_idArqueoViejo, 'egreso', 900, 'Compra de guantes y gasas'),
];

Map<String, dynamic> _movDe(
  String cajaId,
  String tipo,
  num monto,
  String descripcion,
) => {
  'id': 'mov-${cajaId.hashCode ^ descripcion.hashCode}',
  'caja_diaria_id': cajaId,
  'tipo': tipo,
  'monto': monto,
  'descripcion': descripcion,
  'fecha': '2026-07-23T12:00:00.000Z',
};

class _FakeDatasource implements CajaDiariaDatasource {
  _FakeDatasource({
    List<Map<String, dynamic>>? movimientos,
    this.hayCajaAbierta = true,
    Map<String, Map<String, dynamic>>? pendientes,
    Map<String, List<Map<String, dynamic>>>? movimientosPendientes,
  }) : movimientos = movimientos ?? List.of(_movimientosDelDia),
       pendientes = pendientes ?? {},
       movimientosPendientes = movimientosPendientes ?? {};

  /// Un arqueo de anteayer sin cuadrar, además de la caja de hoy.
  factory _FakeDatasource.conArqueoPendiente() => _FakeDatasource(
    pendientes: {
      _idArqueoViejo: _cajaJson(
        _idArqueoViejo,
        '2026-07-23T08:30:00.000Z',
        _aperturaArqueoViejo,
      ),
    },
    movimientosPendientes: {_idArqueoViejo: _movimientosArqueoViejo()},
  );

  final double montoApertura = _montoApertura;
  final List<Map<String, dynamic>> movimientos;
  bool hayCajaAbierta;

  /// Cajas de días anteriores todavía abiertas, por id.
  final Map<String, Map<String, dynamic>> pendientes;
  final Map<String, List<Map<String, dynamic>>> movimientosPendientes;

  /// Cada cierre persistido, con el id de la caja a la que se aplicó.
  final List<Map<String, dynamic>> cierres = [];
  final List<String> cerradas = [];

  @override
  Future<Map<String, dynamic>?> fetchCajaAbierta() async => hayCajaAbierta
      ? _cajaJson('caja-1', '2026-07-25T09:00:00.000Z', montoApertura)
      : null;

  @override
  Future<bool> isCajaAbierta() async => hayCajaAbierta;

  @override
  Future<List<Map<String, dynamic>>> fetchCajasSinCerrarDeOtrosDias() async =>
      pendientes.values.toList();

  @override
  Future<List<Map<String, dynamic>>> fetchMovimientosDelDia() async =>
      hayCajaAbierta ? movimientos : [];

  @override
  Future<List<Map<String, dynamic>>> fetchMovimientosDeCaja(
    String cajaId,
  ) async {
    if (cajaId == 'caja-1') return hayCajaAbierta ? movimientos : const [];
    return movimientosPendientes[cajaId] ?? const [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMovimientosDeCajas(
    List<String> cajaIds,
  ) async => [
    for (final id in cajaIds) ...await fetchMovimientosDeCaja(id),
  ];

  /// Réplica del cálculo del datasource real: apertura + ingresos - egresos
  /// sobre los movimientos vivos de esa caja.
  @override
  Future<double> getBalanceActual() async {
    if (!hayCajaAbierta) return 0;
    return getBalanceDeCaja('caja-1');
  }

  @override
  Future<double> getBalanceDeCaja(String cajaId) async {
    final caja = cajaId == 'caja-1'
        ? await fetchCajaAbierta()
        : pendientes[cajaId];
    if (caja == null) throw Exception('La caja indicada ya no existe.');

    return BalanceCaja.esperado(
      montoApertura: (caja['monto_apertura'] as num).toDouble(),
      movimientos: (await fetchMovimientosDeCaja(cajaId)).map(_entidad),
    );
  }

  @override
  Future<void> cerrarCaja(Map<String, dynamic> datosCierre) async {
    if (!hayCajaAbierta) throw Exception('No hay caja abierta para cerrar.');
    await cerrarCajaPorId('caja-1', datosCierre);
  }

  @override
  Future<void> cerrarCajaPorId(
    String cajaId,
    Map<String, dynamic> datosCierre,
  ) async {
    // El `.eq('cerrada', false)` del datasource real: cerrar dos veces la misma
    // caja no puede pisar el conteo de quien llegó primero.
    if (cerradas.contains(cajaId)) {
      throw Exception('Esa caja ya fue cerrada por otra persona.');
    }

    final esperado = (datosCierre['monto_esperado'] as num).toDouble();
    final balance = await getBalanceDeCaja(cajaId);
    if ((esperado - balance).abs() > 0.005) {
      throw Exception('El monto esperado no coincide con el balance.');
    }

    cerradas.add(cajaId);
    cierres.add({...datosCierre, 'caja_id': cajaId});
    if (cajaId == 'caja-1') hayCajaAbierta = false;
    pendientes.remove(cajaId);
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
  _FakeCajaRepository({this.caja, List<ArqueoPendiente>? pendientes})
    : pendientes = pendientes ?? [];

  CajaDiaria? caja;
  final List<ArqueoPendiente> pendientes;
  final movimientos = StreamController<List<MovimientoCaja>>.broadcast();
  final List<Map<String, double>> cierres = [];
  final List<Map<String, Object?>> arqueosCerrados = [];
  bool fallaAlCerrar = false;
  bool fallaAlCerrarArqueo = false;

  @override
  Future<List<ArqueoPendiente>> getArqueosPendientes() async =>
      List.of(pendientes);

  @override
  Future<void> cerrarArqueoPendiente({
    required String cajaId,
    required double montoReal,
    String? observaciones,
  }) async {
    if (fallaAlCerrarArqueo) {
      throw Exception('Esa caja ya fue cerrada por otra persona.');
    }
    arqueosCerrados.add({
      'cajaId': cajaId,
      'montoReal': montoReal,
      'observaciones': observaciones,
    });
    pendientes.removeWhere((arqueo) => arqueo.id == cajaId);
  }

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

  group('CajaDiariaRepositoryImpl — arqueos pendientes', () {
    test('el arqueo pendiente viaja con sus movimientos y su esperado', () async {
      final repositorio = CajaDiariaRepositoryImpl(
        _FakeDatasource.conArqueoPendiente(),
      );

      final pendientes = await repositorio.getArqueosPendientes();

      expect(pendientes, hasLength(1));
      final arqueo = pendientes.single;
      expect(arqueo.id, _idArqueoViejo);
      expect(arqueo.movimientos, hasLength(3));
      expect(arqueo.ingresos, 7200);
      expect(arqueo.egresos, 900);
      // El esperado sale de los movimientos, no del `monto_esperado` guardado
      // en la apertura, que sigue diciendo 3000.
      expect(arqueo.esperado, _esperadoArqueoViejo);
    });

    test('el esperado del cierre tardío es el de esa caja, no el de hoy', () async {
      final datasource = _FakeDatasource.conArqueoPendiente();
      final repositorio = CajaDiariaRepositoryImpl(datasource);

      await repositorio.cerrarArqueoPendiente(
        cajaId: _idArqueoViejo,
        montoReal: _esperadoArqueoViejo,
      );

      final cierre = datasource.cierres.single;
      expect(cierre['caja_id'], _idArqueoViejo);
      expect(cierre['monto_esperado'], _esperadoArqueoViejo);
      expect(
        cierre['monto_esperado'],
        isNot(_esperadoDelDia),
        reason: 'confundir las dos cajas descuadra las dos',
      );
    });

    test('el conteo tardío se guarda como real y como cierre', () async {
      final datasource = _FakeDatasource.conArqueoPendiente();
      final repositorio = CajaDiariaRepositoryImpl(datasource);

      await repositorio.cerrarArqueoPendiente(
        cajaId: _idArqueoViejo,
        montoReal: _esperadoArqueoViejo - 250,
        observaciones: 'Faltan RD\$ 250, se revisó el arqueo de la tarde.',
      );

      final cierre = datasource.cierres.single;
      expect(cierre['monto_real'], _esperadoArqueoViejo - 250);
      expect(cierre['monto_cierre'], _esperadoArqueoViejo - 250);
      expect(
        cierre['observaciones'],
        'Faltan RD\$ 250, se revisó el arqueo de la tarde.',
      );
    });

    test('cerrar dos veces el mismo arqueo falla la segunda vez', () async {
      final datasource = _FakeDatasource.conArqueoPendiente();
      final repositorio = CajaDiariaRepositoryImpl(datasource);

      await repositorio.cerrarArqueoPendiente(
        cajaId: _idArqueoViejo,
        montoReal: _esperadoArqueoViejo,
      );

      await expectLater(
        repositorio.cerrarArqueoPendiente(
          cajaId: _idArqueoViejo,
          montoReal: 1,
        ),
        throwsA(isA<Exception>()),
        reason: 'la segunda sesión no puede pisar el conteo de la primera',
      );
      expect(datasource.cierres, hasLength(1));
    });

    test('sin arqueos pendientes la lista viene vacía sin consultar movimientos', () async {
      final repositorio = CajaDiariaRepositoryImpl(_FakeDatasource());

      expect(await repositorio.getArqueosPendientes(), isEmpty);
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

    test('cerrar un arqueo viejo no toca la caja de hoy', () async {
      final arqueo = ArqueoPendiente(
        id: _idArqueoViejo,
        caja: CajaDiaria(
          id: _idArqueoViejo,
          fecha: DateTime(2026, 7, 23),
          montoApertura: _aperturaArqueoViejo,
          montoCierre: 0,
          montoEsperado: _aperturaArqueoViejo,
          montoReal: 0,
        ),
        movimientos: _movimientosArqueoViejo().map(_entidad).toList(),
      );
      final repositorio = _FakeCajaRepository(
        caja: _cajaAbierta(),
        pendientes: [arqueo],
      );
      final cubit = CajaDiariaCubit(repositorio, _MovimientoRepositoryFake());
      await cubit.cargar();

      final error = await cubit.cerrarArqueoPendiente(
        cajaId: _idArqueoViejo,
        montoReal: _esperadoArqueoViejo,
      );

      expect(error, isNull);
      expect(repositorio.arqueosCerrados.single['cajaId'], _idArqueoViejo);
      // Un descuadre de otro día no se corrige moviendo el dinero de hoy.
      expect(repositorio.cierres, isEmpty);
      expect(
        cubit.state,
        isA<CajaDiariaAbierta>(),
        reason: 'cuadrar un arqueo viejo no puede cerrar la caja de hoy',
      );

      await cubit.close();
      await repositorio.movimientos.close();
    });

    test('un arqueo viejo que no cuadra exige una nota', () async {
      final arqueo = ArqueoPendiente(
        id: _idArqueoViejo,
        caja: CajaDiaria(
          id: _idArqueoViejo,
          fecha: DateTime(2026, 7, 23),
          montoApertura: _aperturaArqueoViejo,
          montoCierre: 0,
          montoEsperado: _aperturaArqueoViejo,
          montoReal: 0,
        ),
        movimientos: _movimientosArqueoViejo().map(_entidad).toList(),
      );
      final repositorio = _FakeCajaRepository(pendientes: [arqueo]);
      final cubit = CajaDiariaCubit(repositorio, _MovimientoRepositoryFake());
      await cubit.cargar();

      expect(arqueo.esperado, _esperadoArqueoViejo);

      final sinNota = await cubit.cerrarArqueoPendiente(
        cajaId: _idArqueoViejo,
        montoReal: _esperadoArqueoViejo - 400,
      );
      expect(sinNota, contains('nota'));
      expect(repositorio.arqueosCerrados, isEmpty);

      final conNota = await cubit.cerrarArqueoPendiente(
        cajaId: _idArqueoViejo,
        montoReal: _esperadoArqueoViejo - 400,
        observaciones: 'Faltante detectado tres días después.',
      );
      expect(conNota, isNull);
      expect(
        repositorio.arqueosCerrados.single['observaciones'],
        'Faltante detectado tres días después.',
      );

      await cubit.close();
      await repositorio.movimientos.close();
    });

    test('no se cierra un arqueo que ya no está pendiente', () async {
      final repositorio = _FakeCajaRepository(caja: _cajaAbierta());
      final cubit = CajaDiariaCubit(repositorio, _MovimientoRepositoryFake());
      await cubit.cargar();

      final error = await cubit.cerrarArqueoPendiente(
        cajaId: 'caja-fantasma',
        montoReal: 100,
      );

      expect(error, contains('ya no está pendiente'));
      expect(repositorio.arqueosCerrados, isEmpty);

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
