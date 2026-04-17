import 'package:salud_dental_clinic_management/core/domain/entities/persona.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';

class Paciente extends Persona {
  final Genero genero;
  final Record record;
  final String trabajo;
  final String referencia;
  final List<Cita> citas;
  final TipoPaciente tipoPaciente;

  Paciente({
    required super.id,
    required super.nombre,
    required super.apellido,
    required super.birthDate,
    required super.govID,
    required super.contacto,
    required super.estatus,
    required this.genero,
    required this.record,
    required this.trabajo,
    required this.referencia,
    required this.citas,
    required this.tipoPaciente,
  });

  Paciente copyWith({
    String? govID,
    EstatusPersona? estatus,
    Genero? genero,
    Record? record,
    String? trabajo,
    String? referencia,
    List<Cita>? citas,
    TipoPaciente? tipoPaciente,
  }) {
    return Paciente(
      id: id,
      nombre: nombre,
      apellido: apellido,
      birthDate: birthDate,
      contacto: contacto,
      estatus: estatus ?? this.estatus,
      govID: govID ?? this.govID,
      genero: genero ?? this.genero,
      record: record ?? this.record,
      trabajo: trabajo ?? this.trabajo,
      referencia: referencia ?? this.referencia,
      citas: citas ?? this.citas,
      tipoPaciente: tipoPaciente ?? this.tipoPaciente,
    );
  }
}
