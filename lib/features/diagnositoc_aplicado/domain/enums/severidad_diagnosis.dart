enum SeveridadDiagnosis {
  leve,
  moderada,
  grave;

  String get nameCapitalized {
    switch (this) {
      case SeveridadDiagnosis.leve:
        return 'Leve';
      case SeveridadDiagnosis.moderada:
        return 'Moderada';
      case SeveridadDiagnosis.grave:
        return 'Grave';
    }
  }
}
