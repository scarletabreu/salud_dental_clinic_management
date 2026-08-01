import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/entities/cuota.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/enums/estado_cuota.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/enums/frecuencia_cuota.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/repositories/cuota_repository.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/usecases/generar_plan_de_cuotas.dart';
import 'package:salud_dental_clinic_management/features/item_cuenta/domain/entities/item_cuenta.dart';

class _FakeCuotaRepository implements CuotaRepository {
  List<Cuota>? insertadas;

  @override
  Future<void> generarPlanDePagos(List<Cuota> cuotas) async {
    insertadas = cuotas;
  }

  @override
  Future<List<Cuota>> getCuotasDeCuenta(String cuentaId) async => const [];

  @override
  Future<void> marcarCuotasVencidas(String cuentaId) async {}
}

Cuenta _cuenta(double total) => Cuenta(
  id: 'c1',
  consultaId: 'consulta-1',
  fechaCreacion: DateTime(2026, 7, 20),
  metodoPago: MetodoPago.contado,
  itemCuentas: [
    ItemCuenta(
      cuentaId: 'c1',
      descripcion: 'Tratamiento',
      precioUnitario: total,
      cantidad: 1,
    ),
  ],
);

void main() {
  group('GenerarPlanDeCuotas', () {
    late _FakeCuotaRepository repository;
    late GenerarPlanDeCuotas usecase;
    late DateTime fechaFutura;

    setUp(() {
      repository = _FakeCuotaRepository();
      usecase = GenerarPlanDeCuotas(repository);
      fechaFutura = DateTime.now().add(const Duration(days: 10));
    });

    test('reparte en centavos y la última cuota absorbe el redondeo', () {
      final cuotas = usecase.previsualizar(
        cuenta: _cuenta(100),
        numCuotas: 3,
        fechaPrimera: fechaFutura,
        frecuencia: FrecuenciaCuota.mensual,
      );

      expect(cuotas.map((c) => c.monto), [33.33, 33.33, 33.34]);
      expect(cuotas.fold<double>(0, (suma, c) => suma + c.monto), 100);
      expect(cuotas.every((c) => c.estado == EstadoCuota.pendiente), isTrue);
    });

    test('genera fechas mensuales preservando el día cuando existe', () {
      final fechas = List.generate(
        3,
        (i) => FrecuenciaCuota.mensual.fechaDesde(DateTime(2027, 1, 31), i),
      );

      expect(fechas, [
        DateTime(2027, 1, 31),
        DateTime(2027, 2, 28),
        DateTime(2027, 3, 31),
      ]);
    });

    test('persiste exactamente la previsualización generada', () async {
      final resultado = await usecase(
        cuenta: _cuenta(900),
        numCuotas: 3,
        fechaPrimera: fechaFutura,
        frecuencia: FrecuenciaCuota.quincenal,
      );

      expect(repository.insertadas, same(resultado));
      expect(
        resultado[1].fechaVencimiento.difference(resultado[0].fechaVencimiento),
        const Duration(days: 15),
      );
    });

    test('rechaza una primera fecha en el pasado sin persistir', () {
      expect(
        () => usecase.previsualizar(
          cuenta: _cuenta(100),
          numCuotas: 2,
          fechaPrimera: DateTime.now().subtract(const Duration(days: 1)),
          frecuencia: FrecuenciaCuota.semanal,
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(repository.insertadas, isNull);
    });
  });
}
