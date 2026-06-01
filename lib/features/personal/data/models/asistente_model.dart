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
    
    // 2. Entramos al segundo nivel (personas) desde usuarios
    final personaData = usuarioData['personas'] as Map<String, dynamic>? ?? {};

    return AsistenteModel(
      id: json['id'] as String?,
      
      // Datos que vienen del fondo: de la tabla 'personas'
      nombre: personaData['nombre'] as String? ?? '',
      apellido: personaData['apellido'] as String? ?? '',
      birthDate: personaData['fecha_nacimiento'] != null
          ? DateTime.parse(personaData['fecha_nacimiento'])
          : DateTime.now(),
      govID: personaData['cedula'] as String? ?? '',
      contactos: _parseContactos(personaData),
      
      // Datos que vienen del medio: de la tabla 'usuarios'
      estatus: _parseEstatus(personaData['estatus'] as String?),
      username: usuarioData['username'] as String? ?? '',
      passwordHash: usuarioData['password_hash'] as String? ?? '',
      
      // Datos de la raíz: de la tabla 'doctores'
      shift: json['turno'] as String? ?? '',
    );
  }

    static EstatusPersona _parseEstatus(String? estatusStr) {
    if (estatusStr == null) return EstatusPersona.activo; // Fallback por defecto
    
    return EstatusPersona.values.firstWhere(
      (e) => e.name.toLowerCase() == estatusStr.toLowerCase(),
      orElse: () => EstatusPersona.activo, // Por si en DB guardas algo raro
    );
  }

  static List<ContactoModel> _parseContactos(Map<String, dynamic> json) {
    final raw = json['contactos'];

    // Caso 1: Si viene como una Lista (lo ideal)
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>() // Filtra y asegura que cada item sea un Map
          .map((item) => ContactoModel.fromJson(item))
          .toList();
    }

    // Caso 2: Por si acaso el backend viejo o un fallback envía un solo objeto Map
    if (raw is Map<String, dynamic>) {
      return [ContactoModel.fromJson(raw)];
    }

    // Caso 3: Si es nulo o no es un formato válido, devolvemos una lista vacía
    return [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'turno': shift,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
