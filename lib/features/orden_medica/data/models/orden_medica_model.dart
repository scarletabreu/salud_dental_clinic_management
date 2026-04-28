import 'package:salud_dental_clinic_management/features/orden_medica/domain/entities/orden_medica.dart';

class OrdenMedicaModel extends OrdenMedica {
  OrdenMedicaModel({
    required super.id,
    required super.fecha,
    required super.procedimientoId,
    super.notas,
  });

  factory OrdenMedicaModel.fromJson(Map<String, dynamic> json) {
    return OrdenMedicaModel(
      id: json['id'] as String,
      fecha: DateTime.parse(json['fecha'] as String).toLocal(),
      procedimientoId:
          json['procedimiento_id'] ?? json['procedimientoId'] as String,
      notas: json['notas'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha.toUtc().toIso8601String(),
      'procedimiento_id': procedimientoId,
      'notas': notas,
    };
  }

  factory OrdenMedicaModel.fromEntity(OrdenMedica entidad) {
    return OrdenMedicaModel(
      id: entidad.id,
      fecha: entidad.fecha,
      procedimientoId: entidad.procedimientoId,
      notas: entidad.notas,
    );
  }
}
