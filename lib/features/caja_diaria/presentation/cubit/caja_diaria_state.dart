import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/caja_diaria.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/entities/movimiento_caja.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/enums/tipo_movimiento.dart';

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

  double get ingresos => movimientos
      .where((movimiento) => movimiento.tipo == TipoMovimiento.ingreso)
      .fold(0, (total, movimiento) => total + movimiento.monto);

  double get egresos => movimientos
      .where((movimiento) => movimiento.tipo == TipoMovimiento.egreso)
      .fold(0, (total, movimiento) => total + movimiento.monto);

  double get montoEsperado => caja.montoApertura + ingresos - egresos;
}

class CajaDiariaError extends CajaDiariaState {
  const CajaDiariaError(this.mensaje);

  final String mensaje;
}
