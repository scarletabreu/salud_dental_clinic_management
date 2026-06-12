import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/record/data/models/record_model.dart';

class PacienteModel extends Paciente {
  PacienteModel({
    super.id,
    required super.nombre,
    required super.apellido,
    required super.birthDate,
    required super.govID,
    required super.contactos,
    required super.estatus,
    required super.genero,
    required super.record,
    required super.trabajo,
    required super.referencia,
    required super.citas,
    required super.tipoPaciente,
  });

  factory PacienteModel.fromJson(Map<String, dynamic> json) {
    final persona = json['personas'] as Map<String, dynamic>? ?? {};
    return PacienteModel(
      id: json['id'] as String,
      nombre: persona['nombre'] as String,
      apellido: persona['apellido'] as String,
      birthDate: DateTime.parse(persona['fecha_nacimiento'] as String),
      govID: persona['cedula'] as String,
      contactos: _parseContactos(json),
      estatus: EstatusPersona.values.byName(persona['estatus'] as String),
      genero: Genero.values.byName(json['genero'] as String),
      tipoPaciente: TipoPaciente.values.byName(json['tipo_paciente'] as String),
      trabajo: json['trabajo'] as String? ?? '',
      referencia: json['referencia'] as String? ?? '',
      record: json['record'] != null
          ? RecordModel.fromJson(json['record'] as Map<String, dynamic>)
          : RecordModel.empty(),
      citas: const [],
    );
  }
  
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'genero': genero.name,
      'tipo_paciente': tipoPaciente.name,
      'trabajo': trabajo,
      'referencia': referencia,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }

  static List<ContactoModel> _parseContactos(Map<String, dynamic> json) {
    final raw = json['contactos'];

    // Caso 1: Si viene como una Lista (lo ideal)
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>() // Filtra y asegura que cada item sea un Map
          .map((item) => ContactoModel.fromJson(item))
          .toList();
    }

    // Caso 2: Por si acaso el backend viejo o un fallback envía un solo objeto Map
    if (raw is Map<String, dynamic>) {
      return [ContactoModel.fromJson(raw)];
    }

    // Caso 3: embed anidado de Supabase:
    // personas(..., persona_contacto:persona_contactos(contactos(*)))
    final persona = json['personas'];
    if (persona is Map<String, dynamic>) {
      final relaciones = persona['persona_contacto'];
      if (relaciones is List) {
        return relaciones
            .map((rel) => rel is Map ? rel['contactos'] : null)
            .whereType<Map<String, dynamic>>()
            .map(ContactoModel.fromJson)
            .toList();
      }
    }

    // Si es nulo o no es un formato válido, devolvemos una lista vacía
    return [];
  }

  factory PacienteModel.fromEntity(Paciente paciente) {
    return PacienteModel(
      id: paciente.id,
      nombre: paciente.nombre,
      apellido: paciente.apellido,
      birthDate: paciente.birthDate,
      govID: paciente.govID,
      contactos: paciente.contactos,
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
