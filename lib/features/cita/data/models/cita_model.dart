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
    super.duracionMinutos = 30,
    required super.esEmergencia,
    required super.estado,
    super.motivo,
  });

  /// Un motivo en blanco es "sin motivo": así el campo vacío del formulario no
  /// se guarda como cadena vacía ni se pinta como si el paciente hubiera dicho
  /// algo.
  static String? normalizarMotivo(String? valor) {
    final limpio = valor?.trim() ?? '';
    return limpio.isEmpty ? null : limpio;
  }

  factory CitaModel.fromJson(Map<String, dynamic> json) {
    final String? fechaRaw = json['fecha'] ?? json['fecha_hora'];

    if (fechaRaw == null) {
      throw Exception(
        'Error de mapeo: La columna de fecha no se encuentra en el payload de la cita.',
      );
    }

    return CitaModel(
      id: json['id'] as String?,
      // dev aplanó el payload del doctor: la cita ya no trae el embed anidado.
      doctor: DoctorModel.fromJsonFn(json['doctor'] as Map<String, dynamic>),
      persona: PersonaModel.fromJson(json['persona']),
      date: DateTime.parse(fechaRaw).toLocal(),
      duracionMinutos: (json['duracion_minutos'] as num?)?.toInt() ?? 30,
      esEmergencia: json['es_emergencia'] ?? false,
      estado: EstadoCita.fromDb(json['estado'] as String?),
      motivo: normalizarMotivo(json['motivo'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'doctor_id': doctor.id,
      'persona_id': persona.id,
      'fecha_hora': date.toUtc().toIso8601String(),
      'duracion_minutos': duracionMinutos,
      'es_emergencia': esEmergencia,
      'estado': estado.dbValue,
      'motivo': normalizarMotivo(motivo),
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
