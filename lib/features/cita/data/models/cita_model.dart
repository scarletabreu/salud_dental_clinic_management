import 'package:salud_dental_clinic_management/core/data/models/persona_model.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/personal/data/models/doctor_model.dart';

class CitaModel extends Cita {
  CitaModel({
    super.id,
    required super.doctor,
    required super.persona,
    required super.date,
    required super.esEmergencia,
    required super.estado,
  });

  factory CitaModel.fromJson(Map<String, dynamic> json) {
    return CitaModel(
      id: json['id'] as String?,
      doctor: DoctorModel.fromJson(json['doctor']),
      persona: PersonaModel.fromJson(json['persona']),
      date: DateTime.parse(json['fecha_hora']).toLocal(),
      esEmergencia: json['es_emergencia'] ?? false,
      estado: EstadoCita.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EstadoCita.pendiente,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'doctor_id': doctor.id,
      'persona_id': persona.id,
      'fecha_hora': date.toUtc().toIso8601String(),
      'es_emergencia': esEmergencia,
      'estado': estado.name,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
