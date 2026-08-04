/// Estados de una compra, alineados con el enum `estado_compra` de Postgres.
///
/// El enum de la base nació con etiquetas duplicadas (`completada` y `recibido`
/// son sinónimos históricos de `recibida`) y con una tilde en `envíada`.
/// Postgres no permite borrar etiquetas, así que la migración
/// `audit_001_inventario_compras` normalizó los datos y dejó un CHECK que
/// impide volver a escribir las legadas. Aquí se persiste siempre [dbValue],
/// nunca `.name`: escribir el nombre de Dart producía `22P02` en cada intento
/// de avanzar o cancelar una compra.
enum EstadoCompra {
  pendiente('pendiente', 'Pendiente'),
  enviada('envíada', 'Enviada'),
  recibida('recibida', 'Recibida'),
  cancelada('cancelada', 'Cancelada');

  const EstadoCompra(this.dbValue, this.etiqueta);

  final String dbValue;
  final String etiqueta;

  /// Etiquetas legadas que la base todavía puede devolver en filas antiguas.
  static const Map<String, EstadoCompra> _legado = {
    'completada': EstadoCompra.recibida,
    'recibido': EstadoCompra.recibida,
  };

  /// Traduce lo que devuelve la base. Devuelve `null` para una etiqueta
  /// desconocida en vez de caer en «pendiente»: un estado inventado que parece
  /// plausible es peor que un fallo visible —una compra ya recibida se mostraba
  /// como pendiente y volvía a ofrecerse para recibir—.
  static EstadoCompra? fromDb(String? valor) {
    if (valor == null) return null;
    for (final estado in EstadoCompra.values) {
      if (estado.dbValue == valor) return estado;
    }
    return _legado[valor];
  }
}
