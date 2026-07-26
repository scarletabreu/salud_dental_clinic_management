/// El acto clínico que el doctor abrió.
///
/// Una evaluación documenta lo encontrado y puede proponer un plan. Una
/// consulta ejecuta actividades del plan o deja justificada una excepción.
enum TipoAtencionClinica {
  evaluacion,
  consulta;

  String get etiqueta =>
      this == TipoAtencionClinica.evaluacion ? 'Evaluación' : 'Consulta';

  static TipoAtencionClinica fromDb(String? value) =>
      value == 'evaluacion' ? evaluacion : consulta;
}
