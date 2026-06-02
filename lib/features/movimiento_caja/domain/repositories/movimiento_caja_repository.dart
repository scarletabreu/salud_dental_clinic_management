import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/entities/movimiento_caja.dart';

abstract class MovimientoCajaRepository {
  Future<void> crearMovimiento(MovimientoCaja movimiento);
  Future<List<MovimientoCaja>> getMovimientosDeHoy(String cajaDiariaId);
}
