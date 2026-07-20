import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/estado_cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/repositories/cuenta_repository.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/usecases/get_cuenta_by_id_usecase.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/pre_factura_cubit.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/pre_factura_state.dart';
import 'package:salud_dental_clinic_management/features/item_cuenta/domain/entities/item_cuenta.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/entities/pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/enums/estado_pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/enums/metodo_pago.dart'
    as pago_enums;
import 'package:salud_dental_clinic_management/features/pago/domain/repositories/pago_repository.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/usecases/registrar_pago.dart';

/// Fake del repositorio: solo implementa lo que consume el use case bajo prueba.
/// El proyecto no usa mocktail/mockito, así que se escribe a mano (ver
/// `connectivity_cubit_test.dart`).
class _FakeCuentaRepository implements CuentaRepository {
  _FakeCuentaRepository({this.resultado, this.error});

  final Cuenta? resultado;
  final Object? error;

  @override
  Future<Cuenta> getCuentaById(String id) async {
    if (error != null) throw error!;
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

Pago _pago(double monto) => Pago(
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
      final cubit = PreFacturaCubit(
        getCuenta: GetCuentaByIdUseCase(
          repository: _FakeCuentaRepository(resultado: cuenta),
        ),
        registrarPago: RegistrarPago(_FakePagoRepository()),
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
      await cubit.close();
    });

    test('cargar con error emite Cargando y luego Error', () async {
      final cubit = PreFacturaCubit(
        getCuenta: GetCuentaByIdUseCase(
          repository: _FakeCuentaRepository(error: Exception('boom')),
        ),
        registrarPago: RegistrarPago(_FakePagoRepository()),
      );

      final futuro = expectLater(
        cubit.stream,
        emitsInOrder([isA<PreFacturaCargando>(), isA<PreFacturaError>()]),
      );

      await cubit.cargar('c1');
      await futuro;
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
