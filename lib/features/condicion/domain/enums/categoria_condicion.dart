enum CategoriaCondicion {
  temporal,
  cronica;

  String get name => toString().split('.').last;

  String get displayName {
    switch (this) {
      case CategoriaCondicion.temporal:
        return 'Temporal';
      case CategoriaCondicion.cronica:
        return 'Crónica';
    }
  }
}
