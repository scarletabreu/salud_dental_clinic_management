import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/estado_cuenta.dart';

sealed class CuentaException implements Exception {
  final String message;
  const CuentaException(this.message);
  @override
  String toString() => message;
}

class TransicionInvalidaException extends CuentaException {
  TransicionInvalidaException(EstadoCuenta desde, EstadoCuenta hacia)
    : super('No se puede pasar de $desde a $hacia');
}

class ModoPagoNoPermitidoException extends CuentaException {
  ModoPagoNoPermitidoException()
    : super('Pacientes de EMERGENCIA solo pueden pagar AL_CONTADO');
}

class AjusteRequiereAutorizacionException extends CuentaException {
  AjusteRequiereAutorizacionException()
    : super('El ajuste requiere autorización de un doctor');
}

class SaldoInsuficienteException extends CuentaException {
  SaldoInsuficienteException()
    : super('No se puede saldar: monto pagado menor al monto total');
}
