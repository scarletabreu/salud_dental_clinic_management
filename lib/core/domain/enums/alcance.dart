enum Alcance {
  puntual,
  diente,
  arcada,
  global;

  String get name {
    switch (this) {
      case Alcance.puntual:
        return 'Puntual';
      case Alcance.diente:
        return 'Diente';
      case Alcance.arcada:
        return 'Arcada';
      case Alcance.global:
        return 'Global';
    }
  }
}
