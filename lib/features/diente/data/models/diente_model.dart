import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/data/models/diagnostico_aplicado_model.dart';
import 'package:salud_dental_clinic_management/features/superficie/data/models/superficie_model.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/data/models/tratamiento_aplicado_model.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/entities/superficie.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

class DienteModel extends Diente {
  DienteModel({
    required super.id,
    required super.odontogramaId,
    required super.superficies,
    super.tratamientos = const [],
    super.diagnosis = const [],
    required super.fdiCode,
    super.observaciones,
  });

  factory DienteModel.fromJson(Map<String, dynamic> json) {
    return DienteModel(
      id: json['id'] as String,
      odontogramaId: json['odontograma_id'] ?? json['odontogramaId'],
      fdiCode: (json['fdi_code'] ?? json['fdiCode'] as num).toInt(),
      observaciones: json['observaciones'] as String?,

      superficies: json['superficies'] != null
          ? (json['superficies'] as List)
                .map((e) => SuperficieModel.fromJson(e))
                .toList()
          : [],

      diagnosis: json['diagnosis'] != null
          ? (json['diagnosis'] as List)
                .map((e) => DiagnosticoAplicadoModel.fromJson(e))
                .toList()
          : [],

      tratamientos: json['tratamientos'] != null
          ? (json['tratamientos'] as List)
                .map((e) => TratamientoAplicadoModel.fromJson(e))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'odontogramaId': odontogramaId,
      'fdiCode': fdiCode,
      'observaciones': observaciones,
      'superficies': superficies
          .map((e) => (e as SuperficieModel).toJson())
          .toList(),
      'diagnosis': diagnosis
          .map((e) => (e as DiagnosticoAplicadoModel).toJson())
          .toList(),
      'tratamientos': tratamientos
          .map((e) => (e as TratamientoAplicadoModel).toJson())
          .toList(),
    };
  }
}
