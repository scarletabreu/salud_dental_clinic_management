import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/repositories/pago_repository.dart';

/// Caso de uso: registrar un cobro sobre una cuenta (pre-factura).
///
/// Valida en el dominio antes de tocar la red (monto positivo y que no exceda el
/// saldo pendiente) para dar feedback inmediato con un mensaje concreto. La
/// inserción del pago, la actualización del pagado y el cierre de la cuenta si
/// quedó saldada ocurren de forma atómica en el repositorio (RPC), que además
/// revalida el saldo server-side para blindar contra pagos concurrentes.
class RegistrarPago {
  final PagoRepository _repository;

  RegistrarPago(this._repository);

  /// [cuenta] cuenta cargada; aporta el id y el saldo pendiente a validar.
  /// [monto] importe a cobrar.
  /// [metodo] instrumento de pago (efectivo, tarjeta, transferencia).
  ///
  /// Devuelve el id del pago creado. Lanza [ValidationFailure] si el monto no
  /// respeta las reglas de negocio.
  Future<String> call({
    required Cuenta cuenta,
    required double monto,
    required MetodoPago metodo,
  }) async {
    final cuentaId = cuenta.id;
    if (cuentaId == null) {
      throw const ValidationFailure(
        'La cuenta no tiene un identificador válido.',
      );
    }

    if (monto <= 0) {
      throw const ValidationFailure(
        'El monto del pago debe ser mayor que cero.',
      );
    }

    final saldo = cuenta.balancePendiente;
    if (saldo <= 0) {
      throw const ValidationFailure('Esta cuenta ya está saldada.');
    }

    // Tolerancia de un centavo para no rechazar un pago total por errores de
    // redondeo de punto flotante al prellenar el monto con el saldo.
    if (monto > saldo + 0.01) {
      throw ValidationFailure(
        'El monto (${monto.toStringAsFixed(2)}) excede el saldo pendiente '
        '(${saldo.toStringAsFixed(2)}).',
      );
    }

    return _repository.registrarPago(
      cuentaId: cuentaId,
      monto: monto,
      metodo: metodo,
    );
  }
}
