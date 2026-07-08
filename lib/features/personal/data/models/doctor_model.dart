import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/personal/data/models/asistente_model.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';

class DoctorModel extends Doctor {
  DoctorModel({
    super.id,
    required super.nombre,
    required super.apellido,
    required super.contactos,
    required super.birthDate,
    required super.govID,
    required super.estatus,
    required super.username,
    required super.passwordHash,
    required super.specialty,
    required super.assistants,
    super.isAvailable = true,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    final usuarioData = json['usuarios'] as Map<String, dynamic>? ?? {};
    final personaData = usuarioData['personas'] as Map<String, dynamic>? ?? {};

    return DoctorModel(
      id: json['id'] as String?,

      nombre: personaData['nombre'] as String? ?? '',
      apellido: personaData['apellido'] as String? ?? '',
      birthDate: personaData['fecha_nacimiento'] != null
          ? DateTime.parse(personaData['fecha_nacimiento'])
          : DateTime.now(),
      govID: personaData['cedula'] as String? ?? '',
      contactos: _parseContactos(personaData),

      estatus: _parseEstatus(personaData['estatus'] as String?),
      username: usuarioData['username'] as String? ?? '',
      passwordHash: usuarioData['password_hash'] as String? ?? '',

      specialty: json['especialidad'] as String? ?? '',
      isAvailable: json['esta_disponible'] as bool? ?? true,

      assistants:
          (json['assistants'] as List?)
              ?.map((e) => AsistenteModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static EstatusPersona _parseEstatus(String? estatusStr) {
    if (estatusStr == null) return EstatusPersona.activo;

    return EstatusPersona.values.firstWhere(
      (e) => e.name.toLowerCase() == estatusStr.toLowerCase(),
      orElse: () => EstatusPersona.activo,
    );
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
    final Map<String, dynamic> data = {
      'especialidad': specialty,
      'esta_disponible': isAvailable,
      'assistants': assistants
          .map((e) => (e as AsistenteModel).toJson())
          .toList(),
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
