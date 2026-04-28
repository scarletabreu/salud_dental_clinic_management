import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';

class RecetaModel extends Receta {
  RecetaModel({
    required super.id,
    required super.title,
    required super.createdAt,
    required super.medicinaId,
    required super.dosis,
    required super.frecuencia,
    required super.indicaciones,
    required super.duracion,
    super.notas,
  });

  factory RecetaModel.fromJson(Map<String, dynamic> json) {
    return RecetaModel(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(
        json['created_at'] ?? json['createdAt'],
      ).toLocal(),
      medicinaId: json['medicina_id'] ?? json['medicinaId'] as String,
      dosis: json['dosis'] as String,
      frecuencia: json['frecuencia'] as String,
      indicaciones: json['indicaciones'] as String,
      duracion: json['duracion'] as String,
      notas: json['notas'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt.toUtc().toIso8601String(),
      'medicina_id': medicinaId,
      'dosis': dosis,
      'frecuencia': frecuencia,
      'indicaciones': indicaciones,
      'duracion': duracion,
      'notas': notas,
    };
  }

  factory RecetaModel.fromEntity(Receta receta) {
    return RecetaModel(
      id: receta.id,
      title: receta.title,
      createdAt: receta.createdAt,
      medicinaId: receta.medicinaId,
      dosis: receta.dosis,
      frecuencia: receta.frecuencia,
      indicaciones: receta.indicaciones,
      duracion: receta.duracion,
      notas: receta.notas,
    );
  }
}
