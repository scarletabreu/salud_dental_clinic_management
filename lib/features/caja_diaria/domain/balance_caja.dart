import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/entities/movimiento_caja.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/enums/tipo_movimiento.dart';

/// Regla contable única del cierre de caja.
///
/// El mismo cálculo vivía duplicado en el estado del cubit, en el datasource y
/// en la pantalla de cierre. Tres copias de una regla de dinero es una copia
/// que se desincroniza: aquí queda una sola, cubierta por pruebas.
///
/// Todos los totales se redondean a centavos porque `double` no representa
/// exactamente los decimales del dinero: sumar 0.1 + 0.2 da 0.30000000000000004
/// y el cierre reportaría un descuadre fantasma de una fracción de centavo. La
/// base guarda `numeric(12,2)`, así que redondear aquí también evita que el
/// esperado calculado en la app difiera del persistido.
abstract final class BalanceCaja {
  /// Redondea a centavos (2 decimales), la unidad mínima real del dinero.
  static double redondear(double monto) => (monto * 100).round() / 100;

  static double ingresos(Iterable<MovimientoCaja> movimientos) =>
      redondear(_sumarPorTipo(movimientos, TipoMovimiento.ingreso));

  static double egresos(Iterable<MovimientoCaja> movimientos) =>
      redondear(_sumarPorTipo(movimientos, TipoMovimiento.egreso));

  /// Dinero que debería haber en la gaveta: apertura + ingresos - egresos.
  static double esperado({
    required double montoApertura,
    required Iterable<MovimientoCaja> movimientos,
  }) {
    return redondear(
      montoApertura +
          _sumarPorTipo(movimientos, TipoMovimiento.ingreso) -
          _sumarPorTipo(movimientos, TipoMovimiento.egreso),
    );
  }

  /// Descuadre del cierre: negativo es faltante, positivo es sobrante.
  ///
  /// Se redondea para que la pantalla de cierre pueda comparar contra cero sin
  /// arrastrar el error de punto flotante de las restas anteriores.
  static double diferencia({
    required double montoReal,
    required double montoEsperado,
  }) => redondear(montoReal - montoEsperado);

  static double _sumarPorTipo(
    Iterable<MovimientoCaja> movimientos,
    TipoMovimiento tipo,
  ) => movimientos
      .where((movimiento) => movimiento.tipo == tipo)
      .fold(0.0, (total, movimiento) => total + movimiento.monto);
}
