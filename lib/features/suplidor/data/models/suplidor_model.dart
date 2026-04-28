import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/entities/suplidor.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/enums/tipo_suplidor.dart';

class SuplidorModel extends Suplidor {
  SuplidorModel({
    required super.id,
    required super.nombre,
    required super.tipoSuplidor,
    required super.contactos,
    required super.summary,
  });

  factory SuplidorModel.fromJson(Map<String, dynamic> json) {
    return SuplidorModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      tipoSuplidor: TipoSuplidor.values.firstWhere(
        (e) =>
            e.name == json['tipo_suplidor'] || e.name == json['tipoSuplidor'],
        orElse: () => TipoSuplidor.consumible,
      ),
      contactos: json['contactos'] != null
          ? (json['contactos'] as List)
                .map((e) => ContactoModel.fromJson(e))
                .toList()
          : [],
      summary: json['summary'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo_suplidor': tipoSuplidor.name,
      'contactos': contactos.map((e) => (e as ContactoModel).toJson()).toList(),
      'summary': summary,
    };
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
