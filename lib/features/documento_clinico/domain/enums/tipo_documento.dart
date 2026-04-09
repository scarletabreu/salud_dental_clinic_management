enum TipoDocumento {
  imagen,
  video,
  radiografia;

  String get name => toString().split('.').last;
}