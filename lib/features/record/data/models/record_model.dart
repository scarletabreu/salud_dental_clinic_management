import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';
import 'package:salud_dental_clinic_management/features/record/domain/enums/tipo_sangre.dart';

class RecordModel extends Record {
  RecordModel({
    super.id,
    required super.pacienteId,
    required super.tipoSangre,
    super.consultas = const [],
    required super.condiciones,
    super.cantHijos = 0,
    required super.cirugiasPrevias,
    required super.historialFamiliar,
  });

  factory RecordModel.fromJson(Map<String, dynamic> json) {
    return RecordModel(
      id: json['id'] as String?,
      pacienteId: json['paciente_id'] ?? json['pacienteId'],
      tipoSangre: TipoSangre.values.firstWhere(
        (e) => e.name == (json['tipo_sangre'] ?? json['tipoSangre']),
        orElse: () => TipoSangre.desconocido,
      ),
      condiciones: json['condiciones'] as String? ?? '',
      cantHijos:
          (json['cant_hijos'] ?? json['cantHijos'] as num?)?.toInt() ?? 0,
      cirugiasPrevias: List<String>.from(
        json['cirugias_previas'] ?? json['cirugiasPrevias'] ?? [],
      ),
      historialFamiliar:
          json['historial_familiar'] ?? json['historialFamiliar'] ?? '',
      consultas: [],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'paciente_id': pacienteId,
      'tipo_sangre': tipoSangre.name,
      'condiciones': condiciones,
      'cant_hijos': cantHijos,
      'cirugias_previas': cirugiasPrevias,
      'historial_familiar': historialFamiliar,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }

  factory RecordModel.fromEntity(Record record) {
    return RecordModel(
      id: record.id,
      pacienteId: record.pacienteId,
      tipoSangre: record.tipoSangre,
      consultas: record.consultas,
      condiciones: record.condiciones,
      cantHijos: record.cantHijos,
      cirugiasPrevias: record.cirugiasPrevias,
      historialFamiliar: record.historialFamiliar,
    );
  }

  factory RecordModel.empty() {
    return RecordModel(
      id: '',
      pacienteId: '',
      tipoSangre: TipoSangre.desconocido,
      consultas: const [],
      condiciones: '',
      cantHijos: 0,
      cirugiasPrevias: const [],
      historialFamiliar: '',
    );
  }
}
