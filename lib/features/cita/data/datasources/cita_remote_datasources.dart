import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/core/util/app_log.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/features/cita/data/models/cita_model.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/referencia_cita.dart';
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

    final personaIds = rawCitas
        .where((c) => (c as Map<String, dynamic>)['persona_id'] != null)
        .map((c) => (c as Map<String, dynamic>)['persona_id'] as String)
        .toSet()
        .toList();

    // 1. OBTENER DOCTORES USANDO EL RPC SEGURO (Bypass / Respeta RLS correctamente)
    final Map<String, Map<String, dynamic>> doctorMaps = {};
    try {
      final responseDoctores = await supabase.rpc('get_active_doctors');
      for (final docJson in (responseDoctores as List)) {
        final m = docJson as Map<String, dynamic>;
        final id = m['doctor_id'] as String?;
        if (id != null) {
          doctorMaps[id] = m;
        }
      }
    } catch (e) {
      AppLog.error('Error cargando doctores en _assembleCitas', e);
    }

    // 2. Obtener pacientes (esto suele tener menos restricciones o permisos distintos)
    final Map<String, Map<String, dynamic>> pacientes = {};
    if (personaIds.isNotEmpty) {
      try {
        final res = await supabase
            .from('pacientes')
            .select(
              '*, personas(id, nombre, apellido, fecha_nacimiento, cedula, estatus)',
            )
            .inFilter('id', personaIds);
        for (final row in res as List) {
          final m = row as Map<String, dynamic>;
          if (m['id'] != null) {
            pacientes[m['id'] as String] = m;
          }
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
            final id = m['id'] as String?;
            if (id != null) {
              pacientes[id] = {'id': id, 'personas': m};
            }
          }
        }
      } catch (e) {
        AppLog.error('Error cargando pacientes en _assembleCitas', e);
      }
    }

    final List<CitaModel> result = [];

    // 3. Ensamblar las citas combinando la información obtenida
    for (final c in rawCitas) {
      try {
        final json = Map<String, dynamic>.from(c as Map);
        final doctorId = json['doctor_id'] as String?;

        // Obtenemos los datos del doctor desde el mapa construido con el RPC
        final dp = (doctorId != null ? doctorMaps[doctorId] : null) ?? {};
        
        json['doctor'] = {
          'doctor_id': doctorId,
          'nombre': dp['nombre'] ?? '',
          'apellido': dp['apellido'] ?? '',
          'fecha_nacimiento': dp['fecha_nacimiento'] ?? '2000-01-01',
          'cedula': dp['cedula'] ?? '',
          'estatus': dp['estatus'] ?? 'activo',
          'username': dp['username'] ?? '',
          'password_hash': dp['password_hash'] ?? '',
          'especialidad': dp['especialidad'] ?? '',
          'esta_disponible': dp['esta_disponible'] ?? true,
          'assistants': dp['assistants'] ?? <dynamic>[],
          'contacto': dp['contacto'] ?? const {
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
      'motivo': CitaModel.normalizarMotivo(cita.motivo),
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

  /// Datos programados de la cita, sin ensamblar doctor ni paciente.
  ///
  /// La consulta que nace de una cita hereda de aquí su `fecha` (SD-160): el
  /// día que cuenta es el agendado, no el del clic. Devuelve `null` si el id no
  /// corresponde a ninguna cita viva, para que quien llame decida si eso es un
  /// defecto o un caso legítimo.
  Future<ReferenciaCita?> fetchReferenciaCita(String id) async {
    final res = await supabase
        .from('citas')
        .select('id, fecha_hora, estado, doctor_id, motivo')
        .eq('id', id)
        .filter('deleted_at', 'is', null)
        .maybeSingle();
    if (res == null) return null;
    return ReferenciaCita(
      id: res['id'] as String,
      fechaHora: DateTime.parse(res['fecha_hora'] as String).toLocal(),
      estado: EstadoCita.fromDb(res['estado'] as String?),
      doctorId: res['doctor_id'] as String,
      motivo: res['motivo'] as String?,
    );
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
