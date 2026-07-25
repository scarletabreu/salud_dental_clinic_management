import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

class DiagnosticoAplicadoModel extends DiagnosticoAplicado {
  DiagnosticoAplicadoModel({
    super.id,
    required super.diagnosisId,
    required super.severidad,
    required super.fechaAplicacion,
    required super.notas,
    super.consultaId,
    super.dienteId,
    super.superficie,
    super.origen,
    super.nombreDiagnostico,
    super.claveOdontograma,
  });

  factory DiagnosticoAplicadoModel.fromJson(Map<String, dynamic> json) {
    final diagnosis = json['diagnosis'];
    final catalogo = diagnosis is Map
        ? Map<String, dynamic>.from(diagnosis)
        : json;
    return DiagnosticoAplicadoModel(
      id: json['id'] as String?,
      diagnosisId: json['diagnosis_id'] ?? json['diagnosisId'],
      severidad: SeveridadDiagnosis.values.firstWhere(
        (e) => e.name == json['severidad'],
        orElse: () => SeveridadDiagnosis.leve,
      ),
      fechaAplicacion: DateTime.parse(
        json['fecha_aplicacion'] ?? json['fechaAplicacion'],
      ),
      notas: json['notas'] ?? '',
      consultaId: json['consulta_id'] ?? json['consultaId'],
      dienteId: json['diente_id'] ?? json['dienteId'],
      superficie: _parseSuperficie(json['superficie']),
      origen: OrigenMarcaOdontograma.values.firstWhere(
        (origen) => origen.name == json['origen'],
        orElse: () => OrigenMarcaOdontograma.preexistente,
      ),
      nombreDiagnostico: catalogo['nombre'] as String?,
      claveOdontograma:
          catalogo['clave_odontograma'] as String? ??
          catalogo['claveOdontograma'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'diagnosis_id': diagnosisId,
      'severidad': severidad.name,
      'fecha_aplicacion': fechaAplicacion.toIso8601String(),
      'notas': notas,
      'consulta_id': consultaId,
      'diente_id': dienteId,
      'superficie': superficie?.name.toLowerCase(),
      'origen': origen.name,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }

  static TipoSuperficie? _parseSuperficie(dynamic raw) {
    if (raw == null) return null;
    final value = raw.toString().toLowerCase();
    for (final superficie in TipoSuperficie.values) {
      if (superficie.name.toLowerCase() == value) return superficie;
    }
    return null;
  }
}
