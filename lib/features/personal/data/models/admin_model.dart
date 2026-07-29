import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/admin.dart';

class AdminModel extends Admin {
  AdminModel({
    super.id,
    required super.nombre,
    required super.apellido,
    required super.contactos,
    required super.birthDate,
    required super.govID,
    required super.estatus,
    required super.username,
    required super.passwordHash,
    required super.departamento,
    required super.assistants,
    required super.specialty,
    super.isAvailable = true,
  });

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    final doctorData = json['doctores'] as Map<String, dynamic>? ?? {};
    final usuarioData = doctorData['usuarios'] as Map<String, dynamic>? ?? {};
    final personaData = usuarioData['personas'] as Map<String, dynamic>? ?? {};

    return AdminModel(
      id: json['id'] as String?,

      
      specialty: doctorData['especialidad'] as String? ?? '',
      isAvailable: doctorData['esta_disponible'] as bool? ?? true,

      assistants: [],

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

      departamento: json['departamento'] as String? ?? '',
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
    final Map<String, dynamic> data = {'departamento': departamento};

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
