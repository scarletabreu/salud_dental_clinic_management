import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/persona.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/cita/data/models/cita_model.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';

class CitaRemoteDataSource {
  final SupabaseClient supabase;

  CitaRemoteDataSource(this.supabase);

  Future<List<CitaModel>> fetchCitas() async {
    try {
      final citasRes = await supabase
          .from('citas')
          .select('*')
          .filter('deleted_at', 'is', null);

      final raw = citasRes as List;
      debugPrint('RAW citas desde Supabase: ${raw.length} filas');

      if (raw.isEmpty) return _citasPrueba;

      final real = await _assembleCitas(raw);
      debugPrint('Citas ensambladas: ${real.length}');

      return real.isEmpty ? _citasPrueba : real;
    } catch (e, stack) {
      debugPrint('fetchCitas error: $e');
      debugPrint('Stack: $stack');
      return _citasPrueba;
    }
  }

  Future<List<CitaModel>> fetchCitasByPaciente(String pacienteId) async {
    try {
      final citasRes = await supabase
          .from('citas')
          .select('*')
          .eq('persona_id', pacienteId)
          .filter('deleted_at', 'is', null);

      return _assembleCitas(citasRes as List);
    } catch (e) {
      throw Exception('Error al obtener citas del paciente: $e');
    }
  }

  Future<List<CitaModel>> fetchCitasByDoctor(String doctorId) async {
    try {
      final citasRes = await supabase
          .from('citas')
          .select('*')
          .eq('doctor_id', doctorId)
          .filter('deleted_at', 'is', null);

      return _assembleCitas(citasRes as List);
    } catch (e) {
      throw Exception('Error al obtener citas del doctor: $e');
    }
  }

