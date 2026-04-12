import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/asistente.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/persona_estatus.dart';

class Doctor extends Usuario {
  final String specialty;
  final List<Asistente> assistants;
  final bool isAvailable;

  Doctor({
    required super.id,
    required super.nombre,
    required super.apellido,
    required super.birthDate,
    required super.govID,
    required super.contacto,
    required super.estatus,
    required super.username,
    required super.passwordHash,
    required this.specialty,
    required this.assistants,
    this.isAvailable = true,
  });

  Doctor copyWith({
    String? specialty,
    List<Asistente>? assistants,
    bool? isAvailable,
    PersonaEstatus? estatus,
  }) {
    return Doctor(
      id: id,
      nombre: nombre,
      apellido: apellido,
      birthDate: birthDate,
      govID: govID,
      contacto: contacto,
      estatus: estatus ?? this.estatus,
      username: username,
      passwordHash: passwordHash,
      specialty: specialty ?? this.specialty,
      assistants: assistants ?? this.assistants,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
