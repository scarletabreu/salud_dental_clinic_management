import 'package:salud_dental_clinic_management/core/domain/enums/alcance.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/data/models/contraindicacion_model.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';

class TratamientoModel extends Tratamiento {
  TratamientoModel({
    super.id,
    required super.nombre,
    required super.descripcion,
    required super.costo,
    required super.contraindicaciones,
    required super.alcance,
  });

  factory TratamientoModel.fromJson(Map<String, dynamic> json) {
    return TratamientoModel(
      id: json['id'] as String?,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] ?? '',
      costo: (json['costo'] as num).toDouble(),
      contraindicaciones: json['contraindicaciones'] != null
          ? (json['contraindicaciones'] as List)
                .map((e) => ContraindicacionModel.fromJson(e))
                .toList()
          : [],
      alcance: Alcance.values.firstWhere(
        (e) => e.name == json['alcance'],
        orElse: () => Alcance.diente,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'nombre': nombre,
      'descripcion': descripcion,
      'costo': costo,
      'alcance': alcance.name,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
