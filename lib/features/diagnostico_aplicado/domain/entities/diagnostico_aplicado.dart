import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';

class DiagnosticoAplicado {
  final String id;
  final String diagnosisId;
  final SeveridadDiagnosis severidad;
  final DateTime fechaAplicacion;
  final String notas;

  DiagnosticoAplicado({
    required this.id,
    required this.diagnosisId,
    required this.severidad,
    required this.fechaAplicacion,
    required this.notas,
  });

  DiagnosticoAplicado copyWith({
    String? diagnosisId,
    SeveridadDiagnosis? severidad,
    DateTime? fechaAplicacion,
    String? notas,
  }) {
    return DiagnosticoAplicado(
      id: id,
      diagnosisId: diagnosisId ?? this.diagnosisId,
      severidad: severidad ?? this.severidad,
      fechaAplicacion: fechaAplicacion ?? this.fechaAplicacion,
      notas: notas ?? this.notas,
    );
  }
}
