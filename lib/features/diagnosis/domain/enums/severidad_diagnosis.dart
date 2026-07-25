enum SeveridadDiagnosis { leve, moderada, grave }

extension SeveridadDiagnosisX on SeveridadDiagnosis {
  /// Cómo se nombra la severidad en pantalla y en la ficha de la pieza.
  String get etiqueta => switch (this) {
    SeveridadDiagnosis.leve => 'Leve',
    SeveridadDiagnosis.moderada => 'Moderado',
    SeveridadDiagnosis.grave => 'Grave',
  };
}
