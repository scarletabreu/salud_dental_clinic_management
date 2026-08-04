import 'package:salud_dental_clinic_management/features/caja_diaria/domain/balance_caja.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/caja_diaria.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/entities/movimiento_caja.dart';

sealed class CajaDiariaState {
  const CajaDiariaState();
}

class CajaDiariaLoading extends CajaDiariaState {
  const CajaDiariaLoading();
}

class CajaDiariaSinAbrir extends CajaDiariaState {
  const CajaDiariaSinAbrir({this.error, this.pendientes = const []});

  final String? error;

  /// Cajas de días anteriores que quedaron sin cerrar.
  final List<CajaDiaria> pendientes;
}

class CajaDiariaAbierta extends CajaDiariaState {
  const CajaDiariaAbierta({
    required this.caja,
    this.movimientos = const [],
    this.pendientes = const [],
  });

  final CajaDiaria caja;
  final List<MovimientoCaja> movimientos;

  /// Cajas de días anteriores que quedaron sin cerrar. Ya no impiden cobrar
  /// —la unicidad pasó a ser por día civil—, pero siguen siendo un arqueo
  /// pendiente que alguien debe cerrar.
  final List<CajaDiaria> pendientes;

  double get ingresos => BalanceCaja.ingresos(movimientos);

  double get egresos => BalanceCaja.egresos(movimientos);

  double get montoEsperado => BalanceCaja.esperado(
    montoApertura: caja.montoApertura,
    movimientos: movimientos,
  );
}

class CajaDiariaError extends CajaDiariaState {
  const CajaDiariaError(this.mensaje);

  final String mensaje;
}
