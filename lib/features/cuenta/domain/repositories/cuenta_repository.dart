import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';

abstract class CuentaRepository {
  Future<List<Cuenta>> getHistorialFinanciero(String pacienteId);
  Future<void> crearFactura(Cuenta cuenta);
  Future<void> eliminarCuenta(String id);
}
