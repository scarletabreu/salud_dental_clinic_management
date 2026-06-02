import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';

class Admin extends Usuario {
  final String departamento;

  Admin({
    super.id,
    required super.nombre,
    required super.apellido,
    required super.birthDate,
    required super.govID,
    required super.contactos,
    required super.estatus,
    required super.username,
    required super.passwordHash,
    required this.departamento,
  });

  @override
  RolUsuario get rol => RolUsuario.admin;

  Admin copyWith({EstatusPersona? estatus, String? departamento}) {
    return Admin(
      id: id,
      nombre: nombre,
      apellido: apellido,
      birthDate: birthDate,
      govID: govID,
      contactos: contactos,
      estatus: estatus ?? this.estatus,
      username: username,
      passwordHash: passwordHash,
      departamento: departamento ?? this.departamento,
    );
  }
}
