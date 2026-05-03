import 'package:salud_dental_clinic_management/core/domain/entities/persona.dart';

class Usuario extends Persona {
  final String username;
  final String passwordHash;

  Usuario({
    super.id,
    required super.nombre,
    required super.apellido,
    required super.birthDate,
    required super.govID,
    required super.contacto,
    required super.estatus,
    required this.username,
    required this.passwordHash,
  });
}
