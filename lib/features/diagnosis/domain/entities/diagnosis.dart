import 'package:salud_dental_clinic_management/core/domain/enums/alcance.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/categoria_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';

class Diagnosis {
  final String? id;
  final String nombre;
  final String descripcion;
  final SeveridadDiagnosis severidadDefault;
  final Alcance alcance;
  final CategoriaDiagnosis categoria;

  Diagnosis({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.severidadDefault,
    required this.alcance,
    required this.categoria,
  });

  Diagnosis copyWith({
    String? nombre,
    String? descripcion,
    SeveridadDiagnosis? severidadDefault,
    Alcance? alcance,
    CategoriaDiagnosis? categoria,
  }) {
    return Diagnosis(
      id: id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      severidadDefault: severidadDefault ?? this.severidadDefault,
      alcance: alcance ?? this.alcance,
      categoria: categoria ?? this.categoria,
    );
  }

  factory Diagnosis.fromJson(Map<String, dynamic> json) {
    return Diagnosis(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,

      severidadDefault: SeveridadDiagnosis.values.byName(
        json['severidadDefault'] as String,
      ),

      alcance: Alcance.values.byName(json['alcance'] as String),

      categoria: CategoriaDiagnosis.values.byName(json['categoria'] as String),
    );
  }
}
