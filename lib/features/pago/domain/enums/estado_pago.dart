enum EstadoPago {
  pendiente,
  parcial,
  completado,
  fallido,
  cancelado,
  reembolsado,
  vencido;

  String get label {
    return switch (this) {
      EstadoPago.pendiente => 'Pendiente de cobro',
      EstadoPago.parcial => 'Pago parcial / A cuenta',
      EstadoPago.completado => 'Completado',
      EstadoPago.fallido => 'Error en el proceso',
      EstadoPago.cancelado => 'Transacción cancelada',
      EstadoPago.reembolsado => 'Reembolsado / Devuelto',
      EstadoPago.vencido => 'Pago fuera de plazo',
    };
  }
}
