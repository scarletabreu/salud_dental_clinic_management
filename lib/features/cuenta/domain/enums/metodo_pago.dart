/// Modo de pago pactado para una cuenta: se cobra al momento o queda a crédito.
///
/// No confundir con `pago/domain/enums/metodo_pago.dart`, que es el medio con
/// el que entra cada abono (efectivo, tarjeta…). El enum de Postgres detrás de
/// este es `modo_pago`.
enum MetodoPago {
  contado,
  credito;

  /// Etiqueta legible para la UI. NO se persiste.
  String get name {
    switch (this) {
      case MetodoPago.contado:
        return 'Contado';
      case MetodoPago.credito:
        return 'Crédito';
    }
  }

  /// Valor persistido: coincide 1:1 con los labels del enum `modo_pago` de
  /// Postgres.
  ///
  /// Serializar con [name] escribía «Crédito», que la base rechaza, y al leer
  /// tampoco casaba con `credito` —la tilde—, así que toda cuenta a crédito
  /// volvía como contado sin que fallara nada.
  String get dbValue => switch (this) {
    MetodoPago.contado => 'contado',
    MetodoPago.credito => 'credito',
  };

  /// Reconstruye el modo a partir del valor almacenado. Cae en [contado] si el
  /// valor es nulo o desconocido, que es el modo por defecto de la clínica.
  static MetodoPago fromDbValue(String? value) => MetodoPago.values.firstWhere(
    (modo) => modo.dbValue == value?.toLowerCase().trim(),
    orElse: () => MetodoPago.contado,
  );
}
