/// Qué encontró la base al pedirle la consulta de una cita.
///
/// Iniciar una consulta dejó de ser «crear una fila»: la RPC bloquea la cita y
/// responde con lo que ya existe. Un doble toque, una red lenta o volver a
/// entrar mañana llevan al mismo sitio en vez de chocar contra el índice único.
enum EstadoInicioConsulta {
  /// No había ninguna: se creó ahora y la cita quedó en consulta.
  creada,

  /// Ya había una abierta: se sigue trabajando sobre ella.
  reanudada,

  /// La cita ya fue atendida. Se puede consultar, no reabrir.
  finalizada,
}

class InicioConsulta {
  final String consultaId;
  final EstadoInicioConsulta estado;

  const InicioConsulta({required this.consultaId, required this.estado});

  factory InicioConsulta.fromJson(Map<String, dynamic> json) {
    final id = json['consulta_id'] as String?;
    if (id == null) {
      throw const FormatException(
        'La base no devolvió el identificador de la consulta.',
      );
    }
    return InicioConsulta(
      consultaId: id,
      estado: switch (json['estado'] as String?) {
        'reanudada' => EstadoInicioConsulta.reanudada,
        'finalizada' => EstadoInicioConsulta.finalizada,
        _ => EstadoInicioConsulta.creada,
      },
    );
  }
}
