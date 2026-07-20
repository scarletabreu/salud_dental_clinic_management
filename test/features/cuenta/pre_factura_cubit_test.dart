import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/estado_cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/repositories/cuenta_repository.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/usecases/get_cuenta_by_id_usecase.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/pre_factura_cubit.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/pre_factura_state.dart';
import 'package:salud_dental_clinic_management/features/item_cuenta/domain/entities/item_cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/entities/cuota.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/enums/estado_cuota.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/repositories/cuota_repository.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/usecases/generar_plan_de_cuotas.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/entities/pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/enums/estado_pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/enums/metodo_pago.dart'
    as pago_enums;
import 'package:salud_dental_clinic_management/features/pago/domain/repositories/pago_repository.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/usecases/registrar_pago.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';

/// Fake del repositorio: solo implementa lo que consume el use case bajo prueba.
/// El proyecto no usa mocktail/mockito, así que se escribe a mano (ver
/// `connectivity_cubit_test.dart`).
class _FakeCuentaRepository implements CuentaRepository {
  _FakeCuentaRepository({this.resultado, this.resultados, this.error});

  final Cuenta? resultado;
  final List<Cuenta>? resultados;
  final Object? error;
  int _lecturas = 0;

  @override
  Future<Cuenta> getCuentaById(String id) async {
    if (error != null) throw error!;
    final secuencia = resultados;
    if (secuencia != null) {
      final indice = _lecturas < secuencia.length
          ? _lecturas
          : secuencia.length - 1;
      _lecturas++;
      return secuencia[indice];
    }
    return resultado!;
  }

  @override
  Future<void> crearFactura(Cuenta cuenta) => throw UnimplementedError();

  @override
  Future<void> eliminarCuenta(String id) => throw UnimplementedError();

  @override
  Future<List<Cuenta>> getCuentasPorCobrar() => throw UnimplementedError();

  @override
  Future<List<Cuenta>> getHistorialFinanciero(String pacienteId) =>
      throw UnimplementedError();
}

/// Fake del repositorio de pagos: registra la última llamada para poder
/// aseverar los argumentos y devuelve un id fijo.
class _FakePagoRepository implements PagoRepository {
  String? ultimaCuentaId;
  double? ultimoMonto;
  pago_enums.MetodoPago? ultimoMetodo;

  @override
  Future<String> registrarPago({
    required String cuentaId,
    required double monto,
    required pago_enums.MetodoPago metodo,
    String? cuotaId,
  }) async {
    ultimaCuentaId = cuentaId;
    ultimoMonto = monto;
    ultimoMetodo = metodo;
    return 'pago-1';
  }

  @override
  Future<void> procesarPago(Pago pago) => throw UnimplementedError();

  @override
  Future<void> editarPago(Pago pago) => throw UnimplementedError();

  @override
  Future<void> cancelarPago(String id) => throw UnimplementedError();

  @override
  Future<List<Pago>> getHistorialPagosCuenta(String cuentaId) =>
      throw UnimplementedError();
}

class _FakeCuotaRepository implements CuotaRepository {
  final List<Cuota> cuotas;
  _FakeCuotaRepository({this.cuotas = const []});

  @override
  Future<List<Cuota>> getCuotasDeCuenta(String cuentaId) async => cuotas;

  @override
  Future<void> generarPlanDePagos(List<Cuota> cuotas) async {}
}

