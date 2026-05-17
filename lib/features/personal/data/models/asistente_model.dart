import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/asistente.dart';

class AsistenteModel extends Asistente {
  AsistenteModel({
    super.id,
    required super.nombre,
    required super.apellido,
    required super.contacto,
    required super.birthDate,
    required super.govID,
    required super.estatus,
    required super.username,
    required super.passwordHash,
    required super.shift,
  });

  factory AsistenteModel.fromJson(Map<String, dynamic> json) {
    return AsistenteModel(
      id: json['id'] as String?,
      nombre: json['nombre'],
      apellido: json['apellido'],
      contacto: ContactoModel.fromJson(json['contacto']),
      birthDate: DateTime.parse(json['fecha_nacimiento']),
      govID: json['cedula'],
      estatus: json['estatus'],
      username: json['username'],
      passwordHash: json['password_hash'],
      shift: json['turno'],
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
      'turno': shift,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
