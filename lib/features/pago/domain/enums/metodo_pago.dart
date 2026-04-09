enum MetodoPago {
  tarjetaCredito,
  tarjetaDebito,
  transferenciaBancaria,
  efectivo;

  String get name {
    switch (this) {
      case MetodoPago.tarjetaCredito:
        return 'Tarjeta de Crédito';
      case MetodoPago.tarjetaDebito:
        return 'Tarjeta de Débito';
      case MetodoPago.transferenciaBancaria:
        return 'Transferencia Bancaria';
      case MetodoPago.efectivo:
        return 'Efectivo';
    }
  }
}
