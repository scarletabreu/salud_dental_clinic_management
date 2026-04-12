enum PersonaEstatus {
  activo,
  inactivo;

  String get name => toString().split('.').last;

  String get displayName {
    switch (this) {
      case PersonaEstatus.activo:
        return 'Activo';
      case PersonaEstatus.inactivo:
        return 'Inactivo';
    }
  }
}
