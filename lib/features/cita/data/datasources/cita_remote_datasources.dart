import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/core/util/app_log.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/features/cita/data/models/actividad_planificada_model.dart';
import 'package:salud_dental_clinic_management/features/cita/data/models/cita_model.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/actividad_planificada.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/referencia_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';

class CitaRemoteDataSource {
  final SupabaseClient supabase;

  CitaRemoteDataSource(this.supabase);

  /// Citas reales de la base. Un fallo de red, de RLS o de esquema se propaga
  /// para que el guard del repositorio lo convierta en un `Failure` tipado y la
  /// agenda pinte su estado de error: nunca se sustituye por datos inventados.
  ///
  /// [desde] y [hasta] acotan el rango **en el servidor**. Sin ellos la consulta
  /// traía TODAS las citas de la historia de la clínica y después resolvía sus
  /// pacientes una por una: con decenas de citas no se nota, con dos años de
  /// operación la agenda degrada linealmente en transferencia, memoria y render
  /// (§1.3 del audit). La agenda pide la ventana que está mirando y la recarga
  /// al navegar fuera de ella.
  Future<List<CitaModel>> fetchCitas({DateTime? desde, DateTime? hasta}) async {
    final citasRes = await _enRango(
      supabase.from('citas').select('*').filter('deleted_at', 'is', null),
      desde,
      hasta,
    );
    return _assembleCitas(citasRes as List);
  }

