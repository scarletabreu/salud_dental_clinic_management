import 'package:salud_dental_clinic_management/features/pago/domain/entities/pago.dart';

abstract class PagoRepository {
  Future<void> procesarPago(Pago pago);
  Future<void> editarPago(Pago pago);
  Future<void> cancelarPago(String id);
  Future<List<Pago>> getHistorialPagosCuenta(String cuentaId);
}
