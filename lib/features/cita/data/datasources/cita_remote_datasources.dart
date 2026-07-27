import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/core/util/app_log.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/features/cita/data/models/cita_model.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';

class CitaRemoteDataSource {
  final SupabaseClient supabase;

  CitaRemoteDataSource(this.supabase);

  /// Citas reales de la base. Un fallo de red, de RLS o de esquema se propaga
  /// para que el guard del repositorio lo convierta en un `Failure` tipado y la
  /// agenda pinte su estado de error: nunca se sustituye por datos inventados.
  Future<List<CitaModel>> fetchCitas() async {
    final citasRes = await supabase
        .from('citas')
        .select('*')
        .filter('deleted_at', 'is', null);

    return _assembleCitas(citasRes as List);
  }

  Future<List<CitaModel>> fetchCitasByPaciente(String pacienteId) async {
    final citasRes = await supabase
        .from('citas')
        .select('*')
        .eq('persona_id', pacienteId)
        .filter('deleted_at', 'is', null);

    return _assembleCitas(citasRes as List);
  }

  Future<List<CitaModel>> fetchCitasByDoctor(String doctorId) async {
    final citasRes = await supabase
        .from('citas')
        .select('*')
        .eq('doctor_id', doctorId)
        .filter('deleted_at', 'is', null);

    return _assembleCitas(citasRes as List);
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
        AppLog.error('ensamblar cita ${(c as Map)['id']}', e);
      }
    }

    return result;
  }

  Future<void> addCita(CitaModel cita) async {
    final data = cita.toJson();

    if (!_isValidUuid(data['id'])) {
      data.remove('id');
    }

    final now = DateTime.now().toIso8601String();
    data['created_at'] = now;
    data['updated_at'] = now;

    await supabase.from('citas').insert(data);
  }

  Future<void> updateCita(CitaModel cita) async {
    if (cita.id == null) {
      throw Exception('No se puede actualizar una cita sin ID.');
    }
    final data = <String, dynamic>{
      'doctor_id': cita.doctor.id,
      'persona_id': cita.persona.id,
      'fecha_hora': cita.date.toUtc().toIso8601String(),
      'duracion_minutos': cita.duracionMinutos,
      'es_emergencia': cita.esEmergencia,
      'estado': cita.estado.dbValue,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await supabase.from('citas').update(data).eq('id', cita.id!);
  }

  Future<void> deleteCita(String id) async {
    await supabase
        .from('citas')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  /// Estado actual de la cita en la BD.
  ///
  /// Falla si el id no corresponde a ninguna fila. Antes devolvía `null` para
  /// tolerar los ids sintéticos de la agenda de prueba; eliminada esa fuente
  /// (SD-161), un id desconocido o mal formado es un defecto real y debe verse
  /// como error en vez de saltarse la validación de transiciones.
  Future<EstadoCita> fetchEstadoCita(String id) async {
    final res = await supabase
        .from('citas')
        .select('estado')
        .eq('id', id)
        .maybeSingle();
    if (res == null) {
      throw ServerFailure('La cita $id ya no existe o fue eliminada.');
    }
    return EstadoCita.fromDb(res['estado'] as String?);
  }

  Future<void> updateCitaEstado(String id, EstadoCita nuevoEstado) async {
    await supabase
        .from('citas')
        .update({
          'estado': nuevoEstado.dbValue,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  bool _isValidUuid(dynamic id) =>
      id != null && id is String && id.length == 36 && id.contains('-');
}
