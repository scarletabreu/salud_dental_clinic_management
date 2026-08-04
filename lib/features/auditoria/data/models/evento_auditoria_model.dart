import 'package:salud_dental_clinic_management/features/auditoria/domain/entities/evento_auditoria.dart';

abstract final class EventoAuditoriaModel {
  static EventoAuditoria fromJson(Map<String, dynamic> json) {
    return EventoAuditoria(
      id: json['id'] as String,
      evento: json['evento'] as String? ?? '',
      categoria: CategoriaEventoX.fromDb(json['categoria'] as String?),
      // `ocurrido_en` viaja en UTC; la pantalla lo lee en la hora de la clínica.
      ocurridoEn:
          DateTime.tryParse(json['ocurrido_en'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      actorId: json['actor_id'] as String?,
      actorNombre: json['actor_nombre'] as String?,
      rol: json['rol'] as String?,
      motivo: json['motivo'] as String?,
      metadata: switch (json['metadata']) {
        final Map<String, dynamic> mapa => mapa,
        final Map mapa => Map<String, dynamic>.from(mapa),
        _ => const {},
      },
    );
  }
}
