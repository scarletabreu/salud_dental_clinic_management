import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/entities/movimiento_caja.dart';

class ResumenCierre {
  final Map<String, double> totalesPorMetodoPago;
  final double totalIngresos;
  final double totalEgresos;
  final double montoEsperado;
  final List<MovimientoCaja> movimientos;

  ResumenCierre({
    required this.totalesPorMetodoPago,
    required this.totalIngresos,
    required this.totalEgresos,
    required this.montoEsperado,
    required this.movimientos,
  });
}
