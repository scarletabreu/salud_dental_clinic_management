enum TipoCondicion {
  fisiologica,
  patologica,
  quirurgica,
  genetica,
  alergica;

  String get name => toString().split('.').last;

  String get displayName {
    switch (this) {
      case TipoCondicion.fisiologica:
        return 'Fisiológica';
      case TipoCondicion.patologica:
        return 'Patológica';
      case TipoCondicion.quirurgica:
        return 'Quirúrgica';
      case TipoCondicion.genetica:
        return 'Genética';
      case TipoCondicion.alergica:
        return 'Alérgica';
    }
  }
}