import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
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
    return DoctorModel(
      id: json['id'] as String?,
      nombre: json['nombre'],
      apellido: json['apellido'],
      contactos: _parseContactos(json),
      birthDate: DateTime.parse(json['fecha_nacimiento']),
      govID: json['cedula'],
      estatus: json['estatus'],
      username: json['username'],
      passwordHash: json['password_hash'],
      specialty: json['especialidad'],
      assistants:
          (json['assistants'] as List?)
              ?.map((e) => AsistenteModel.fromJson(e))
              .toList() ??
          [],
      isAvailable: json['esta_disponible'] ?? true,
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
