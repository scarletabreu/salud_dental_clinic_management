import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';

class ContactoModel extends Contacto {
  ContactoModel({
    required super.id,
    required super.email,
    required super.numeroTelefono,
    required super.direccion,
  });

  factory ContactoModel.fromJson(Map<String, dynamic> json) {
    return ContactoModel(
      id: json['id'],
      email: json['email'],
      numeroTelefono: json['numeroTelefono'],
      direccion: json['direccion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'numeroTelefono': numeroTelefono,
      'direccion': direccion,
    };
  }
}
