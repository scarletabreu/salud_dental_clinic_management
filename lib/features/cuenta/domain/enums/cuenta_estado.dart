enum CuentaEstado {
  abierta,
  pendiente,
  saldada,
  cancelada;

  String get name => toString().split('.').last;
}