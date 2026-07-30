import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';

class Admin extends Doctor {
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
    required super.assistants,
    required super.specialty,
    super.isAvailable = true,
    required this.departamento,
  });

  @override
  RolUsuario get rol => RolUsuario.admin;

  Admin copyWithAdmin({EstatusPersona? estatus, String? departamento}) {
    return Admin(
      id: id,
      nombre: nombre,
      apellido: apellido,
      birthDate: birthDate,
      govID: govID,
      contactos: contactos,
      estatus: estatus ?? this.estatus,
      username: username,
      departamento: departamento ?? this.departamento,
      specialty: specialty,
      assistants: assistants,
      isAvailable: isAvailable,
    );
  }
}
