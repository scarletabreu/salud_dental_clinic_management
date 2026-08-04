enum EstadoCuota {
  pendiente,
  pagada,
  atrasada,
  vencida,
  cancelada;

  String get name => toString().split('.').last;
}
