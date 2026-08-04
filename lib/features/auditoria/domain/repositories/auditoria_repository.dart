import 'package:salud_dental_clinic_management/features/auditoria/domain/entities/evento_auditoria.dart';

abstract class AuditoriaRepository {
  /// Historia clínica y administrativa de una consulta, en orden cronológico.
  Future<List<EventoAuditoria>> getLineaTiempo(String consultaId);
}
