enum CategoriaDiagnosis {
  preventiva,
  caries,
  endodoncia,
  periodoncia,
  ortodoncia,
  protesis,
  implantes,
  cirugiaOral,
  estetica,
  patologiaATM;

  String get dbValue => switch (this) {
    CategoriaDiagnosis.periodoncia => 'periodontitis',
    CategoriaDiagnosis.cirugiaOral => 'cirurgia_oral',
    CategoriaDiagnosis.patologiaATM => 'patologia_atm',
    _ => name,
  };

  static CategoriaDiagnosis fromDb(String value) =>
      CategoriaDiagnosis.values.firstWhere(
        (categoria) => categoria.dbValue == value,
        orElse: () => CategoriaDiagnosis.caries,
      );

  String get nombre => name[0].toUpperCase() + name.substring(1);
}