  Future<List<CitaModel>> _assembleCitas(List rawCitas) async {
    if (rawCitas.isEmpty) return [];

    final doctorIds = rawCitas
        .map((c) => (c as Map<String, dynamic>)['doctor_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    final personaIds = rawCitas
        .map((c) => (c as Map<String, dynamic>)['persona_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    debugPrint('doctor_ids buscados: $doctorIds');
    debugPrint('persona_ids buscados: $personaIds');

    final Map<String, Map<String, dynamic>> doctorPersonas = {};
    if (doctorIds.isNotEmpty) {
      final res = await supabase
          .from('personas')
          .select('*')
          .inFilter('id', doctorIds);
      for (final row in res as List) {
        final m = row as Map<String, dynamic>;
        doctorPersonas[m['id'] as String] = m;
      }
    }
    debugPrint('doctorPersonas encontrados: ${doctorPersonas.keys}');

    final Map<String, Map<String, dynamic>> pacientes = {};
    if (personaIds.isNotEmpty) {
      final res = await supabase
          .from('pacientes')
          .select(
            '*, personas(id, nombre, apellido, fecha_nacimiento, cedula, estatus)',
          )
          .inFilter('id', personaIds);
      for (final row in res as List) {
        final m = row as Map<String, dynamic>;
        pacientes[m['id'] as String] = m;
      }

      final missing = personaIds
          .where((id) => !pacientes.containsKey(id))
          .toList();
      if (missing.isNotEmpty) {
        debugPrint('persona_ids no encontrados en pacientes: $missing');
        final fallback = await supabase
            .from('personas')
            .select('*')
            .inFilter('id', missing);
        for (final row in fallback as List) {
          final m = row as Map<String, dynamic>;
          pacientes[m['id'] as String] = {'id': m['id'], 'personas': m};
        }
      }
    }
    debugPrint('pacientes encontrados: ${pacientes.keys}');

    final List<CitaModel> result = [];

    for (final c in rawCitas) {
      try {
        final json = Map<String, dynamic>.from(c as Map);

        final dp = doctorPersonas[json['doctor_id'] as String?] ?? {};
        json['doctor'] = {
          'id': json['doctor_id'],
          'nombre': dp['nombre'] ?? '',
          'apellido': dp['apellido'] ?? '',
          'fecha_nacimiento': dp['fecha_nacimiento'] ?? '2000-01-01',
          'cedula': dp['cedula'] ?? '',
          'estatus': dp['estatus'] ?? 'activo',
          'username': dp['username'] ?? '',
          'password_hash': dp['password_hash'] ?? '',
          'especialidad': dp['especialidad'] ?? '',
          'esta_disponible': dp['esta_disponible'] ?? true,
          'assistants': <dynamic>[],
          'contacto': const {
            'email': '',
            'numero_telefono': '',
            'direccion': '',
          },
        };

        final pac = pacientes[json['persona_id'] as String?] ?? {};
        final personaData = pac['personas'] as Map<String, dynamic>? ?? pac;
        json['persona'] = {
          'id': pac['id'] ?? json['persona_id'],
          'nombre': personaData['nombre'] ?? '',
          'apellido': personaData['apellido'] ?? '',
          'fecha_nacimiento': personaData['fecha_nacimiento'] ?? '2000-01-01',
          'cedula': personaData['cedula'] ?? '',
          'estatus': personaData['estatus'] ?? 'activo',
        };

        result.add(CitaModel.fromJson(json));
      } catch (e) {
        debugPrint('Error ensamblando cita ${(c as Map)['id']}: $e');
      }
    }

    return result;
  }

  Future<void> addCita(CitaModel cita) async {
    try {
      final data = cita.toJson();

      if (!_isValidUuid(data['id'])) {
        data.remove('id');
      }

      final now = DateTime.now().toIso8601String();
      data['created_at'] = now;
      data['updated_at'] = now;

      await supabase.from('citas').insert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al agregar cita: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al agregar cita: $e');
    }
  }

  Future<void> updateCita(CitaModel cita) async {
    if (cita.id == null) {
      throw Exception('No se puede actualizar una cita sin ID.');
    }
    try {
      final data = <String, dynamic>{
        'doctor_id': cita.doctor.id,
        'persona_id': cita.persona.id,
        'fecha_hora': cita.date.toUtc().toIso8601String(),
        'duracion_minutos': cita.duracionMinutos,
        'es_emergencia': cita.esEmergencia,
        'estado': cita.estado.name,
        'updated_at': DateTime.now().toIso8601String(),
      };
      debugPrint('updateCita payload: $data para id=${cita.id}');
      await supabase.from('citas').update(data).eq('id', cita.id!);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar cita: ${e.message}');
    }
  }

  Future<void> deleteCita(String id) async {
    try {
      await supabase
          .from('citas')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al borrar cita: $e');
    }
  }

  Future<void> updateCitaEstado(String id, EstadoCita nuevoEstado) async {
    try {
      final updateData = <String, dynamic>{
        'estado': nuevoEstado.dbValue,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (nuevoEstado == EstadoCita.completada) {
        updateData['fecha_fin'] = DateTime.now().toIso8601String();
      }
      await supabase.from('citas').update(updateData).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(
        'Error al actualizar el estado en Supabase: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'Error inesperado al actualizar el estado de la cita: $e',
      );
    }
  }

  bool _isValidUuid(dynamic id) =>
      id != null && id is String && id.length == 36 && id.contains('-');

  static final _empty = [ContactoModel.empty()];

  static Doctor _doc(
    String id,
    String nombre,
    String apellido,
    String especialidad,
  ) => Doctor(
    id: id,
    nombre: nombre,
    apellido: apellido,
    birthDate: DateTime(1980, 1, 1),
    govID: '001-0000000-0',
    contactos: _empty,
    estatus: EstatusPersona.activo,
    username: '',
    passwordHash: '',
    specialty: especialidad,
    assistants: const [],
  );

  static Persona _pac(String id, String nombre, String apellido) => Persona(
    id: id,
    nombre: nombre,
    apellido: apellido,
    birthDate: DateTime(1990, 1, 1),
    govID: '001-0000000-0',
    contactos: _empty,
    estatus: EstatusPersona.activo,
  );

  static final _docFernandez = _doc('d1', 'Carlos', 'Fernández', 'Ortodoncia');
  static final _docRodriguez = _doc('d2', 'Ana', 'Rodríguez', 'Endodoncia');
  static final _docLopez = _doc('d3', 'Luis', 'López', 'Periodoncia');

  static final _pacAlonso = _pac('p1', 'Pedro', 'Alonso');
  static final _pacSantos = _pac('p2', 'María', 'Santos');
  static final _pacMendez = _pac('p3', 'Juan', 'Méndez');
  static final _pacCastillo = _pac('p4', 'Laura', 'Castillo');
  static final _pacGarcia = _pac('p5', 'Roberto', 'García');
  static final _pacHerrera = _pac('p6', 'Sofía', 'Herrera');

  static CitaModel _cita(
    String id,
    Doctor doc,
    Persona pac,
    int month,
    int day,
    int hour,
    int min,
    EstadoCita estado, {
    bool urgente = false,
    int duracion = 30,
  }) => CitaModel(
    id: id,
    doctor: doc,
    persona: pac,
    date: DateTime(2026, month, day, hour, min),
    duracionMinutos: duracion,
    esEmergencia: urgente,
    estado: estado,
  );

  static final List<CitaModel> _citasPrueba = [
    _cita(
      't01',
      _docFernandez,
      _pacAlonso,
      5,
      5,
      9,
      0,
      EstadoCita.completada,
      duracion: 60,
    ),
    _cita(
      't02',
      _docRodriguez,
      _pacSantos,
      5,
      12,
      10,
      30,
      EstadoCita.completada,
      duracion: 90,
    ),
    _cita(
      't03',
      _docLopez,
      _pacMendez,
      5,
      12,
      14,
      0,
      EstadoCita.completada,
      duracion: 45,
    ),
    _cita(
      't04',
      _docFernandez,
      _pacCastillo,
      5,
      13,
      11,
      0,
      EstadoCita.cancelada,
      duracion: 60,
    ),
    _cita(
      't05',
      _docFernandez,
      _pacAlonso,
      5,
      18,
      8,
      0,
      EstadoCita.completada,
      duracion: 60,
    ),
    _cita(
      't06',
      _docRodriguez,
      _pacGarcia,
      5,
      18,
      10,
      0,
      EstadoCita.pendiente,
      urgente: true,
      duracion: 30,
    ),
    _cita(
      't07',
      _docLopez,
      _pacHerrera,
      5,
      18,
      15,
      30,
      EstadoCita.pendiente,
      duracion: 90,
    ),
    _cita(
      't08',
      _docFernandez,
      _pacSantos,
      5,
      19,
      9,
      0,
      EstadoCita.completada,
      duracion: 60,
    ),
    _cita(
      't09',
      _docRodriguez,
      _pacMendez,
      5,
      19,
      14,
      0,
      EstadoCita.completada,
      duracion: 120,
    ),
    _cita(
      't10',
      _docLopez,
      _pacCastillo,
      5,
      20,
      10,
      30,
      EstadoCita.completada,
      duracion: 60,
    ),
    _cita(
      't11',
      _docFernandez,
      _pacAlonso,
      5,
      21,
      9,
      0,
      EstadoCita.completada,
      urgente: true,
      duracion: 45,
    ),
    _cita(
      't12',
      _docRodriguez,
      _pacGarcia,
      5,
      21,
      16,
      0,
      EstadoCita.pendiente,
      duracion: 60,
    ),
    _cita(
      't13',
      _docLopez,
      _pacHerrera,
      5,
      22,
      11,
      0,
      EstadoCita.cancelada,
      duracion: 30,
    ),
    _cita(
      't14',
      _docFernandez,
      _pacSantos,
      5,
      25,
      8,
      30,
      EstadoCita.pendiente,
      duracion: 60,
    ),
    _cita(
      't15',
      _docRodriguez,
      _pacMendez,
      5,
      25,
      11,
      0,
      EstadoCita.pendiente,
      duracion: 90,
    ),
    _cita(
      't16',
      _docLopez,
      _pacCastillo,
      5,
      25,
      14,
      30,
      EstadoCita.pendiente,
      duracion: 60,
    ),
    _cita(
      't17',
      _docFernandez,
      _pacAlonso,
      5,
      25,
      17,
      0,
      EstadoCita.pendiente,
      duracion: 30,
    ),
    _cita(
      't18',
      _docRodriguez,
      _pacGarcia,
      5,
      27,
      9,
      0,
      EstadoCita.pendiente,
      duracion: 60,
    ),
    _cita(
      't19',
      _docLopez,
      _pacHerrera,
      5,
      27,
      13,
      0,
      EstadoCita.completada,
      duracion: 45,
    ),
    _cita(
      't20',
      _docFernandez,
      _pacSantos,
      5,
      28,
      10,
      0,
      EstadoCita.completada,
      duracion: 60,
    ),
  ];
}
