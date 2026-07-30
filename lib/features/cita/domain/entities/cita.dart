import 'package:salud_dental_clinic_management/features/cita/domain/entities/actividad_planificada.dart';
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

  /// Actividades del plan de tratamiento que se piensan atender en esta sesión
  /// (SD-146). La cita las referencia por id: no copia el plan como texto, así
  /// que corregir el plan corrige lo que la agenda muestra.
  ///
  /// Vacía no significa "nada que hacer": una cita puede existir sin plan (una
  /// primera evaluación, una emergencia). Es el [motivo] el que dice a qué vino
  /// el paciente cuando no hay actividades.
  final List<ActividadPlanificada> actividades;

  Cita({
    this.id,
    required this.doctor,
    required this.persona,
    required this.date,
    this.duracionMinutos = 30,
    required this.esEmergencia,
    required this.estado,
    this.motivo,
    this.actividades = const [],
  });

  DateTime get fechaFin => date.add(Duration(minutes: duracionMinutos));

  /// Lo que se piensa tratar, en una línea por actividad y en el orden del plan.
  List<String> get resumenActividades {
    final ordenadas = [...actividades]
      ..sort((a, b) => a.orden.compareTo(b.orden));
    return [for (final actividad in ordenadas) actividad.descripcion];
  }

  Cita copyWith({
    String? id,
    Doctor? doctor,
    Persona? persona,
    DateTime? date,
    int? duracionMinutos,
    bool? esEmergencia,
    EstadoCita? estado,
    String? motivo,
    List<ActividadPlanificada>? actividades,
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
      actividades: actividades ?? this.actividades,
    );
  }
}
