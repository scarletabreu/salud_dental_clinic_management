import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
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
    super.peso,
    super.altura,
  });

  PacienteModel copyWithModel({
    String? id,
    String? nombre,
    String? apellido,
    DateTime? birthDate,
    String? govID,
    List<ContactoModel>? contactos,
    EstatusPersona? estatus,
    Genero? genero,
    RecordModel? record,
    String? trabajo,
    String? referencia,
    List<Cita>? citas,
    TipoPaciente? tipoPaciente,
    double? peso,
    double? altura,
  }) {
    return PacienteModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      birthDate: birthDate ?? this.birthDate,
      govID: govID ?? this.govID,
      contactos: contactos ?? this.contactos,
      estatus: estatus ?? this.estatus,
      genero: genero ?? this.genero,
      record: record ?? (this.record as RecordModel),
      trabajo: trabajo ?? this.trabajo,
      referencia: referencia ?? this.referencia,
      citas: citas ?? this.citas,
      tipoPaciente: tipoPaciente ?? this.tipoPaciente,
      peso: peso ?? this.peso,
      altura: altura ?? this.altura,
    );
  }

  factory PacienteModel.fromJson(Map<String, dynamic> json) {
    final persona = json['personas'] as Map<String, dynamic>? ?? {};

    double? parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    return PacienteModel(
      id: json['id'] as String,
      nombre: persona['nombre'] as String? ?? '',
      apellido: persona['apellido'] as String? ?? '',
      birthDate: DateTime.parse(persona['fecha_nacimiento'] as String),
      govID: persona['cedula'] as String? ?? '',
      contactos: _parseContactos(json),
      estatus: EstatusPersona.values.byName(
        persona['estatus'] as String? ?? 'activo',
      ),
      genero: Genero.values.byName(json['genero'] as String? ?? 'otro'),
      tipoPaciente: TipoPaciente.values.byName(
        json['tipo_paciente'] as String? ?? 'integrado',
      ),
      trabajo: json['trabajo'] as String? ?? '',
      referencia: json['referencia'] as String? ?? '',
      peso: parseDouble(json['peso']),
      altura: parseDouble(json['altura']),
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
      'peso': peso,
      'altura': altura,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }

  static List<ContactoModel> _parseContactos(Map<String, dynamic> json) {
    final raw = json['contactos'];

    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map((item) => ContactoModel.fromJson(item))
          .toList();
    }

    if (raw is Map<String, dynamic>) {
      return [ContactoModel.fromJson(raw)];
    }

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
      peso: paciente.peso,
      altura: paciente.altura,
    );
  }
}
