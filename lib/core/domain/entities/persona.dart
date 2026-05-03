import 'contacto.dart';
import '../enums/estatus_persona.dart';

class Persona {
  final String? id;
  final String nombre;
  final String apellido;
  final DateTime birthDate;
  final String govID;
  final Contacto contacto;
  final EstatusPersona estatus;

  Persona({
    this.id,
    required this.nombre,
    required this.apellido,
    required this.birthDate,
    required this.govID,
    required this.contacto,
    required this.estatus,
  });

  String get fullName => '$nombre $apellido';

  int get age {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}
