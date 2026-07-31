import 'package:salud_dental_clinic_management/features/consulta/data/datasources/consulta_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef CrearConsultaRpc =
    Future<dynamic> Function(Map<String, dynamic> params);

class ConsultaRemoteDatasourceImpl implements ConsultaRemoteDatasource {
  final SupabaseClient supabaseClient;
  final CrearConsultaRpc _crearConsultaRpc;
  bool? _soportaFlujoClinicoSeparado;

  ConsultaRemoteDatasourceImpl({
    required this.supabaseClient,
    CrearConsultaRpc? crearConsultaRpc,
  }) : _crearConsultaRpc =
           crearConsultaRpc ??
           ((params) =>
               supabaseClient.rpc('crear_consulta_completa', params: params));

  static const _selectConsulta =
      // Los insumos declarados se recuperan con la consulta: si no volvieran,
      // reanudarla los daría por retirados y el siguiente guardado los
      // anularía sin que nadie lo pidiera.
      '*, recetas(*), documentos_clinicos(*), '
      'consumos:consumos_consulta(consumible_id, nombre, cantidad), '
      'odontograma:odontogramas(id, consulta_id, evaluacion_clinica, '
      'dientes(id, odontograma_id, fdi_code, observaciones, esta_ausente, '
      'tratamientos_aplicados_ids, diagnosis:diagnosticos_aplicados!diagnosticos_aplicados_diente_id_fkey(*, '
      // El doctor de un hallazgo cuelga de su evaluación (SD-135): la ficha de
      // la pieza tiene que poder decir quién lo anotó.
      'evaluacion:evaluaciones_clinicas(doctor_id), '
      'diagnosis:diagnosticos(*)), tratamientos:tratamientos_aplicados(*, '
      'tratamiento:tratamientos(*))))';

  @override
  Future<String> crearConsultaCompleta(Map<String, dynamic> params) async {
    if (_soportaFlujoClinicoSeparado == false) {
      return _crearConsultaConFirmaAnterior(params);
    }
    try {
      final id = await _crearConsultaRpc(params) as String;
      _soportaFlujoClinicoSeparado = true;
      return id;
    } on PostgrestException catch (error) {
      if (!_esFirmaNuevaAusente(error)) rethrow;
      _soportaFlujoClinicoSeparado = false;
      return _crearConsultaConFirmaAnterior(params);
    }
  }

  Future<String> _crearConsultaConFirmaAnterior(
    Map<String, dynamic> params,
  ) async {
    // La firma anterior representa siempre una consulta de ejecución. Usarla
    // para una evaluación perdería su tipo y falsearía el expediente.
    if (params['p_tipo_atencion'] != 'consulta') {
      throw const PostgrestException(
        message:
            'La base de datos clínica aún no permite separar evaluaciones '
            'de tratamientos. Aplica las migraciones pendientes antes de '
            'registrar una evaluación.',
        code: 'PGRST202',
      );
    }

    final paramsCompatibles = Map<String, dynamic>.from(params)
      ..remove('p_tipo_atencion');
    return await _crearConsultaRpc(paramsCompatibles) as String;
  }

  bool _esFirmaNuevaAusente(PostgrestException error) =>
      error.code == 'PGRST202' &&
      error.message.contains('crear_consulta_completa') &&
      error.message.contains('p_tipo_atencion');

  @override
  Future<Map<String, dynamic>> guardarBorradorConsulta({
    required String consultaId,
    int? version,
    required Map<String, dynamic> payload,
  }) async {
    final respuesta = await supabaseClient.rpc(
      'guardar_borrador_consulta',
      params: {
        'p_consulta_id': consultaId,
        'p_version': version,
        'p_payload': payload,
      },
    );
    return Map<String, dynamic>.from(respuesta as Map);
  }

  @override
  Future<void> resolverAlertaClinica({
    required String alertaId,
    required String estado,
    String? justificacion,
  }) async {
    await supabaseClient.rpc(
      'resolver_alerta_clinica',
      params: {
        'p_alerta_id': alertaId,
        'p_estado': estado,
        'p_justificacion': justificacion,
      },
    );
  }

