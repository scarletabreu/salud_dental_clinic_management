/// En qué eje de la consulta ocurrió el evento. Sale de la base
/// (`linea_tiempo_consulta.categoria`) para que la pantalla no tenga que
/// reinterpretar el nombre del evento.
enum CategoriaEvento { agenda, clinico, plan, receta, alerta, correccion }

extension CategoriaEventoX on CategoriaEvento {
  static CategoriaEvento fromDb(String? valor) => switch (valor) {
    'agenda' => CategoriaEvento.agenda,
    'plan' => CategoriaEvento.plan,
    'receta' => CategoriaEvento.receta,
    'alerta' => CategoriaEvento.alerta,
    'correccion' => CategoriaEvento.correccion,
    _ => CategoriaEvento.clinico,
  };

  String get etiqueta => switch (this) {
    CategoriaEvento.agenda => 'Agenda',
    CategoriaEvento.clinico => 'Clínico',
    CategoriaEvento.plan => 'Plan',
    CategoriaEvento.receta => 'Receta',
    CategoriaEvento.alerta => 'Alerta',
    CategoriaEvento.correccion => 'Corrección',
  };
}

/// Un hecho de la historia de una consulta, tal como lo registró la base.
///
/// La aplicación no fabrica eventos ni los edita: los triggers de HFX-CLIN-005
/// son la única fuente. Aquí solo se leen.
class EventoAuditoria {
  final String id;

  /// Código estable del evento (`consulta_guardada`, `receta_emitida`…). Se
  /// conserva crudo además de la descripción: es lo que permite correlacionar
  /// un soporte con la base sin depender del texto de pantalla.
  final String evento;
  final CategoriaEvento categoria;
  final DateTime ocurridoEn;
  final String? actorId;
  final String? actorNombre;
  final String? rol;
  final String? motivo;
  final Map<String, dynamic> metadata;

  const EventoAuditoria({
    required this.id,
    required this.evento,
    required this.categoria,
    required this.ocurridoEn,
    this.actorId,
    this.actorNombre,
    this.rol,
    this.motivo,
    this.metadata = const {},
  });

  /// Quién lo hizo, en el lenguaje de la clínica. Un evento sin sesión —una
  /// migración, un script de mantenimiento— dice «Sistema» en vez de atribuirle
  /// el acto a alguien.
  String get autor {
    final nombre = actorNombre?.trim();
    if (nombre != null && nombre.isNotEmpty) {
      return rol == null ? nombre : '$nombre · ${_rolEtiqueta(rol!)}';
    }
    if (rol == 'sistema' || actorId == null) return 'Sistema';
    return _rolEtiqueta(rol!);
  }

  static String _rolEtiqueta(String rol) => switch (rol) {
    'admin' => 'Administración',
    'doctor' => 'Doctor',
    'asistente' => 'Asistente',
    'sistema' => 'Sistema',
    _ => rol,
  };

  /// Qué pasó, dicho para el expediente. La terminología es la misma que usa el
  /// resto de la aplicación (HFX-CLIN-005): emitida, anulada, reemplazada,
  /// ejecutado, aceptado.
  String get descripcion => switch (evento) {
    'cita_creada' => esEmergencia ? 'Cita de emergencia creada' : 'Cita creada',
    'cita_llegada' => 'Llegada del paciente registrada',
    'cita_en_consulta' => 'Paciente pasó a consulta',
    'cita_completada' => 'Cita completada',
    'cita_cancelada' => 'Cita cancelada',
    'cita_no_asistio' => 'El paciente no asistió',
    'cita_reprogramada' => 'Cita reprogramada',
    'cita_eliminada' => 'Cita eliminada',
    'cita_estado_cambiado' => 'Estado de la cita cambiado',
    'consulta_iniciada' => 'Consulta iniciada',
    'consulta_guardada' => 'Trabajo clínico guardado',
    'consulta_cerrada' => 'Consulta finalizada',
    'diagnostico_agregado' => 'Diagnóstico añadido${_de('diagnostico')}',
    'diagnostico_retirado' => 'Diagnóstico retirado${_de('diagnostico')}',
    'tratamiento_ejecutado' => 'Tratamiento ejecutado${_de('tratamiento')}',
    'tratamiento_actualizado' => 'Tratamiento actualizado${_de('tratamiento')}',
    'tratamiento_anulado' => 'Tratamiento anulado${_de('tratamiento')}',
    'receta_emitida' => 'Receta emitida',
    'receta_anulada' => 'Receta anulada',
    'receta_reemplazada' => 'Receta reemplazada',
    'plan_propuesto' => 'Plan de tratamiento propuesto',
    'plan_aceptado' => 'Plan de tratamiento aceptado',
    'plan_rechazado' => 'Plan de tratamiento rechazado',
    'consentimiento_aceptado' => 'Consentimiento aceptado',
    'consentimiento_rechazado' => 'Consentimiento rechazado',
    'alerta_emitida' => 'Alerta clínica emitida',
    'alerta_resuelta' => 'Alerta clínica resuelta',
    'correccion_administrativa' => 'Corrección administrativa',
    _ => evento.replaceAll('_', ' '),
  };

  bool get esEmergencia => metadata['es_emergencia'] == true;

  String _de(String clave) {
    final valor = metadata[clave];
    return valor is String && valor.trim().isNotEmpty ? ': $valor' : '';
  }
}
