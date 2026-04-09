enum EstadoCuota {
  pendiente,
  pagada,
  atrasada,
  venciada,
  cancelada;

  String get name => toString().split('.').last;
}
