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
  const CajaDiariaSinAbrir({this.error});

  final String? error;
}

class CajaDiariaAbierta extends CajaDiariaState {
  const CajaDiariaAbierta({required this.caja, this.movimientos = const []});

  final CajaDiaria caja;
  final List<MovimientoCaja> movimientos;

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
