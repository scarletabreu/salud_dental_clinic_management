/// Motivo con el que se mueve el stock de un consumible.
///
/// [ajustables] son los únicos que `ajustar_stock_consumible` admite. Los otros
/// dos existen sólo para leer el historial: los escriben el cierre de consulta
/// (`consumoClinico`) y la recepción de una compra (`compra_recibida`), cada uno
/// por su propia vía transaccional. El desplegable de ajuste los ofrecía todos,
/// así que elegir «Compra recibida» respondía `22023 · El motivo del ajuste no
/// es válido`.
enum MotivoAjusteStock {
  merma('merma', 'Merma'),
  correccion('correccion', 'Corrección'),
  usoInterno('usoInterno', 'Uso interno'),
  consumoClinico('consumoClinico', 'Consumo clínico'),
  compraRecibida('compra_recibida', 'Compra recibida');

  const MotivoAjusteStock(this.dbValue, this.etiqueta);

  final String dbValue;
  final String etiqueta;

  /// Lo que un ajuste manual puede declarar. El resto lo escribe el servidor.
  static const List<MotivoAjusteStock> ajustables = [
    MotivoAjusteStock.merma,
    MotivoAjusteStock.correccion,
    MotivoAjusteStock.usoInterno,
  ];

  static MotivoAjusteStock? fromDb(String? valor) {
    if (valor == null) return null;
    for (final motivo in MotivoAjusteStock.values) {
      if (motivo.dbValue == valor) return motivo;
    }
    return null;
  }
}
