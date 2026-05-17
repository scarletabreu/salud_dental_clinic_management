import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/entities/suplidor.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/enums/tipo_suplidor.dart';

class SuplidorModel extends Suplidor {
  SuplidorModel({
    super.id,
    required super.nombre,
    required super.tipoSuplidor,
    required super.contactos,
    required super.summary,
  });

  factory SuplidorModel.fromJson(Map<String, dynamic> json) {
    return SuplidorModel(
      id: json['id'] as String?,
      nombre: json['nombre'] as String,
      tipoSuplidor: TipoSuplidor.values.firstWhere(
        (e) => e.name == (json['tipo_suplidor'] ?? json['tipoSuplidor']),
        orElse: () => TipoSuplidor.consumible,
      ),
      contactos: [],
      summary: json['summary'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'nombre': nombre,
      'tipo_suplidor': tipoSuplidor.name,
      'summary': summary,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }

  factory SuplidorModel.fromEntity(Suplidor entidad) {
    return SuplidorModel(
      id: entidad.id,
      nombre: entidad.nombre,
      tipoSuplidor: entidad.tipoSuplidor,
      contactos: entidad.contactos,
      summary: entidad.summary,
    );
  }
}
