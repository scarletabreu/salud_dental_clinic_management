enum CondicionMedica {
  // Endocrino y Estado
  diabetes,
  embarazo,
  tiroidismo,

  // Cardiovascular (Riesgo de Anestesia/Sangrado)
  hipertension,
  arritmia,
  cardiopatiaIsquemica,
  portadorMarcapasos,
  anticoagulado,

  // Infecciosas y Sistema Inmune
  vihSida,
  hepatitis,
  inmunodepresion,

  // Alergias (Cruciales)
  alergiaAntibioticos,
  alergiaLatex,
  alergiaAnestesia,
  alergiaAines,

  // Digestivo y Otros
  ulceraPeptica,
  colitis,
  insuficienciaRenal,
  osteoporosisBisfosfonatos,
  asma;

  String get label {
    return switch (this) {
      CondicionMedica.diabetes => 'Diabetes Mellitus',
      CondicionMedica.embarazo => 'Embarazo en curso',
      CondicionMedica.tiroidismo => 'Alteraciones tiroideas',
      CondicionMedica.hipertension => 'Hipertensión arterial',
      CondicionMedica.arritmia => 'Arritmia cardíaca',
      CondicionMedica.cardiopatiaIsquemica => 'Cardiopatía isquémica',
      CondicionMedica.portadorMarcapasos => 'Portador de marcapasos',
      CondicionMedica.anticoagulado => 'Paciente anticoagulado',
      CondicionMedica.vihSida => 'VIH/SIDA',
      CondicionMedica.hepatitis => 'Hepatitis (B, C o crónica)',
      CondicionMedica.inmunodepresion => 'Inmunodepresión / Quimioterapia',
      CondicionMedica.alergiaAntibioticos => 'Alergia a antibióticos',
      CondicionMedica.alergiaLatex => 'Alergia al látex',
      CondicionMedica.alergiaAnestesia => 'Alergia a anestésicos locales',
      CondicionMedica.alergiaAines => 'Alergia a AINEs (Aspirina/Ibuprofeno)',
      CondicionMedica.ulceraPeptica => 'Úlcera péptica',
      CondicionMedica.colitis => 'Colitis ulcerosa / Crohn',
      CondicionMedica.insuficienciaRenal => 'Insuficiencia renal',
      CondicionMedica.osteoporosisBisfosfonatos =>
        'Tratamiento con bisfosfonatos',
      CondicionMedica.asma => 'Asma bronquial',
    };
  }
}
