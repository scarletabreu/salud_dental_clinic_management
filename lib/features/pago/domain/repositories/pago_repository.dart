import 'package:salud_dental_clinic_management/features/pago/domain/entities/pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/enums/metodo_pago.dart';

abstract class PagoRepository {
  Future<void> procesarPago(Pago pago);
  Future<void> editarPago(Pago pago);
  Future<void> cancelarPago(String id);
  Future<List<Pago>> getHistorialPagosCuenta(String cuentaId);

  /// Registra un cobro sobre una cuenta de forma atómica (inserta el pago y
  /// cierra la cuenta si quedó saldada). Devuelve el id del pago creado.
  Future<String> registrarPago({
    required String cuentaId,
    required double monto,
    required MetodoPago metodo,
  });
}
