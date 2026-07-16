import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart'
    as cuenta_enums;
import 'package:salud_dental_clinic_management/features/item_cuenta/domain/entities/item_cuenta.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/entities/pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/enums/estado_pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/repositories/pago_repository.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/usecases/registrar_pago.dart';

/// Fake que captura los argumentos con los que se invocó el repositorio. Si
/// [debeInvocarse] es false y aun así se llama, el test falla explícitamente.
class _FakePagoRepository implements PagoRepository {
  bool invocado = false;
  String? cuentaId;
  double? monto;
  MetodoPago? metodo;

  @override
  Future<String> registrarPago({
    required String cuentaId,
    required double monto,
    required MetodoPago metodo,
  }) async {
    invocado = true;
    this.cuentaId = cuentaId;
    this.monto = monto;
    this.metodo = metodo;
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
  String? id = 'c1',
  double total = 1000,
  List<Pago> pagos = const [],
}) {
  return Cuenta(
    id: id,
    consultaId: 'consulta-123',
    fechaCreacion: DateTime(2026, 7, 15),
    metodoPago: cuenta_enums.MetodoPago.contado,
    itemCuentas: [
      ItemCuenta(
        cuentaId: 'c1',
        descripcion: 'Tratamiento',
        precioUnitario: total,
        cantidad: 1,
      ),
    ],
    pagos: pagos,
  );
}

Pago _pago(double monto) => Pago(
  cuentaId: 'c1',
  monto: monto,
  fecha: DateTime(2026, 7, 15),
  estado: EstadoPago.completado,
  metodoPago: MetodoPago.efectivo,
);

void main() {
  group('RegistrarPago', () {
    late _FakePagoRepository repo;
    late RegistrarPago usecase;

    setUp(() {
      repo = _FakePagoRepository();
      usecase = RegistrarPago(repo);
    });

    test('cobro válido delega en el repositorio con los argumentos correctos',
        () async {
      final id = await usecase(
        cuenta: _cuenta(total: 1000),
        monto: 400,
        metodo: MetodoPago.efectivo,
      );

      expect(id, 'pago-1');
      expect(repo.invocado, isTrue);
      expect(repo.cuentaId, 'c1');
      expect(repo.monto, 400);
      expect(repo.metodo, MetodoPago.efectivo);
    });

    test('permite saldar exactamente el saldo pendiente', () async {
      await usecase(
        cuenta: _cuenta(total: 1000, pagos: [_pago(600)]),
        monto: 400,
        metodo: MetodoPago.transferenciaBancaria,
      );

      expect(repo.invocado, isTrue);
      expect(repo.monto, 400);
    });

    test('rechaza monto cero sin tocar el repositorio', () async {
      expect(
        () => usecase(
          cuenta: _cuenta(),
          monto: 0,
          metodo: MetodoPago.efectivo,
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(repo.invocado, isFalse);
    });

    test('rechaza monto negativo', () async {
      expect(
        () => usecase(
          cuenta: _cuenta(),
          monto: -50,
          metodo: MetodoPago.efectivo,
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(repo.invocado, isFalse);
    });

    test('rechaza monto mayor que el saldo pendiente', () async {
      expect(
        () => usecase(
          cuenta: _cuenta(total: 1000, pagos: [_pago(800)]),
          monto: 300, // saldo real = 200
          metodo: MetodoPago.efectivo,
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(repo.invocado, isFalse);
    });

    test('rechaza cobro sobre una cuenta ya saldada', () async {
      expect(
        () => usecase(
          cuenta: _cuenta(total: 1000, pagos: [_pago(1000)]),
          monto: 100,
          metodo: MetodoPago.efectivo,
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(repo.invocado, isFalse);
    });

    test('rechaza cuenta sin id', () async {
      expect(
        () => usecase(
          cuenta: _cuenta(id: null),
          monto: 100,
          metodo: MetodoPago.efectivo,
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(repo.invocado, isFalse);
    });
  });
}
