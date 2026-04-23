enum TipoSangre {
  aPositivo('A+'),
  aNegativo('A-'),
  bPositivo('B+'),
  bNegativo('B-'),
  abPositivo('AB+'),
  abNegativo('AB-'),
  oPositivo('O+'),
  oNegativo('O-'),
  desconocido('-');

  final String valor;
  const TipoSangre(this.valor);
}
