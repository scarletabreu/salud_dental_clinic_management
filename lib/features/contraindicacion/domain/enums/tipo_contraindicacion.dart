enum TipoContraindicacion {
  absoluta,
  relativa;

  String get name {
    switch (this) {
      case TipoContraindicacion.absoluta:
        return 'Absoluta';
      case TipoContraindicacion.relativa:
        return 'Relativa';
    }
  }
}