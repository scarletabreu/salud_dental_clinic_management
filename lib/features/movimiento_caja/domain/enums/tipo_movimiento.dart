enum TipoMovimiento {
  ingreso,
  egreso;

  String get name => toString().split('.').last;

  String get displayName {
    switch (this) {
      case TipoMovimiento.ingreso:
        return 'Ingreso';
      case TipoMovimiento.egreso:
        return 'Egreso';
    }
  }
}
