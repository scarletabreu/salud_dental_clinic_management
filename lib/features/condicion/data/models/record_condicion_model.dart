import 'package:salud_dental_clinic_management/features/condicion/data/models/condicion_model.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/entities/record_condicion.dart';

class RecordCondicionModel extends RecordCondicion {
  const RecordCondicionModel({
    super.id,
    required super.recordId,
    required super.condicionId,
    super.condicion,
    super.medicamento,
    super.dosis,
    super.frecuencia,
    super.medicoTratante,
    super.contactoMedico,
    super.notas,
    super.activo = true,
    super.fechaDeteccion,
  });

  factory RecordCondicionModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? condicionJson;
    if (json['condiciones'] is Map<String, dynamic>) {
      condicionJson = json['condiciones'] as Map<String, dynamic>;
    } else if (json['condicion'] is Map<String, dynamic>) {
      condicionJson = json['condicion'] as Map<String, dynamic>;
    }

    final rawFecha = json['fecha_deteccion'];

    return RecordCondicionModel(
      id: json['id'] as String?,
      recordId: (json['record_id'] ?? '').toString(),
      condicionId: (json['condicion_id'] ?? '').toString(),
      condicion: condicionJson != null
          ? CondicionModel.fromJson(condicionJson)
          : null,
      medicamento: json['medicamento'] as String?,
      dosis: json['dosis'] as String?,
      frecuencia: json['frecuencia'] as String?,
      medicoTratante: json['medico_tratante'] as String?,
      contactoMedico: json['contacto_medico'] as String?,
      notas: json['notas'] as String?,
      activo: json['activo'] as bool? ?? true,
      fechaDeteccion: rawFecha != null
          ? DateTime.tryParse(rawFecha.toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'record_id': recordId,
      'condicion_id': condicionId,
      'medicamento': medicamento,
      'dosis': dosis,
      'frecuencia': frecuencia,
      'medico_tratante': medicoTratante,
      'contacto_medico': contactoMedico,
      'notas': notas,
      'activo': activo,
      if (fechaDeteccion != null)
        'fecha_deteccion': fechaDeteccion!.toIso8601String().split('T').first,
    };
  }

  factory RecordCondicionModel.fromEntity(RecordCondicion entity) {
    return RecordCondicionModel(
      id: entity.id,
      recordId: entity.recordId,
      condicionId: entity.condicionId,
      condicion: entity.condicion,
      medicamento: entity.medicamento,
      dosis: entity.dosis,
      frecuencia: entity.frecuencia,
      medicoTratante: entity.medicoTratante,
      contactoMedico: entity.contactoMedico,
      notas: entity.notas,
      activo: entity.activo,
      fechaDeteccion: entity.fechaDeteccion,
    );
  }
}
