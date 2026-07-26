/// Clasificación histórica del acto clínico persistido.
///
/// La interfaz ya no obliga al doctor a elegirla al entrar: toda atención abre
/// el mismo workspace. Se conserva para leer registros creados con el flujo
/// anterior; las atenciones nuevas se registran como consulta.
enum TipoAtencionClinica {
  evaluacion,
  consulta;

  String get etiqueta =>
      this == TipoAtencionClinica.evaluacion ? 'Evaluación' : 'Consulta';

  static TipoAtencionClinica fromDb(String? value) =>
      value == 'evaluacion' ? evaluacion : consulta;
}
