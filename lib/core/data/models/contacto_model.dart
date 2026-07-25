import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';

class ContactoModel extends Contacto {
  ContactoModel({
    super.id,
    required super.email,
    required super.numeroTelefono,
    required super.direccion,
    super.esEmergencia = false,
  });

  factory ContactoModel.fromJson(Map<String, dynamic> json) {
    return ContactoModel(
      id: json['id'] as String?,
      email: json['email'] as String? ?? '',
      numeroTelefono: (json['numero_telefono'] ?? json['telefono'] ?? '')
          .toString(),
      direccion: json['direccion'] as String? ?? '',
      esEmergencia: json['es_emergencia'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'email': email,
      'numero_telefono': numeroTelefono,
      'direccion': direccion,
      'es_emergencia': esEmergencia,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }

  factory ContactoModel.empty() {
    return ContactoModel(
      id: '',
      email: '',
      numeroTelefono: '',
      direccion: '',
      esEmergencia: false,
    );
  }

  factory ContactoModel.fromEntity(Contacto contacto) {
    return ContactoModel(
      id: contacto.id,
      email: contacto.email,
      numeroTelefono: contacto.numeroTelefono,
      direccion: contacto.direccion,
      esEmergencia: contacto.esEmergencia,
    );
  }
}
