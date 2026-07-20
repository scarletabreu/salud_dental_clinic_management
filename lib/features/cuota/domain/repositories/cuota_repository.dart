import 'package:salud_dental_clinic_management/features/cuota/domain/entities/cuota.dart';

abstract class CuotaRepository {
  Future<List<Cuota>> getCuotasDeCuenta(String cuentaId);
  Future<void> generarPlanDePagos(List<Cuota> cuotas);
}
