import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/data/models/caja_diaria_model.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/caja_diaria.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/repositories/caja_diaria_repository.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/presentation/cubit/caja_diaria_cubit.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/presentation/cubit/caja_diaria_state.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/entities/movimiento_caja.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/enums/tipo_movimiento.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/repositories/movimiento_caja_repository.dart';

class _MovimientoRepositoryFake implements MovimientoCajaRepository {
  @override
  Future<void> crearMovimiento(MovimientoCaja movimiento) async {}

  @override
  Future<List<MovimientoCaja>> getMovimientosDeHoy(String cajaDiariaId) async =>
      [];
}

class _CajaRepositoryFake implements CajaDiariaRepository {
  CajaDiaria? caja;
  final movimientos = StreamController<List<MovimientoCaja>>.broadcast();
  double? montoAbierto;

  @override
  Future<void> abrirCaja(double montoApertura) async {
    montoAbierto = montoApertura;
    caja = CajaDiaria(
      id: 'caja-1',
      fecha: DateTime(2026, 7, 21),
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
  }) async {}

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

void main() {
  test('mapea los campos snake_case que devuelve Supabase', () {
    final caja = CajaDiariaModel.fromJson({
      'id': 'caja-1',
      'fecha': '2026-07-21T10:00:00.000Z',
      'monto_apertura': 500,
      'monto_cierre': 0,
      'monto_esperado': 500,
      'monto_real': 0,
      'cerrada': false,
    });

    expect(caja.montoApertura, 500);
    expect(caja.montoEsperado, 500);
    expect(caja.cerrada, isFalse);
  });

  test(
    'abre caja y calcula el esperado con ingresos y egresos en vivo',
    () async {
      final repository = _CajaRepositoryFake();
      final cubit = CajaDiariaCubit(repository, _MovimientoRepositoryFake());

      expect(await cubit.abrirCaja(500), isNull);
      expect(repository.montoAbierto, 500);
      expect(cubit.state, isA<CajaDiariaAbierta>());

      repository.movimientos.add([
        MovimientoCaja(
          cajaDiariaId: 'caja-1',
          tipo: TipoMovimiento.ingreso,
          monto: 200,
          descripcion: 'Cobro',
          fecha: DateTime(2026, 7, 21, 9),
          referenciaId: 'pago-1',
        ),
        MovimientoCaja(
          cajaDiariaId: 'caja-1',
          tipo: TipoMovimiento.egreso,
          monto: 75,
          descripcion: 'Compra menor',
          fecha: DateTime(2026, 7, 21, 10),
          referenciaId: 'egreso-1',
        ),
      ]);
      await Future<void>.delayed(Duration.zero);

      final state = cubit.state as CajaDiariaAbierta;
      expect(state.ingresos, 200);
      expect(state.egresos, 75);
      expect(state.montoEsperado, 625);
      await cubit.close();
      await repository.movimientos.close();
    },
  );
}