  @override
  Future<Map<String, dynamic>> cerrarConsulta({
    required String consultaId,
    int? version,
    Map<String, dynamic> payload = const {},
    required String idempotenciaKey,
    String metodoPago = 'contado',
    String? nota,
  }) async {
    final respuesta = await supabaseClient.rpc(
      'cerrar_consulta',
      params: {
        'p_consulta_id': consultaId,
        'p_version': version,
        'p_payload': payload,
        'p_idempotencia_key': idempotenciaKey,
        'p_metodo_pago': metodoPago,
        'p_nota': nota,
      },
    );
    return Map<String, dynamic>.from(respuesta as Map);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchConsultas() async {
    final response = await supabaseClient
        .from('consultas')
        .select(_selectConsulta)
        .isFilter('deleted_at', null)
        .order('fecha', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchConsultasByDoctor(
    String doctorId,
  ) async {
    final response = await supabaseClient
        .from('consultas')
        .select(_selectConsulta)
        .eq('doctor_id', doctorId)
        .isFilter('deleted_at', null)
        .order('fecha', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchConsultasPorCitaIds(
    List<String> citaIds,
  ) async {
    if (citaIds.isEmpty) return const [];
    final response = await supabaseClient
        .from('consultas')
        .select('id, cita_id, finalizada')
        .inFilter('cita_id', citaIds)
        .isFilter('deleted_at', null);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchConsultasByPaciente(
    String pacienteId,
  ) async {
    final response = await supabaseClient
        .from('consultas')
        .select(_selectConsulta)
        .eq('paciente_id', pacienteId)
        .isFilter('deleted_at', null)
        .order('fecha', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<Map<String, dynamic>?> fetchConsultaById(String id) async {
    return await supabaseClient
        .from('consultas')
        .select(_selectConsulta)
        .eq('id', id)
        .isFilter('deleted_at', null)
        .maybeSingle();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTratamientosAplicadosPorIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    final response = await supabaseClient
        .from('tratamientos_aplicados')
        .select('*, tratamiento:tratamientos(nombre)')
        .inFilter('id', ids)
        .isFilter('deleted_at', null);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTratamientosHistoricosPaciente(
    String pacienteId, {
    String? excluyendoConsultaId,
    bool incluyendoAnulados = false,
  }) async {
    var query = supabaseClient
        .from('tratamientos_aplicados')
        .select(
          // La clave del catálogo es lo que decide cómo se dibuja la pieza:
          // sin ella todo tratamiento previo caía en «Otro».
          '*, tratamiento:tratamientos(nombre, clave_odontograma), '
          'diente:dientes!tratamientos_aplicados_diente_id_fkey!inner(fdi_code), '
          'consulta:consultas!inner(paciente_id, fecha)',
        )
        .eq('consulta.paciente_id', pacienteId);

    if (!incluyendoAnulados) {
      query = query.isFilter('deleted_at', null);
    }

    if (excluyendoConsultaId != null) {
      query = query.neq('consulta_id', excluyendoConsultaId);
    }

    final response = await query.order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchDiagnosticosHistoricosPaciente(
    String pacienteId, {
    String? excluyendoConsultaId,
    bool incluyendoAnulados = false,
  }) async {
    var query = supabaseClient
        .from('diagnosticos_aplicados')
        .select(
          '*, diagnosis:diagnosticos(nombre, clave_odontograma), '
          'evaluacion:evaluaciones_clinicas(doctor_id), '
          'diente:dientes!diagnosticos_aplicados_diente_id_fkey!inner(fdi_code), '
          // `doctor_id` de la consulta es el respaldo para las filas anteriores
          // a SD-135, que no cuelgan de ninguna evaluación.
          'consulta:consultas!inner(paciente_id, fecha, doctor_id)',
        )
        .eq('consulta.paciente_id', pacienteId);

    if (!incluyendoAnulados) {
      query = query.isFilter('deleted_at', null);
    }

    if (excluyendoConsultaId != null) {
      query = query.neq('consulta_id', excluyendoConsultaId);
    }

    // De la más reciente a la más antigua: al consolidar gana la primera que
    // anota cada pieza, es decir la última palabra del doctor.
    final response = await query.order(
      'fecha',
      referencedTable: 'consulta',
      ascending: false,
    );
    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchEvaluacionesPaciente(
    String pacienteId, {
    String? excluyendoConsultaId,
  }) async {
    var query = supabaseClient
        .from('odontogramas')
        .select(
          'evaluacion_clinica, consulta:consultas!inner(paciente_id, fecha)',
        )
        .eq('consulta.paciente_id', pacienteId)
        .isFilter('deleted_at', null);

    if (excluyendoConsultaId != null) {
      query = query.neq('consulta_id', excluyendoConsultaId);
    }

    // De la más reciente a la más antigua: al consolidar gana la primera que
    // anota cada pieza, es decir la última palabra del doctor.
    final response = await query.order(
      'fecha',
      referencedTable: 'consulta',
      ascending: false,
    );
    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchItemsPlanPorPaciente(
    String pacienteId,
  ) async {
    // Sin filtro por `deleted_at` de la actividad: una actividad retirada del
    // plan sigue siendo parte de la historia de la pieza. El plan sí se exige
    // vivo, porque un plan borrado se retiró entero.
    final filas = await supabaseClient
        .from('items_plan_tratamiento')
        .select(
          '*, tratamiento:tratamientos(id, nombre, costo, alcance), '
          'diente:dientes!items_plan_tratamiento_diente_id_fkey!inner(id, fdi_code), '
          'plan:planes_tratamiento!inner(id, paciente_id, consulta_origen_id, '
          'deleted_at)',
        )
        .eq('plan.paciente_id', pacienteId)
        .isFilter('plan.deleted_at', null)
        .order('fecha_propuesta', ascending: false);
    return List<Map<String, dynamic>>.from(filas as List);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchReferenciasConsultasPaciente(
    String pacienteId,
  ) async {
    if (_soportaFlujoClinicoSeparado == false) {
      return _fetchReferenciasConsultasAnteriores(pacienteId);
    }
    try {
      final filas = await supabaseClient
          .from('consultas')
          .select('id, fecha, motivo_consulta, tipo_atencion, doctor_id')
          .eq('paciente_id', pacienteId)
          .order('fecha', ascending: false);
      _soportaFlujoClinicoSeparado = true;
      return List<Map<String, dynamic>>.from(filas as List);
    } on PostgrestException catch (error) {
      if (!error.message.contains('tipo_atencion')) rethrow;
      _soportaFlujoClinicoSeparado = false;
      return _fetchReferenciasConsultasAnteriores(pacienteId);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchReferenciasConsultasAnteriores(
    String pacienteId,
  ) async {
    // Antes de SD-138 todas las atenciones eran consultas. El modelo ya
    // interpreta la ausencia del campo con ese mismo valor por defecto.
    final filas = await supabaseClient
        .from('consultas')
        .select('id, fecha, motivo_consulta, doctor_id')
        .eq('paciente_id', pacienteId)
        .order('fecha', ascending: false);
    return List<Map<String, dynamic>>.from(filas as List);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchNombresDoctores(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return const [];
    final filas = await supabaseClient
        .from('doctores')
        .select('id, usuarios(personas(nombre, apellido))')
        .inFilter('id', ids);
    return List<Map<String, dynamic>>.from(filas as List);
  }

  @override
  Future<void> updateConsulta(
    String id,
    Map<String, dynamic> consultaData,
  ) async {
    consultaData.remove('id');
    consultaData['updated_at'] = DateTime.now().toIso8601String();
    await supabaseClient.from('consultas').update(consultaData).eq('id', id);
  }

  @override
  Future<void> deleteConsulta(String id) async {
    await supabaseClient
        .from('consultas')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }
}
