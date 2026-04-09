enum EstadoPago {
  pendiente,
  cancelada,
  recibido,
  errado;

  String get name {
    switch (this) {
      case EstadoPago.pendiente:
        return 'Pendiente';
      case EstadoPago.cancelada:
        return 'Cancelada';
      case EstadoPago.recibido:
        return 'Recibido';
      case EstadoPago.errado:
        return 'Errado';
    }
  }
}
