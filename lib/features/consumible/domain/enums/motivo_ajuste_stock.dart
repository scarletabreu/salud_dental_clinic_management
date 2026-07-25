enum MotivoAjusteStock {
  merma('Merma'),
  correccion('Corrección'),
  usoInterno('Uso interno'),
  compraRecibida('Compra recibida');

  const MotivoAjusteStock(this.etiqueta);

  final String etiqueta;
}
