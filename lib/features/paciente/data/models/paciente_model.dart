import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';

class PacienteModel extends Paciente {
  PacienteModel({
    required super.id,
    required super.nombre,
    required super.apellido,
    required super.birthDate,
    required super.govID,
    required super.contacto,
    required super.estatus,
    required super.genero,
    required super.record,
    required super.trabajo,
    required super.referencia,
    required super.citas,
    required super.tipoPaciente,
  });

  factory PacienteModel.fromJson(Map<String, dynamic> json) {
    return PacienteModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      birthDate: DateTime.parse(json['birth_date'] as String),
      govID: json['gov_id'] as String,
      contacto: json['contacto'] as Contacto,
      estatus: EstatusPersona.values.byName(json['estatus'] as String),
      genero: Genero.values.byName(json['genero'] as String),
      tipoPaciente: TipoPaciente.values.byName(json['tipo_paciente'] as String),
      trabajo: json['trabajo'] as String? ?? '',
      referencia: json['referencia'] as String? ?? '',

      record: json['record'] != null
          ? Record.fromJson(json['record'] as Map<String, dynamic>)
          : Record.empty(),

      citas: const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'birth_date': _formatDate(birthDate),
      'gov_id': govID,
      'contacto': contacto,
      'estatus': estatus.name,
      'genero': genero.name,
      'tipo_paciente': tipoPaciente.name,
      'trabajo': trabajo,
      'referencia': referencia,
    };
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }


  factory PacienteModel.fromEntity(Paciente paciente) {
    return PacienteModel(
      id: paciente.id,
      nombre: paciente.nombre,
      apellido: paciente.apellido,
      birthDate: paciente.birthDate,
      govID: paciente.govID,
      contacto: paciente.contacto,
      estatus: paciente.estatus,
      genero: paciente.genero,
      record: paciente.record,
      trabajo: paciente.trabajo,
      referencia: paciente.referencia,
      citas: paciente.citas,
      tipoPaciente: paciente.tipoPaciente,
    );
  }
}