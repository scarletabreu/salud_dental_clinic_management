enum EstadoCompra {
  pendente,
  aprovado,
  recibido,
  enviado,
  cancelado;

  String get name => toString().split('.').last;
}