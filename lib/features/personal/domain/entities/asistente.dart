import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';

class Asistente extends Usuario {
  final String shift;

  Asistente({
    required super.id,
    required super.nombre,
    required super.apellido,
    required super.birthDate,
    required super.govID,
    required super.contacto,
    required super.estatus,
    required super.username,
    required super.passwordHash,
    required this.shift,
  });

  Asistente copyWith({EstatusPersona? estatus, String? shift}) {
    return Asistente(
      id: id,
      nombre: nombre,
      apellido: apellido,
      birthDate: birthDate,
      govID: govID,
      contacto: contacto,
      estatus: estatus ?? this.estatus,
      username: username,
      passwordHash: passwordHash,
      shift: shift ?? this.shift,
    );
  }
}
