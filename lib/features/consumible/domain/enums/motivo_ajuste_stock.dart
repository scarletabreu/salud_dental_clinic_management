enum MotivoAjusteStock {
  merma('Merma'),
  correccion('Corrección'),
  usoInterno('Uso interno');

  const MotivoAjusteStock(this.etiqueta);

  final String etiqueta;
}
