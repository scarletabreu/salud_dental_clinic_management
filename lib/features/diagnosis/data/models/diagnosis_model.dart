import 'package:salud_dental_clinic_management/core/domain/enums/alcance.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/categoria_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';

class DiagnosisModel extends Diagnosis {
  DiagnosisModel({
    super.id,
    required super.nombre,
    required super.descripcion,
    required super.severidadDefault,
    required super.alcance,
    required super.categoria,
  });

  factory DiagnosisModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisModel(
      id: json['id'] as String?,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
      severidadDefault: SeveridadDiagnosis.values.byName(
        json['severidad_default'] ?? json['severidadDefault'],
      ),
      alcance: Alcance.values.byName(json['alcance'] as String),
      categoria: CategoriaDiagnosis.values.byName(json['categoria'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'nombre': nombre,
      'descripcion': descripcion,
      'severidad_default': severidadDefault.name,
      'alcance': alcance.name,
      'categoria': categoria.name,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
