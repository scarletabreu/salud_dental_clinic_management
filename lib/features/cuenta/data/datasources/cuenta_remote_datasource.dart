import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart';

/// Acceso a `cuentas`.
///
/// Una pre-factura la crea el cierre de la consulta y sólo él: desde
/// `audit_002` el cliente no tiene INSERT sobre la tabla, y un trigger congela
/// `monto_total`, `consulta_id` y `paciente_id` frente a cualquier edición del
/// cliente. Lo que sí se decide después —el modo de pago pactado con el
/// paciente— tiene aquí su propia vía.
abstract class CuentaRemoteDatasource {
  Future<List<Map<String, dynamic>>> fetchTodasLasCuentas();
  Future<List<Map<String, dynamic>>> fetchCuentasByPaciente(String pacienteId);
  Future<Map<String, dynamic>?> fetchCuentaById(String id);
  Future<Map<String, dynamic>?> fetchCuentaByConsultaId(String consultaId);

  /// Persiste el modo de pago pactado (contado o crédito).
  Future<void> fijarModoPago(String id, MetodoPago modo);

  Future<void> deleteCuenta(String id);
}
