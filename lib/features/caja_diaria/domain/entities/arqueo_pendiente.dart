import 'package:salud_dental_clinic_management/features/caja_diaria/domain/balance_caja.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/caja_diaria.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/entities/movimiento_caja.dart';

/// Una caja de un día anterior que nadie cerró, junto a los movimientos que la
/// explican.
///
/// El aviso de arqueos pendientes sólo daba la fecha, y cerrar a ciegas el
/// arqueo de hace tres días es fabricar el descuadre: se pide un conteo contra
/// un esperado que nadie puede ver. La caja viaja con sus movimientos para que
/// el esperado salga de `BalanceCaja` —la misma regla que cuadra el cierre del
/// día— y no de un número guardado que quedó viejo en la apertura.
class ArqueoPendiente {
  const ArqueoPendiente({
    required this.id,
    required this.caja,
    this.movimientos = const [],
  });

  /// Identificador de la caja. Es obligatorio: un arqueo que no se puede
  /// nombrar tampoco se puede cerrar.
  final String id;

  final CajaDiaria caja;
  final List<MovimientoCaja> movimientos;

  DateTime get fecha => caja.fecha;

  double get montoApertura => caja.montoApertura;

  double get ingresos => BalanceCaja.ingresos(movimientos);

  double get egresos => BalanceCaja.egresos(movimientos);

  double get esperado => BalanceCaja.esperado(
    montoApertura: caja.montoApertura,
    movimientos: movimientos,
  );

  /// Días transcurridos desde la apertura sin que nadie cuadrara la caja.
  int diasDeRetraso(DateTime hoy) =>
      DateTime(hoy.year, hoy.month, hoy.day)
          .difference(DateTime(fecha.year, fecha.month, fecha.day))
          .inDays;
}
