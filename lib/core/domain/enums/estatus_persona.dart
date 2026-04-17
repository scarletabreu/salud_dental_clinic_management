enum EstatusPersona {
  activo,
  inactivo;

  String get name => toString().split('.').last;

  String get displayName {
    switch (this) {
      case EstatusPersona.activo:
        return 'Activo';
      case EstatusPersona.inactivo:
        return 'Inactivo';
    }
  }
}
