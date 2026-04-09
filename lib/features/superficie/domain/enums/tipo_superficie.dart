enum TipoSuperficie {
  mesial,
  distal,
  vestibular,
  lingual,
  palatina,
  oclusal,
  incisal;

  String get name {
    switch (this) {
      case TipoSuperficie.mesial:
        return 'Mesial';
      case TipoSuperficie.distal:
        return 'Distal';
      case TipoSuperficie.vestibular:
        return 'Vestibular';
      case TipoSuperficie.lingual:
        return 'Lingual';
      case TipoSuperficie.palatina:
        return 'Palatina';
      case TipoSuperficie.oclusal:
        return 'Oclusal';
      case TipoSuperficie.incisal:
        return 'Incisal';
    }
  }
}
