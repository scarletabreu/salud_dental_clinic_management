enum CondicionMedica {
  diabetes,
  embarazo,
  hipertension,
  ulceraPeptica,
  alergiaAntibioticos,
  hepatopatia,
  arritmia,
  colitis;

  String get label {
    switch (this) {
      case CondicionMedica.diabetes:
        return 'Diabetes';
      case CondicionMedica.embarazo:
        return 'Embarazo';
      case CondicionMedica.hipertension:
        return 'Hipertensión';
      case CondicionMedica.ulceraPeptica:
        return 'Úlcera péptica';
      case CondicionMedica.alergiaAntibioticos:
        return 'Alergia a antibióticos';
      case CondicionMedica.hepatopatia:
        return 'Hepatopatía';
      case CondicionMedica.arritmia:
        return 'Arritmia';
      case CondicionMedica.colitis:
        return 'Colitis';
    }
  }
}
