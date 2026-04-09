enum AlcanceDiagnosis {
  puntual,
  diente,
  arcada,
  global;

  String get name {
    switch (this) {
      case AlcanceDiagnosis.puntual:
        return 'Puntual';
      case AlcanceDiagnosis.diente:
        return 'Diente';
      case AlcanceDiagnosis.arcada:
        return 'Arcada';
      case AlcanceDiagnosis.global:
        return 'Global';
    }
  }
}
