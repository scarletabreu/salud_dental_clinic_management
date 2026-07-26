/// El acto clínico que el doctor abrió.
///
/// Una evaluación documenta lo encontrado y puede proponer un plan. Una
/// consulta ejecuta actividades del plan o deja justificada una excepción.
enum TipoAtencionClinica {
  evaluacion,
  consulta;

  String get etiqueta =>
      this == TipoAtencionClinica.evaluacion ? 'Evaluación' : 'Consulta';

  String get accion => this == TipoAtencionClinica.evaluacion
      ? 'Evaluar y planificar'
      : 'Realizar tratamiento';

  String get descripcion => this == TipoAtencionClinica.evaluacion
      ? 'Registra hallazgos y prepara el plan, sin realizar tratamientos.'
      : 'Registra los tratamientos realizados durante esta cita.';

  static TipoAtencionClinica fromDb(String? value) =>
      value == 'evaluacion' ? evaluacion : consulta;
}
