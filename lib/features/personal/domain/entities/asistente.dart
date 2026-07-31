import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';

class Asistente extends Usuario {
  final String shift;

  Asistente({
    super.id,
    required super.nombre,
    required super.apellido,
    required super.birthDate,
    required super.govID,
    required super.contactos,
    required super.estatus,
    required super.username,
    required this.shift,
  });

  @override
  RolUsuario get rol => RolUsuario.asistente;

  Asistente copyWith({EstatusPersona? estatus, String? shift}) {
    return Asistente(
      id: id,
      nombre: nombre,
      apellido: apellido,
      birthDate: birthDate,
      govID: govID,
      contactos: contactos,
      estatus: estatus ?? this.estatus,
      username: username,
      shift: shift ?? this.shift,
    );
  }
}
