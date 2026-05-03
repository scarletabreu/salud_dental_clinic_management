import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/data/models/diagnostico_aplicado_model.dart';
import 'package:salud_dental_clinic_management/features/superficie/data/models/superficie_model.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/data/models/tratamiento_aplicado_model.dart';

class DienteModel extends Diente {
  DienteModel({
    super.id,
    required super.odontogramaId,
    required super.superficies,
    super.tratamientos = const [],
    super.diagnosis = const [],
    required super.fdiCode,
    super.observaciones,
  });

  factory DienteModel.fromJson(Map<String, dynamic> json) {
    return DienteModel(
      id: json['id'] as String?,
      odontogramaId: json['odontograma_id'] as String,
      fdiCode: (json['fdi_code'] as num).toInt(),
      observaciones: json['observaciones'] as String?,
      // Relaciones normalmente cargadas en una consulta con JOIN
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
    final Map<String, dynamic> data = {
      'odontograma_id': odontogramaId,
      'fdi_code': fdiCode,
      'observaciones': observaciones,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
