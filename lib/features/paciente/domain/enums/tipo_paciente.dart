enum TipoPaciente {
  emergencia,
  integrado;

  String get name => toString().split('.').last;

    String get label {
      switch (this) {
        case TipoPaciente.emergencia: return 'Emergencia';
        case TipoPaciente.integrado: return 'Integrado';
      }
  }
}