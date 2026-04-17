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

  String get nombre => name[0].toUpperCase() + name.substring(1);
}
