enum Genero { masculino, femenino, otro, noPrefiereDecir;

  String get label {
      switch (this) {
        case Genero.masculino: return 'Masculino';
        case Genero.femenino: return 'Femenino';
        case Genero.otro: return 'Otro';
        case Genero.noPrefiereDecir: return 'No Prefiere Decir';
      }
  }
}