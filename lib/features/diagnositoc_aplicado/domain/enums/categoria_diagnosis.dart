enum CategoriaDiagnosis {
  caries,
  periodontitis,
  endodoncia,
  ortodoncia,
  protesis,
  implantologia,
  cirugiaOral,
  odontopediatria;

  String get name {
    switch (this) {
      case CategoriaDiagnosis.caries:
        return 'Caries';
      case CategoriaDiagnosis.periodontitis:
        return 'Periodontitis';
      case CategoriaDiagnosis.endodoncia:
        return 'Endodoncia';
      case CategoriaDiagnosis.ortodoncia:
        return 'Ortodoncia';
      case CategoriaDiagnosis.protesis:
        return 'Protesis';
      case CategoriaDiagnosis.implantologia:
        return 'Implantologia';
      case CategoriaDiagnosis.cirugiaOral:
        return 'Cirugia Oral';
      case CategoriaDiagnosis.odontopediatria:
        return 'Odontopediatria';
    }
  }
}