  Future<List<CitaModel>> fetchCitasByPaciente(
    String pacienteId, {
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final citasRes = await _enRango(
      supabase
          .from('citas')
          .select('*')
          .eq('persona_id', pacienteId)
          .filter('deleted_at', 'is', null),
      desde,
      hasta,
    );
    return _assembleCitas(citasRes as List);
  }

  Future<List<CitaModel>> fetchCitasByDoctor(
    String doctorId, {
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final citasRes = await _enRango(
      supabase
          .from('citas')
          .select('*')
          .eq('doctor_id', doctorId)
          .filter('deleted_at', 'is', null),
      desde,
      hasta,
    );
    return _assembleCitas(citasRes as List);
  }

  Future<dynamic> _enRango(
    PostgrestFilterBuilder<dynamic> consulta,
    DateTime? desde,
    DateTime? hasta,
  ) {
    var q = consulta;
    if (desde != null) {
      q = q.gte('fecha_hora', desde.toUtc().toIso8601String());
    }
    if (hasta != null) {
      q = q.lt('fecha_hora', hasta.toUtc().toIso8601String());
    }
    return q;
  }

  Future<List<CitaModel>> _assembleCitas(List rawCitas) async {
    if (rawCitas.isEmpty) return [];

    final personaIds = rawCitas
        .where((c) => (c as Map<String, dynamic>)['persona_id'] != null)
        .map((c) => (c as Map<String, dynamic>)['persona_id'] as String)
        .toSet()
        .toList();

    // 1. OBTENER DOCTORES USANDO EL RPC SEGURO (Bypass / Respeta RLS correctamente)
    //
    // El fallo se propaga en vez de tragarse. Antes iba en un `try/catch` que
    // sólo escribía en el log y seguía: con la red o el RPC caídos la agenda
    // «cargaba» y las citas salían huérfanas de doctor, sin ningún estado de
    // error, contradiciendo el contrato declarado en la cabecera de este mismo
    // archivo —«nunca se sustituye por datos inventados»—, que sí se cumplía
    // para las citas pero no para sus doctores (§1.2 del audit).
    final Map<String, Map<String, dynamic>> doctorMaps = {};
    final responseDoctores = await supabase.rpc('get_active_doctors');
    for (final docJson in (responseDoctores as List)) {
      final m = docJson as Map<String, dynamic>;
      final id = m['doctor_id'] as String?;
      if (id != null) {
        doctorMaps[id] = m;
      }
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

    // 2b. Actividades planificadas de cada cita (SD-146). Se piden en un solo
    // viaje para que la agenda pueda mostrar el resumen sin ir al servidor en
    // cada hover. Es información accesoria: si falla, las citas se ven igual.
    final citaIds = rawCitas
        .map((c) => (c as Map<String, dynamic>)['id'] as String?)
        .whereType<String>()
        .toList();
    final actividadesPorCita = await _fetchActividadesDeCitas(citaIds);

    final List<CitaModel> result = [];

    // 3. Ensamblar las citas combinando la información obtenida
    for (final c in rawCitas) {
      try {
        final json = Map<String, dynamic>.from(c as Map);
        final doctorId = json['doctor_id'] as String?;
        json['actividades'] = actividadesPorCita[json['id']] ?? const [];

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
          'especialidad': dp['especialidad'] ?? '',
          'esta_disponible': dp['esta_disponible'] ?? true,
          'assistants': dp['assistants'] ?? <dynamic>[],
          'contacto':
              dp['contacto'] ??
              const {'email': '', 'numero_telefono': '', 'direccion': ''},
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

  /// Resumen de las actividades de un lote de citas, agrupado por `cita_id`.
  ///
  /// Lee la vista `resumen_actividades_cita` y no las tablas del plan: el
  /// asistente que gestiona la agenda no tiene permiso de lectura sobre
  /// `items_plan_tratamiento` ni sobre el catálogo de tratamientos (SD-146).
  Future<Map<String, List<Map<String, dynamic>>>> _fetchActividadesDeCitas(
    List<String> citaIds,
  ) async {
    if (citaIds.isEmpty) return const {};
    try {
      final res = await supabase
          .from('resumen_actividades_cita')
          .select()
          .inFilter('cita_id', citaIds);

      final agrupadas = <String, List<Map<String, dynamic>>>{};
      for (final row in res as List) {
        final fila = Map<String, dynamic>.from(row as Map);
        final citaId = fila['cita_id'] as String?;
        if (citaId == null) continue;
        agrupadas.putIfAbsent(citaId, () => []).add(fila);
      }
      return agrupadas;
    } catch (e) {
      AppLog.error('actividades planificadas de las citas', e);
      return const {};
    }
  }

  /// Actividades del plan de [pacienteId] que todavía pueden agendarse.
  ///
  /// A diferencia de las anteriores, un fallo aquí sí se propaga: el formulario
  /// tiene que distinguir «este paciente no tiene actividades pendientes» de
  /// «no se pudieron cargar», o el usuario agendaría a ciegas.
  Future<List<ActividadPlanificada>> fetchActividadesAgendables(
    String pacienteId,
  ) async {
    final res = await supabase
        .from('actividades_agendables_paciente')
        .select()
        .eq('paciente_id', pacienteId)
        .order('orden');

    return [
      for (final row in res as List)
        ActividadPlanificadaModel.fromJson(
          Map<String, dynamic>.from(row as Map),
        ),
    ];
  }

  Future<void> addCita(CitaModel cita) async {
    final data = cita.toJson();

    if (!_isValidUuid(data['id'])) {
      data.remove('id');
    }

    final now = DateTime.now().toUtc().toIso8601String();
    data['created_at'] = now;
    data['updated_at'] = now;

    final fila = await supabase
        .from('citas')
        .insert(data)
        .select('id')
        .single();
    await _vincularActividades(fila['id'] as String, cita.actividades);
  }

  /// Reemplaza los vínculos de la cita por [actividades].
  ///
  /// Se hace en dos pasos (borrar los que sobran, insertar los que faltan) en
  /// vez de borrar todo y reinsertar: así reprogramar una cita sin tocar sus
  /// actividades no pierde el `created_at` del vínculo.
  Future<void> _sincronizarActividades(
    String citaId,
    List<ActividadPlanificada> actividades,
  ) async {
    final deseados = {for (final a in actividades) a.itemPlanId};

    final actuales = await supabase
        .from('citas_items_plan')
        .select('item_plan_id')
        .eq('cita_id', citaId);
    final existentes = {
      for (final row in actuales as List)
        (row as Map<String, dynamic>)['item_plan_id'] as String,
    };

    final sobran = existentes.difference(deseados);
    if (sobran.isNotEmpty) {
      await supabase
          .from('citas_items_plan')
          .delete()
          .eq('cita_id', citaId)
          .inFilter('item_plan_id', sobran.toList());
    }

    final faltan = deseados.difference(existentes);
    if (faltan.isNotEmpty) {
      await supabase.from('citas_items_plan').insert([
        for (final itemPlanId in faltan)
          {'cita_id': citaId, 'item_plan_id': itemPlanId},
      ]);
    }
  }

  /// Vincula las actividades de una cita recién creada.
  ///
  /// La cita ya existe cuando esto corre, así que un fallo aquí deja una cita
  /// sin sus actividades. El mensaje lo dice explícitamente para que nadie la
  /// vuelva a crear pensando que no se guardó: el trigger
  /// `trg_validar_cita_item_plan` solo rechaza lo que el formulario no ofrece
  /// (actividad de otro paciente, retirada o ya cerrada), así que llegar aquí es
  /// un defecto o una caída de red.
  Future<void> _vincularActividades(
    String citaId,
    List<ActividadPlanificada> actividades,
  ) async {
    if (actividades.isEmpty) return;
    try {
      await _sincronizarActividades(citaId, actividades);
    } catch (e) {
      AppLog.error('vincular actividades de la cita $citaId', e);
      throw ServerFailure(
        'La cita se guardó, pero no se pudieron vincular sus actividades del '
        'plan: $e. Edítala para volver a seleccionarlas.',
      );
    }
  }

  /// `registrar_llegada_cita`: la base valida quién puede marcarla y no falla
  /// si ya estaba marcada.
  Future<void> registrarLlegada(String citaId) async {
    await supabase.rpc('registrar_llegada_cita', params: {'p_cita_id': citaId});
  }

  /// `registrar_cita_emergencia`: devuelve el id de la cita de urgencia creada.
  Future<String> registrarEmergencia({
    required String pacienteId,
    required String doctorId,
    String? motivo,
  }) async {
    final respuesta = await supabase.rpc(
      'registrar_cita_emergencia',
      params: {
        'p_paciente_id': pacienteId,
        'p_doctor_id': doctorId,
        'p_motivo': motivo,
      },
    );
    return (respuesta as Map)['cita_id'] as String;
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
      // `es_emergencia` no viaja: encenderla al editar saca la cita del control
      // de solapes sin dejar constancia del motivo, y desde `audit_005` la base
      // lo rechaza. Una urgencia se declara al registrarla, por
      // `registrar_cita_emergencia` (F3-04).
      'estado': cita.estado.dbValue,
      'motivo': CitaModel.normalizarMotivo(cita.motivo),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await supabase.from('citas').update(data).eq('id', cita.id!);
    await _sincronizarActividades(cita.id!, cita.actividades);
  }

  Future<void> deleteCita(String id) async {
    await supabase
        .from('citas')
        .update({
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
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
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  bool _isValidUuid(dynamic id) =>
      id != null && id is String && id.length == 36 && id.contains('-');
}
