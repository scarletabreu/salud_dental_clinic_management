import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';
import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';

class UsuarioModel extends Usuario {
  UsuarioModel({
    super.id,
    required super.username,
    required super.passwordHash,
    required super.nombre,
    required super.apellido,
    required super.birthDate,
    required super.govID,
    required super.contactos,
    required super.estatus,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'],
      username: json['username'],
      passwordHash: json['passwordHash'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      birthDate: DateTime.parse(json['birthDate']),
      govID: json['govID'],
      contactos: _parseContactos(json),
      estatus: json['estatus'],
    );
  }

    static List<ContactoModel> _parseContactos(Map<String, dynamic> json) {
    final raw = json['contactos'];

    // Caso 1: Si viene como una Lista (lo ideal)
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>() // Filtra y asegura que cada item sea un Map
          .map((item) => ContactoModel.fromJson(item))
          .toList();
    }

    // Caso 2: Por si acaso el backend viejo o un fallback envía un solo objeto Map
    if (raw is Map<String, dynamic>) {
      return [ContactoModel.fromJson(raw)];
    }

    // Caso 3: Si es nulo o no es un formato válido, devolvemos una lista vacía
    return [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'username': username,
      'passwordHash': passwordHash,
    };

  Map<String, dynamic> parentToJson() {
    final Map<String, dynamic> data = {
      'nombre': nombre,
      'apellido': apellido,
      'fecha_nacimiento': birthDate.toIso8601String(),
      'cedula': govID,
      'estatus': estatus.name,
      'contactos': (contactos as ContactoModel).toJson(),
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
