import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/caja_diaria.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/entities/movimiento_caja.dart';

abstract class CajaDiariaRepository {
  Future<CajaDiaria?> getCajaActual();
  Future<void> abrirCaja(double montoApertura);
  Future<void> cerrarCaja({
    required double montoReal,
    required double montoCierre,
    String? observaciones,
  });
  Future<bool> isCajaAbierta();
  Future<double> getMontoEsperado();
  Stream<List<MovimientoCaja>> watchMovimientos(String cajaDiariaId);
}
