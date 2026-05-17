import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

class TratamientoAplicadoModel extends TratamientoAplicado {
  TratamientoAplicadoModel({
    super.id,
    required super.tratamientoId,
    super.tratamientoPadreId,
    required super.esContinuo,
    required super.estaTerminado,
  });

  factory TratamientoAplicadoModel.fromJson(Map<String, dynamic> json) {
    return TratamientoAplicadoModel(
      id: json['id'] as String?,
      tratamientoId: json['tratamiento_id'] ?? json['tratamientoId'],
      tratamientoPadreId:
          json['tratamiento_padre_id'] ?? json['tratamientoPadreId'],
      esContinuo: json['es_continuo'] ?? json['esContinuo'] ?? false,
      estaTerminado: json['esta_terminado'] ?? json['estaTerminado'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'tratamiento_id': tratamientoId,
      'tratamiento_padre_id': tratamientoPadreId,
      'es_continuo': esContinuo,
      'esta_terminado': estaTerminado,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
