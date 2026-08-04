import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/asistente.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';

class Doctor extends Usuario {
  final String specialty;
  final List<Asistente> assistants;
  final bool isAvailable;

  Doctor({
    super.id,
    required super.nombre,
    required super.apellido,
    required super.birthDate,
    required super.govID,
    required super.contactos,
    required super.estatus,
    required super.username,
    required this.specialty,
    required this.assistants,
    this.isAvailable = true,
  });

  @override
  RolUsuario get rol => RolUsuario.doctor;

  Doctor copyWith({
    String? specialty,
    List<Asistente>? assistants,
    bool? isAvailable,
    EstatusPersona? estatus,
  }) {
    return Doctor(
      id: id,
      nombre: nombre,
      apellido: apellido,
      birthDate: birthDate,
      govID: govID,
      contactos: contactos,
      estatus: estatus ?? this.estatus,
      username: username,
      specialty: specialty ?? this.specialty,
      assistants: assistants ?? this.assistants,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
