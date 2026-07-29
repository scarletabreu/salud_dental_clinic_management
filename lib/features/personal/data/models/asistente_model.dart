import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/asistente.dart';

class AsistenteModel extends Asistente {
  AsistenteModel({
    super.id,
    required super.nombre,
    required super.apellido,
    required super.contactos,
    required super.birthDate,
    required super.govID,
    required super.estatus,
    required super.username,
    required super.passwordHash,
    required super.shift,
  });

  factory AsistenteModel.fromJson(Map<String, dynamic> json) {
    final usuarioData = json['usuarios'] as Map<String, dynamic>? ?? {};

    final personaData = usuarioData['personas'] as Map<String, dynamic>? ?? {};

    return AsistenteModel(
      id: json['id'] as String?,

      nombre: personaData['nombre'] as String? ?? '',
      apellido: personaData['apellido'] as String? ?? '',
      birthDate: personaData['fecha_nacimiento'] != null
          ? DateTime.parse(personaData['fecha_nacimiento'])
          : DateTime.now(),
      govID: personaData['cedula'] as String? ?? '',
      contactos: _parseContactos(personaData),

      estatus: _calcularEstatus(json['deleted_at'] as String?),
      username: usuarioData['username'] as String? ?? '',
      passwordHash: usuarioData['password_hash'] as String? ?? '',

      shift: json['turno'] as String? ?? '',
    );
  }

  static EstatusPersona _calcularEstatus(String? deletedAtStr) {
    return deletedAtStr == null
        ? EstatusPersona.activo
        : EstatusPersona.inactivo;
  }

  static List<ContactoModel> _parseContactos(Map<String, dynamic> json) {
    final directos = json['contactos'];
    if (directos is List) {
      return directos
          .whereType<Map<String, dynamic>>()
          .map((item) => ContactoModel.fromJson(item))
          .toList();
    }
    if (directos is Map<String, dynamic>) {
      return [ContactoModel.fromJson(directos)];
    }

    final relaciones = json['persona_contactos'];
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
    final Map<String, dynamic> data = {'turno': shift};

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
