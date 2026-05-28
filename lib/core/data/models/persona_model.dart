import 'contacto_model.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/persona.dart';

class PersonaModel extends Persona {
  PersonaModel({
    super.id,
    required super.nombre,
    required super.apellido,
    required super.birthDate,
    required super.govID,
    required super.contactos,
    required super.estatus,
  });

  factory PersonaModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> relaciones = json['persona_contacto'] ?? [];

    final contactoData = relaciones.isNotEmpty
        ? relaciones.first['contactos']
        : null;

    return PersonaModel(
      id: json['id'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      birthDate: DateTime.parse(json['fecha_nacimiento']),
      govID: json['cedula'],
      contactos: contactoData != null
          ? (contactoData as List).map((i) => ContactoModel.fromJson(i)).toList()
          : [],
      estatus: EstatusPersona.values.firstWhere(
        (e) => e.name == json['estatus'],
        orElse: () => EstatusPersona.activo,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'nombre': nombre,
      'apellido': apellido,
      'fecha_nacimiento': birthDate.toIso8601String(),
      'cedula': govID,
      'estatus': estatus.name,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }
    return data;
  }
}
