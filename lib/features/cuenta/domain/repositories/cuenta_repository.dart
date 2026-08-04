import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart';

abstract class CuentaRepository {
  Future<List<Cuenta>> getCuentasPorCobrar();
  Future<List<Cuenta>> getHistorialFinanciero(String pacienteId);
  Future<Cuenta?> getCuentaByConsultaId(String consultaId);
  Future<Cuenta> getCuentaById(String id);

  /// Persiste el modo de pago pactado con el paciente.
  Future<void> fijarModoPago(String cuentaId, MetodoPago modo);

  Future<void> eliminarCuenta(String id);
}
