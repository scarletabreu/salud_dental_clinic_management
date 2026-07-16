enum MetodoPago {
  tarjetaCredito,
  tarjetaDebito,
  transferenciaBancaria,
  efectivo;

  /// Etiqueta legible para la UI (chips, resúmenes). NO se persiste.
  String get name {
    switch (this) {
      case MetodoPago.tarjetaCredito:
        return 'Tarjeta de Crédito';
      case MetodoPago.tarjetaDebito:
        return 'Tarjeta de Débito';
      case MetodoPago.transferenciaBancaria:
        return 'Transferencia Bancaria';
      case MetodoPago.efectivo:
        return 'Efectivo';
    }
  }

  /// Valor persistido: coincide 1:1 con los labels del enum `metodo_pago` de
  /// Postgres. Es lo que viaja a la BD y lo que se lee de vuelta; el label de
  /// [name] es solo para mostrar y no debe usarse para serializar.
  String get dbValue {
    switch (this) {
      case MetodoPago.tarjetaCredito:
        return 'tarjeta_credito';
      case MetodoPago.tarjetaDebito:
        return 'tarjeta_debito';
      case MetodoPago.transferenciaBancaria:
        return 'transferencia_bancaria';
      case MetodoPago.efectivo:
        return 'efectivo';
    }
  }

  /// Reconstruye el método a partir del valor almacenado en BD. Cae en
  /// [efectivo] si el valor es nulo o desconocido.
  static MetodoPago fromDbValue(String? value) {
    return MetodoPago.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => MetodoPago.efectivo,
    );
  }
}
