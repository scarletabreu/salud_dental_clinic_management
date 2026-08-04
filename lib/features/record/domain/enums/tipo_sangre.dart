enum TipoSangre {
  aPositivo('A+', 'a_positivo'),
  aNegativo('A-', 'a_negativo'),
  bPositivo('B+', 'b_positivo'),
  bNegativo('B-', 'b_negativo'),
  abPositivo('AB+', 'ab_positivo'),
  abNegativo('AB-', 'ab_negativo'),
  oPositivo('O+', 'o_positivo'),
  oNegativo('O-', 'o_negativo'),
  desconocido('-', 'desconocido');

  /// Cómo se muestra en pantalla.
  final String valor;

  /// Cómo se llama la etiqueta en el enum `public.tipo_sangre` de Postgres.
  ///
  /// No sirve `name`: Dart nombra las constantes en camelCase y la base en
  /// snake_case, así que enviar `name` producía `oPositivo`, Postgres rechazaba
  /// el cast con `22P02` y la transacción entera de `registrar_paciente` hacía
  /// rollback. La única etiqueta que coincidía en ambas grafías era
  /// `desconocido`, que es justo la que hacía parecer que no pasaba nada.
  final String dbValue;

  const TipoSangre(this.valor, this.dbValue);

  /// Reconstruye el enum desde lo que devuelve la base.
  ///
  /// Acepta también el camelCase escrito antes de esta corrección, para no
  /// degradar a `desconocido` las fichas que hubieran llegado a guardarse con
  /// la grafía vieja.
  static TipoSangre desdeDb(Object? valor) {
    if (valor == null) return TipoSangre.desconocido;
    final texto = valor.toString();
    for (final tipo in TipoSangre.values) {
      if (tipo.dbValue == texto || tipo.name == texto) return tipo;
    }
    return TipoSangre.desconocido;
  }
}
