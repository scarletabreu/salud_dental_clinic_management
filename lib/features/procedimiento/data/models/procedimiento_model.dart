import 'package:salud_dental_clinic_management/features/procedimiento/domain/entities/procedimiento.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/data/models/contraindicacion_model.dart';

class ProcedimientoModel extends Procedimiento {
  ProcedimientoModel({
    super.id,
    required super.nombre,
    required super.contraindicaciones,
  });

  factory ProcedimientoModel.fromJson(Map<String, dynamic> json) {
    return ProcedimientoModel(
      id: json['id'] as String?,
      nombre: json['nombre'] as String,
      contraindicaciones: json['contraindicaciones'] != null
          ? (json['contraindicaciones'] as List)
                .map((e) => ContraindicacionModel.fromJson(e))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'nombre': nombre};

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }

  factory ProcedimientoModel.fromEntity(Procedimiento entidad) {
    return ProcedimientoModel(
      id: entidad.id,
      nombre: entidad.nombre,
      contraindicaciones: entidad.contraindicaciones,
    );
  }
}
