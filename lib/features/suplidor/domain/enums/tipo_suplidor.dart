enum TipoSuplidor {
  consumible,
  servicio,
  mixto;

  String get name => toString().split('.').last;
}