import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';

/// El acto de evaluar al paciente, separado de lo que se decide tratar y de lo
/// que finalmente se ejecuta (SD-135).
///
/// Una evaluación registra cualquier cantidad de [hallazgos]. Ninguno de ellos
/// genera por sí mismo un tratamiento aplicado ni una cuenta: para que algo se
/// trate hay que llevarlo explícitamente al plan de tratamiento, y para que algo
/// se cobre hay que registrar su ejecución.
class EvaluacionClinica {
  final String? id;
  final String pacienteId;

  /// Consulta en la que se hizo. `null` cuando la evaluación ocurre fuera de
  /// una consulta abierta (una revisión rápida, una urgencia).
  final String? consultaId;

  /// Profesional que la realizó. Parte de la auditoría clínica.
  final String doctorId;
  final DateTime fecha;
  final String? motivo;
  final String? resumen;

  /// Todo lo encontrado. Puede estar vacío: evaluar y no hallar nada también es
  /// un resultado clínico que vale la pena dejar asentado.
  final List<DiagnosticoAplicado> hallazgos;

  const EvaluacionClinica({
    this.id,
    required this.pacienteId,
    this.consultaId,
    required this.doctorId,
    required this.fecha,
    this.motivo,
    this.resumen,
    this.hallazgos = const [],
  });

  EvaluacionClinica copyWith({
    String? id,
    String? pacienteId,
    String? consultaId,
    String? doctorId,
    DateTime? fecha,
    String? motivo,
    String? resumen,
    List<DiagnosticoAplicado>? hallazgos,
  }) {
    return EvaluacionClinica(
      id: id ?? this.id,
      pacienteId: pacienteId ?? this.pacienteId,
      consultaId: consultaId ?? this.consultaId,
      doctorId: doctorId ?? this.doctorId,
      fecha: fecha ?? this.fecha,
      motivo: motivo ?? this.motivo,
      resumen: resumen ?? this.resumen,
      hallazgos: hallazgos ?? this.hallazgos,
    );
  }
}
