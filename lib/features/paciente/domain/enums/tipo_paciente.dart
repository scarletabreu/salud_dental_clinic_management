enum TipoPaciente {
  emergencia,
  integrado;

  String get name => toString().split('.').last;
}