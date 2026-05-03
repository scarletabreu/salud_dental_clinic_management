import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/admin.dart';

class AdminModel extends Admin {
  AdminModel({
    super.id,
    required super.nombre,
    required super.apellido,
    required super.contacto,
    required super.birthDate,
    required super.govID,
    required super.estatus,
    required super.username,
    required super.passwordHash,
    required super.departamento,
  });

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: json['id'] as String?,
      nombre: json['nombre'],
      apellido: json['apellido'],
      contacto: ContactoModel.fromJson(json['contacto']),
      birthDate: DateTime.parse(json['fecha_nacimiento']),
      govID: json['cedula'],
      estatus: json['estatus'],
      username: json['username'],
      passwordHash: json['password_hash'],
      departamento: json['departamento'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'nombre': nombre,
      'apellido': apellido,
      'contacto': (contacto as ContactoModel).toJson(),
      'fecha_nacimiento': birthDate.toIso8601String(),
      'cedula': govID,
      'estatus': estatus,
      'username': username,
      'password_hash': passwordHash,
      'departamento': departamento,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
