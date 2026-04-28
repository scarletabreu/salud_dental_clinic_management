import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';

class DiagnosticoAplicadoModel extends DiagnosticoAplicado {
  DiagnosticoAplicadoModel({
    required super.id,
    required super.diagnosisId,
    required super.severidad,
    required super.fechaAplicacion,
    required super.notas,
  });

  factory DiagnosticoAplicadoModel.fromJson(Map<String, dynamic> json) {
    return DiagnosticoAplicadoModel(
      id: json['id'] as String,
      diagnosisId: json['diagnosis_id'] ?? json['diagnosisId'],
      severidad: SeveridadDiagnosis.values.firstWhere(
        (e) => e.name == json['severidad'],
        orElse: () => SeveridadDiagnosis.leve,
      ),
      fechaAplicacion: DateTime.parse(
        json['fecha_aplicacion'] ?? json['fechaAplicacion'],
      ),
      notas: json['notas'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'diagnosis_id': diagnosisId,
      'severidad': severidad.name,
      'fecha_aplicacion': fechaAplicacion.toIso8601String(),
      'notas': notas,
    };
  }
}
