import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';

class UsuarioModel extends Usuario {
  UsuarioModel({
    super.id,
    required super.username,
    required super.passwordHash,
    required super.nombre,
    required super.apellido,
    required super.birthDate,
    required super.govID,
    required super.contacto,
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
      contacto: json['contacto'],
      estatus: json['estatus'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'username': username,
      'passwordHash': passwordHash,
      'nombre': nombre,
      'apellido': apellido,
      'birthDate': birthDate.toIso8601String(),
      'govID': govID,
      'contacto': contacto,
      'estatus': estatus,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
