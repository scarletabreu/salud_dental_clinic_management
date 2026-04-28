import 'package:salud_dental_clinic_management/features/superficie/domain/entities/superficie.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

class SuperficieModel extends Superficie {
  SuperficieModel({
    required super.id,
    required super.dienteId,
    required super.tipoSuperficie,
    super.diagnosisId,
    super.tratamientos = const [],
  });

  factory SuperficieModel.fromJson(Map<String, dynamic> json) {
    return SuperficieModel(
      id: json['id'] as String,
      dienteId: json['diente_id'] ?? json['dienteId'] as String,
      tipoSuperficie: TipoSuperficie.values.firstWhere(
        (e) =>
            e.name == json['tipo_superficie'] ||
            e.name == json['tipoSuperficie'],
      ),
      diagnosisId: json['diagnosis_id'] ?? json['diagnosisId'] as String?,
      tratamientos: List<String>.from(json['tratamientos'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'diente_id': dienteId,
      'tipo_superficie': tipoSuperficie.name,
      'diagnosis_id': diagnosisId,
      'tratamientos': tratamientos,
    };
  }

  factory SuperficieModel.fromEntity(Superficie entidad) {
    return SuperficieModel(
      id: entidad.id,
      dienteId: entidad.dienteId,
      tipoSuperficie: entidad.tipoSuperficie,
      diagnosisId: entidad.diagnosisId,
      tratamientos: entidad.tratamientos,
    );
  }
}
