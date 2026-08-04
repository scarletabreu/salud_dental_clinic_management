enum SeveridadDiagnosis { leve, moderada, grave }

extension SeveridadDiagnosisX on SeveridadDiagnosis {
  String get etiqueta => switch (this) {
    SeveridadDiagnosis.leve => 'Leve',
    SeveridadDiagnosis.moderada => 'Moderado',
    SeveridadDiagnosis.grave => 'Grave',
  };
}
