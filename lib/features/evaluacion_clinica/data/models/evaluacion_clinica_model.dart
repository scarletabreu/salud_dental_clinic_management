import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/data/models/diagnostico_aplicado_model.dart';
import 'package:salud_dental_clinic_management/features/evaluacion_clinica/domain/entities/evaluacion_clinica.dart';

class EvaluacionClinicaModel extends EvaluacionClinica {
  const EvaluacionClinicaModel({
    super.id,
    required super.pacienteId,
    super.consultaId,
    required super.doctorId,
    required super.fecha,
    super.motivo,
    super.resumen,
    super.hallazgos,
  });

  factory EvaluacionClinicaModel.fromEntity(EvaluacionClinica evaluacion) {
    return EvaluacionClinicaModel(
      id: evaluacion.id,
      pacienteId: evaluacion.pacienteId,
      consultaId: evaluacion.consultaId,
      doctorId: evaluacion.doctorId,
      fecha: evaluacion.fecha,
      motivo: evaluacion.motivo,
      resumen: evaluacion.resumen,
      hallazgos: evaluacion.hallazgos,
    );
  }

  factory EvaluacionClinicaModel.fromJson(Map<String, dynamic> json) {
    final hallazgos = (json['hallazgos'] as List?) ?? const [];
    return EvaluacionClinicaModel(
      id: json['id'] as String?,
      pacienteId: json['paciente_id'] as String? ?? '',
      consultaId: json['consulta_id'] as String?,
      doctorId: json['doctor_id'] as String? ?? '',
      fecha: DateTime.tryParse('${json['fecha']}') ?? DateTime.now().toUtc(),
      motivo: json['motivo'] as String?,
      resumen: json['resumen'] as String?,
      hallazgos: [
        for (final hallazgo in hallazgos)
          DiagnosticoAplicadoModel.fromJson(
            Map<String, dynamic>.from(hallazgo as Map),
          ),
      ],
    );
  }

  /// Solo el encabezado: los hallazgos son filas de `diagnosticos_aplicados`.
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'paciente_id': pacienteId,
      'consulta_id': consultaId,
      'doctor_id': doctorId,
      'fecha': fecha.toUtc().toIso8601String(),
      'motivo': motivo,
      'resumen': resumen,
    };

    if (id != null && id!.length == 36 && id!.contains('-')) {
      data['id'] = id;
    }
    return data;
  }
}
