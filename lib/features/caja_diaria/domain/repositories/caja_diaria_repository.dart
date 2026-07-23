import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/caja_diaria.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/resumen_cierre.dart';

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
  Future<ResumenCierre> getResumenCierre();
}
