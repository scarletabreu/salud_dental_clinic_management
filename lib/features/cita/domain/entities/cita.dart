import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/persona.dart';

class Cita {
  final Doctor doctor;
  final Persona persona;
  final DateTime date;
  final bool esEmergencia;
  final EstadoCita estado;

  Cita({
    required this.doctor,
    required this.persona,
    required this.date,
    required this.esEmergencia,
    required this.estado,
  });
}
