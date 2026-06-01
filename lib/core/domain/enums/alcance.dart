enum Alcance {
  puntual,
  diente,
  arcada,
  global;

  String get dbValue => name.toLowerCase();
  String get displayName => name[0].toUpperCase() + name.substring(1);
}
