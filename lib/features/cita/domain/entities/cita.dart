import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/persona.dart';

class Cita {
  final String? id;
  final Doctor doctor;
  final Persona persona;
  final DateTime date;
  final int duracionMinutos;
  final bool esEmergencia;
  final EstadoCita estado;

  /// Lo que dijo el paciente al agendar. Prellena el motivo de la consulta
  /// cuando el odontólogo la atiende desde esta cita, sin reemplazarlo.
  final String? motivo;

  Cita({
    this.id,
    required this.doctor,
    required this.persona,
    required this.date,
    this.duracionMinutos = 30,
    required this.esEmergencia,
    required this.estado,
    this.motivo,
  });

  DateTime get fechaFin => date.add(Duration(minutes: duracionMinutos));

  Cita copyWith({
    String? id,
    Doctor? doctor,
    Persona? persona,
    DateTime? date,
    int? duracionMinutos,
    bool? esEmergencia,
    EstadoCita? estado,
    String? motivo,
  }) {
    return Cita(
      id: id ?? this.id,
      doctor: doctor ?? this.doctor,
      persona: persona ?? this.persona,
      date: date ?? this.date,
      duracionMinutos: duracionMinutos ?? this.duracionMinutos,
      esEmergencia: esEmergencia ?? this.esEmergencia,
      estado: estado ?? this.estado,
      motivo: motivo ?? this.motivo,
    );
  }
}