class _FakeConsultaRepository implements ConsultaRepository {
  @override
  Future<Consulta?> getDetalleConsulta(String id) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePacienteRepository implements IPacienteRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Cuenta _cuenta({
  List<ItemCuenta> items = const [],
  List<Pago> pagos = const [],
}) {
  return Cuenta(
    id: 'c1',
    consultaId: 'consulta-123',
    fechaCreacion: DateTime(2026, 7, 15),
    metodoPago: MetodoPago.contado,
    itemCuentas: items,
    pagos: pagos,
  );
}

ItemCuenta _item(double precio, {int cantidad = 1}) => ItemCuenta(
  cuentaId: 'c1',
  descripcion: 'Tratamiento',
  precioUnitario: precio,
  cantidad: cantidad,
);

Pago _pago(double monto, {String? id}) => Pago(
  id: id,
  cuentaId: 'c1',
  monto: monto,
  fecha: DateTime(2026, 7, 15),
  estado: EstadoPago.completado,
  metodoPago: pago_enums.MetodoPago.efectivo,
);

void main() {
  group('PreFacturaCubit', () {
    test('cargar OK emite Cargando y luego Cargada con la cuenta', () async {
      final cuenta = _cuenta(items: [_item(1000)]);
      final cuota = Cuota(
        id: 'q1',
        cuentaId: 'c1',
        monto: 1000,
        fechaVencimiento: DateTime(2026, 8, 15),
        estado: EstadoCuota.pendiente,
      );
      final cuotaRepository = _FakeCuotaRepository(cuotas: [cuota]);
      final cubit = PreFacturaCubit(
        getCuenta: GetCuentaByIdUseCase(
          repository: _FakeCuentaRepository(resultado: cuenta),
        ),
        registrarPago: RegistrarPago(_FakePagoRepository()),
        cuotaRepository: cuotaRepository,
        generarPlan: GenerarPlanDeCuotas(cuotaRepository),
        consultaRepository: _FakeConsultaRepository(),
        pacienteRepository: _FakePacienteRepository(),
      );

      final futuro = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<PreFacturaCargando>(),
          isA<PreFacturaCargada>().having(
            (s) => s.cuenta.consultaId,
            'consultaId',
            'consulta-123',
          ),
        ]),
      );

      await cubit.cargar('c1');
      await futuro;
      expect((cubit.state as PreFacturaCargada).cuotas, [cuota]);
      await cubit.close();
    });

    test('cargar con error emite Cargando y luego Error', () async {
      final cuotaRepository = _FakeCuotaRepository();
      final cubit = PreFacturaCubit(
        getCuenta: GetCuentaByIdUseCase(
          repository: _FakeCuentaRepository(error: Exception('boom')),
        ),
        registrarPago: RegistrarPago(_FakePagoRepository()),
        cuotaRepository: cuotaRepository,
        generarPlan: GenerarPlanDeCuotas(cuotaRepository),
        consultaRepository: _FakeConsultaRepository(),
        pacienteRepository: _FakePacienteRepository(),
      );

      final futuro = expectLater(
        cubit.stream,
        emitsInOrder([isA<PreFacturaCargando>(), isA<PreFacturaError>()]),
      );

      await cubit.cargar('c1');
      await futuro;
      await cubit.close();
    });

    test('conserva el pago recién creado después de recargar', () async {
      final inicial = _cuenta(items: [_item(1000)]);
      final actualizada = _cuenta(
        items: [_item(1000)],
        pagos: [_pago(400, id: 'pago-1')],
      );
      final cuotaRepository = _FakeCuotaRepository();
      final cubit = PreFacturaCubit(
        getCuenta: GetCuentaByIdUseCase(
          repository: _FakeCuentaRepository(resultados: [inicial, actualizada]),
        ),
        registrarPago: RegistrarPago(_FakePagoRepository()),
        cuotaRepository: cuotaRepository,
        generarPlan: GenerarPlanDeCuotas(cuotaRepository),
        consultaRepository: _FakeConsultaRepository(),
        pacienteRepository: _FakePacienteRepository(),
      );

      await cubit.cargar('c1');
      final error = await cubit.registrarPago(
        monto: 400,
        metodo: pago_enums.MetodoPago.efectivo,
      );

      expect(error, isNull);
      expect(cubit.ultimoPagoRegistrado?.id, 'pago-1');
      expect((cubit.state as PreFacturaCargada).cuenta.montoPagado, 400);
      await cubit.close();
    });
  });

  group('Cuenta.estadoCuenta', () {
    test('sin pagos -> abierta', () {
      final cuenta = _cuenta(items: [_item(1000)]);
      expect(cuenta.estadoCuenta, EstadoCuenta.abierta);
    });

    test('pago parcial -> pendiente', () {
      final cuenta = _cuenta(items: [_item(1000)], pagos: [_pago(400)]);
      expect(cuenta.estadoCuenta, EstadoCuenta.pendiente);
    });

    test('pago total -> saldada', () {
      final cuenta = _cuenta(items: [_item(1000)], pagos: [_pago(1000)]);
      expect(cuenta.estadoCuenta, EstadoCuenta.saldada);
    });
  });
}
