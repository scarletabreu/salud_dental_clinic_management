import 'package:salud_dental_clinic_management/core/domain/entities/persona.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart'; // Importa el enum

abstract class Usuario extends Persona { // La hacemos abstracta ya que siempre se instanciará un tipo específico
  final String username;
  final String passwordHash;

  RolUsuario get rol;

  Usuario({
    super.id,
    required super.nombre,
    required super.apellido,
    required super.birthDate,
    required super.govID,
    required super.contactos,
    required super.estatus,
    required this.username,
    required this.passwordHash,
  });
}