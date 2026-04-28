import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/admin.dart';

class AdminModel extends Admin {
  AdminModel({
    required super.id,
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
      id: json['id'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      contacto: ContactoModel.fromJson(json['contacto']),
      birthDate: DateTime.parse(json['birthDate']),
      govID: json['govID'],
      estatus: json['estatus'],
      username: json['username'],
      passwordHash: json['passwordHash'],
      departamento: json['departamento'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'contacto': (contacto as ContactoModel).toJson(),
      'birthDate': birthDate.toIso8601String(),
      'govID': govID,
      'estatus': estatus,
      'username': username,
      'passwordHash': passwordHash,
      'departamento': departamento,
    };
  }
}
