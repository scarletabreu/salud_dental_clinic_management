enum MetodoPago {
  contado,
  credito;

  String get name {
    switch (this) {
      case MetodoPago.contado:
        return 'Contado';
      case MetodoPago.credito:
        return 'Crédito';
    }
  }
}