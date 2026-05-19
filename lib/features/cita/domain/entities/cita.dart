import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/persona.dart';

class Cita {
  final String? id;
  final Doctor doctor;
  final Persona persona;
  final DateTime date;
  final bool esEmergencia;
  final EstadoCita estado;

  Cita({
    this.id,
    required this.doctor,
    required this.persona,
    required this.date,
    required this.esEmergencia,
    required this.estado,
  });

  Cita copyWith({
    String? id,
    Doctor? doctor,
    Persona? persona,
    DateTime? date,
    bool? esEmergencia,
    EstadoCita? estado,
  }) {
    return Cita(
      id: id ?? this.id,
      doctor: doctor ?? this.doctor,
      persona: persona ?? this.persona,
      date: date ?? this.date,
      esEmergencia: esEmergencia ?? this.esEmergencia,
      estado: estado ?? this.estado,
    );
  }
}
