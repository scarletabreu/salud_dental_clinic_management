enum EstadoCompra {
  pendiente,
  aprovado,
  recibido,
  enviado,
  cancelado;

  String get name => toString().split('.').last;
}
