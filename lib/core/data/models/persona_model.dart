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
    return PersonaModel(
      id: json['id'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      birthDate: DateTime.parse(json['fecha_nacimiento']),
      govID: json['cedula'],
      contactos: _parseContactos(json),
      estatus: EstatusPersona.values.firstWhere(
        (e) => e.name == json['estatus'],
        orElse: () => EstatusPersona.activo,
      ),
    );
  }

  /// Acepta tanto una lista plana en `contactos` como el embed vía la tabla
  /// puente (`persona_contacto:persona_contactos(*, contactos(*))`), donde
  /// cada relación trae UN contacto (objeto, no lista).
  static List<ContactoModel> _parseContactos(Map<String, dynamic> json) {
    final directos = json['contactos'];
    if (directos is List) {
      return directos
          .whereType<Map<String, dynamic>>()
          .map(ContactoModel.fromJson)
          .toList();
    }

    final relaciones = json['persona_contacto'];
    if (relaciones is List) {
      return relaciones
          .map((rel) => rel is Map ? rel['contactos'] : null)
          .whereType<Map<String, dynamic>>()
          .map(ContactoModel.fromJson)
          .toList();
    }
    return [];
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
