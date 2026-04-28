import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/data/models/diagnostico_aplicado_model.dart';
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
      odontogramaId: json['odontograma_id'] as String,
      fdiCode: (json['fdi_code'] as num).toInt(),
      observaciones: json['observaciones'] as String?,

      superficies:
          (json['superficies'] as List?)
              ?.map(
                (s) => Superficie(
                  id: s['id'] as String,
                  dienteId: s['diente_id'] as String,
                  tipoSuperficie: TipoSuperficie.values.firstWhere(
                    (type) => type.name == s['tipo_superficie'],
                    orElse: () => TipoSuperficie.vestibular,
                  ),
                  diagnosisId: s['diagnosis_id'] as String?,
                  tratamientos:
                      (s['tratamientos'] as List?)
                          ?.map((t) => t.toString())
                          .toList() ??
                      [],
                ),
              )
              .toList() ??
          [],

      diagnosis:
          (json['diagnosticos'] as List?)
              ?.map(
                (e) => DiagnosticoAplicadoModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],

      tratamientos:
          (json['tratamientos'] as List?)
              ?.map(
                (e) => TratamientoAplicadoModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'odontograma_id': odontogramaId,
      'fdi_code': fdiCode,
      'observaciones': observaciones,
    };
  }
}
