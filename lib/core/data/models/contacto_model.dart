import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';

class ContactoModel extends Contacto {
  ContactoModel({
    super.id,
    required super.email,
    required super.numeroTelefono,
    required super.direccion,
  });

  factory ContactoModel.fromJson(Map<String, dynamic> json) {
    return ContactoModel(
      id: json['id'] as String?,
      email: json['email'] as String? ?? '',
      numeroTelefono: json['numero_telefono'] as String? ?? '',
      direccion: json['direccion'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'email': email,
      'numero_telefono': numeroTelefono,
      'direccion': direccion,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }

  factory ContactoModel.empty() {
    return ContactoModel(id: '', email: '', numeroTelefono: '', direccion: '');
  }
}
