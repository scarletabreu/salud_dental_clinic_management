import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/balance_caja.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/caja_diaria.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/entities/movimiento_caja.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/enums/tipo_movimiento.dart';

MovimientoCaja _ingreso(double monto) => MovimientoCaja(
  cajaDiariaId: 'caja-1',
  tipo: TipoMovimiento.ingreso,
  monto: monto,
  descripcion: 'Cobro a cuenta',
  fecha: DateTime(2026, 7, 25, 10),
);

MovimientoCaja _egreso(double monto) => MovimientoCaja(
  cajaDiariaId: 'caja-1',
  tipo: TipoMovimiento.egreso,
  monto: monto,
  descripcion: 'Compra de insumos',
  fecha: DateTime(2026, 7, 25, 15),
);

void main() {
  group('BalanceCaja.esperado', () {
    test('una caja sin movimientos vale exactamente su apertura', () {
      expect(
        BalanceCaja.esperado(montoApertura: 5000, movimientos: const []),
        5000,
      );
    });

    test('suma los ingresos y resta los egresos de un día mixto', () {
      final movimientos = [
        _ingreso(3500),
        _egreso(1250),
        _ingreso(18500),
        _egreso(800),
        _ingreso(2400),
      ];

      expect(BalanceCaja.ingresos(movimientos), 24400);
      expect(BalanceCaja.egresos(movimientos), 2050);
      expect(
        BalanceCaja.esperado(montoApertura: 5000, movimientos: movimientos),
        27350,
      );
    });

    test('un día de puros egresos baja por debajo de la apertura', () {
      final movimientos = [_egreso(1200), _egreso(3000)];

      expect(BalanceCaja.ingresos(movimientos), 0);
      expect(
        BalanceCaja.esperado(montoApertura: 5000, movimientos: movimientos),
        800,
      );
    });

    test('el orden de los movimientos no altera el esperado', () {
      final movimientos = [_ingreso(1500), _egreso(700), _ingreso(325.50)];
      final invertidos = movimientos.reversed.toList();

      expect(
        BalanceCaja.esperado(montoApertura: 2000, movimientos: movimientos),
        BalanceCaja.esperado(montoApertura: 2000, movimientos: invertidos),
      );
    });

    test('los centavos no arrastran el error de punto flotante', () {
      // 0.1 + 0.2 en double da 0.30000000000000004. Sin redondeo, el cierre
      // reportaría un descuadre inexistente de una fracción de centavo.
      final movimientos = [_ingreso(0.1), _ingreso(0.2)];

      expect(
        BalanceCaja.esperado(montoApertura: 0, movimientos: movimientos),
        0.30,
      );
    });

    test('cuadra con centavos repartidos entre ingresos y egresos', () {
      final movimientos = [
        _ingreso(1200.35),
        _ingreso(899.95),
        _egreso(450.15),
        _egreso(99.99),
      ];

      expect(BalanceCaja.ingresos(movimientos), 2100.30);
      expect(BalanceCaja.egresos(movimientos), 550.14);
      expect(
        BalanceCaja.esperado(montoApertura: 1500.50, movimientos: movimientos),
        3050.66,
      );
    });
  });

  group('BalanceCaja.diferencia', () {
    test('contar de menos es un faltante negativo', () {
      expect(
        BalanceCaja.diferencia(montoReal: 27000, montoEsperado: 27350),
        -350,
      );
    });

    test('contar de más es un sobrante positivo', () {
      expect(
        BalanceCaja.diferencia(montoReal: 27500, montoEsperado: 27350),
        150,
      );
    });

    test('una caja que cuadra da cero exacto y comparable', () {
      final movimientos = [_ingreso(0.1), _ingreso(0.2), _egreso(0.05)];
      final esperado = BalanceCaja.esperado(
        montoApertura: 100.10,
        movimientos: movimientos,
      );

      final diferencia = BalanceCaja.diferencia(
        montoReal: esperado,
        montoEsperado: esperado,
      );

      // La pantalla de cierre decide "cuadra" con `diferencia == 0`: tiene que
      // ser cero exacto, no 1e-13.
      expect(diferencia, 0);
      expect(diferencia == 0, isTrue);
    });
  });

  group('CajaDiaria', () {
    test('expone la diferencia y detecta el faltante', () {
      final caja = CajaDiaria(
        id: 'caja-1',
        fecha: DateTime(2026, 7, 25),
        montoApertura: 5000,
        montoCierre: 27000,
        montoEsperado: 27350,
        montoReal: 27000,
      );

      expect(caja.diferencia, -350);
      expect(caja.tieneFaltante, isTrue);
    });

    test('un sobrante no cuenta como faltante', () {
      final caja = CajaDiaria(
        fecha: DateTime(2026, 7, 25),
        montoApertura: 5000,
        montoCierre: 27500,
        montoEsperado: 27350,
        montoReal: 27500,
      );

      expect(caja.diferencia, 150);
      expect(caja.tieneFaltante, isFalse);
    });

    test('una caja cuadrada con centavos no reporta faltante fantasma', () {
      final caja = CajaDiaria(
        fecha: DateTime(2026, 7, 25),
        montoApertura: 0,
        montoCierre: 0.30,
        montoEsperado: 0.1 + 0.2,
        montoReal: 0.30,
      );

      expect(caja.diferencia, 0);
      expect(caja.tieneFaltante, isFalse);
    });
  });
}
