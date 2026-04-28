import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/diente/data/models/diente_model.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/data/models/diagnosis_model.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/data/models/tratamiento_model.dart';

class OdontogramaModel extends Odontograma {
  OdontogramaModel({
    required super.id,
    required super.consultaId,
    required super.dientes,
    super.tratamientos = const [],
    super.diagnosis = const [],
  });

  factory OdontogramaModel.fromJson(Map<String, dynamic> json) {
    return OdontogramaModel(
      id: json['id'] as String,
      consultaId: json['consulta_id'] ?? json['consultaId'],
      dientes: json['dientes'] != null
          ? (json['dientes'] as List)
                .map((e) => DienteModel.fromJson(e))
                .toList()
          : [],
      tratamientos: json['tratamientos'] != null
          ? (json['tratamientos'] as List)
                .map((e) => TratamientoModel.fromJson(e))
                .toList()
          : [],
      diagnosis: json['diagnosis'] != null
          ? (json['diagnosis'] as List)
                .map((e) => DiagnosisModel.fromJson(e))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'consulta_id': consultaId};
  }
}
