/// Se lanza al intentar cancelar una cita cuya consulta sigue abierta.
///
/// Dejar la cita "Cancelada" con su consulta "En curso" era la forma más
/// visible del desfase entre la agenda y la lista de consultas (SD-160): dos
/// pantallas afirmando cosas distintas sobre el mismo acto clínico. El orden
/// correcto es cerrar o eliminar la consulta y después cancelar la cita.
class CancelacionConConsultaAbierta implements Exception {
  const CancelacionConConsultaAbierta();

  @override
  String toString() =>
      'Esta cita tiene una consulta en curso. Finaliza o elimina la consulta '
      'antes de cancelar la cita.';
}
