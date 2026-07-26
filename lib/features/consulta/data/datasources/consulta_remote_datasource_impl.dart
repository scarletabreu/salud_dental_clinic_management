import 'package:salud_dental_clinic_management/features/consulta/data/datasources/consulta_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/resultado_guardado_odontograma.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsultaRemoteDatasourceImpl implements ConsultaRemoteDatasource {
  final SupabaseClient supabaseClient;

  ConsultaRemoteDatasourceImpl({required this.supabaseClient});

  static const _selectConsulta =
      '*, recetas(*), documentos_clinicos(*), '
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
    final res = await supabaseClient.rpc(
      'crear_consulta_completa',
      params: params,
    );
    return res as String;
  }

  @override
  Future<String> finalizarConsulta({
    required String consultaId,
    String metodoPago = 'contado',
    String? nota,
  }) async {
    final res = await supabaseClient.rpc(
      'finalizar_consulta',
      params: {
        'p_consulta_id': consultaId,
        'p_metodo_pago': metodoPago,
        'p_nota': nota,
      },
    );
    return res as String;
  }

  @override
  Future<ResultadoGuardadoOdontograma> guardarResultadoConsulta({
    required String consultaId,
    required String? pacienteId,
    required Map<int, Map<String, dynamic>> dientesPorFdi,
    required List<Map<String, dynamic>> recetas,
    required Map<String, dynamic> evaluacionOdontologica,
    String? notas,
    Map<String, dynamic>? signosVitales,
    bool? finalizada,
  }) async {
    final now = DateTime.now().toIso8601String();
    final consultaPayload = <String, dynamic>{'updated_at': now};

    if (notas != null && notas.trim().isNotEmpty) {
      consultaPayload['notas'] = notas.trim();
    }
    if (signosVitales != null) {
      consultaPayload['signos_vitales'] = signosVitales;
    }
    if (finalizada != null) {
      consultaPayload['finalizada'] = finalizada;
    }
    if (consultaPayload.length > 1) {
      await supabaseClient
          .from('consultas')
          .update(consultaPayload)
          .eq('id', consultaId);
    }

    await supabaseClient.from('recetas').delete().eq('consulta_id', consultaId);

    if (recetas.isNotEmpty) {
      await supabaseClient.from('recetas').insert([
        for (final r in recetas)
          {...r, 'consulta_id': consultaId, 'updated_at': now},
      ]);
    }

    final odontograma = await supabaseClient
        .from('odontogramas')
        .select(
          'id, dientes(id, fdi_code, esta_ausente, observaciones, '
          'tratamientos_aplicados_ids, diagnosticos:diagnosticos_aplicados!diagnosticos_aplicados_diente_id_fkey(id))',
        )
        .eq('consulta_id', consultaId)
        .isFilter('deleted_at', null)
        .maybeSingle();
    if (odontograma == null) {
      if (dientesPorFdi.isEmpty) return const ResultadoGuardadoOdontograma();
      throw Exception('No se encontró el odontograma de la consulta.');
    }

    await supabaseClient
        .from('odontogramas')
        .update({
          'evaluacion_clinica': evaluacionOdontologica,
          'updated_at': now,
        })
        .eq('id', odontograma['id'] as String);

    final dientes = odontograma['dientes'] as List;
    final tratamientosPorFdi = <int, List<String>>{};
    final diagnosticosPorFdi = <int, List<String>>{};

    for (final d in dientes) {
      final fdi = (d['fdi_code'] as num).toInt();
      final dienteId = d['id'] as String;
      final actualesIds =
          (d['tratamientos_aplicados_ids'] as List?)?.cast<String>() ??
          const <String>[];
      final actualesDiagnosticosIds = ((d['diagnosticos'] as List?) ?? const [])
          .map((diagnostico) => (diagnostico as Map)['id'] as String?)
          .whereType<String>()
          .toList();

      final entrante = dientesPorFdi[fdi];
      final filas =
          (entrante?['tratamientos'] as List?)?.cast<Map<String, dynamic>>() ??
          const <Map<String, dynamic>>[];
      final filasDiagnosticos =
          (entrante?['diagnosticos'] as List?)?.cast<Map<String, dynamic>>() ??
          const <Map<String, dynamic>>[];
      final ausente = entrante?['esta_ausente'] as bool? ?? false;
      final observaciones = entrante?['observaciones'] as String?;

      final cambioEstadoPieza =
          ausente != (d['esta_ausente'] as bool? ?? false) ||
          observaciones != d['observaciones'] as String?;

      if (filas.isEmpty &&
          actualesIds.isEmpty &&
          filasDiagnosticos.isEmpty &&
          actualesDiagnosticosIds.isEmpty &&
          !cambioEstadoPieza) {
        continue;
      }

      final idsFinales = await _reconciliarTratamientos(
        consultaId: consultaId,
        dienteId: dienteId,
        filas: filas,
        actualesIds: actualesIds,
        now: now,
      );
      if (idsFinales.isNotEmpty) tratamientosPorFdi[fdi] = idsFinales;
      final diagnosticosFinales = await _reconciliarDiagnosticos(
        consultaId: consultaId,
        dienteId: dienteId,
        filas: filasDiagnosticos,
        actualesIds: actualesDiagnosticosIds,
        now: now,
      );
      if (diagnosticosFinales.isNotEmpty) {
        diagnosticosPorFdi[fdi] = diagnosticosFinales;
      }

      await supabaseClient
          .from('dientes')
          .update({
            'tratamientos_aplicados_ids': idsFinales,
            'esta_ausente': ausente,
            'observaciones': observaciones,
            'updated_at': now,
          })
          .eq('id', dienteId);
    }

    return ResultadoGuardadoOdontograma(
      tratamientosPorFdi: tratamientosPorFdi,
      diagnosticosPorFdi: diagnosticosPorFdi,
    );
  }

  Future<List<String>> _reconciliarDiagnosticos({
    required String consultaId,
    required String dienteId,
    required List<Map<String, dynamic>> filas,
    required List<String> actualesIds,
    required String now,
  }) async {
    final conservados = <String>{
      for (final fila in filas)
        if (fila['id'] case final String id) id,
    };
    final anulados = actualesIds.where((id) => !conservados.contains(id));
    if (anulados.isNotEmpty) {
      await supabaseClient
          .from('diagnosticos_aplicados')
          .update({'deleted_at': now, 'updated_at': now})
          .inFilter('id', anulados.toList());
    }

    final ids = <String>[];
    for (final fila in filas) {
      final payload = <String, dynamic>{
        ...fila,
        'consulta_id': consultaId,
        'diente_id': dienteId,
        'updated_at': now,
      };
      final id = payload.remove('id') as String?;
      if (id != null) {
        await supabaseClient
            .from('diagnosticos_aplicados')
            .update(payload)
            .eq('id', id);
        ids.add(id);
      } else {
        payload['created_at'] = now;
        final inserted = await supabaseClient
            .from('diagnosticos_aplicados')
            .insert(payload)
            .select('id')
            .single();
        ids.add(inserted['id'] as String);
      }
    }
    return ids;
  }

  /// Lleva las filas de `tratamientos_aplicados` de un diente al estado que
  /// describe [filas], conservando los ids de las que ya existían.
  ///
  /// Antes esto era un `delete` de toda la consulta seguido de un `insert`:
  /// cada guardado parcial reescribía los mismos tratamientos con ids nuevos,
  /// de modo que nada podía referenciarlos y el rastro se perdía.
  Future<List<String>> _reconciliarTratamientos({
    required String consultaId,
    required String dienteId,
    required List<Map<String, dynamic>> filas,
    required List<String> actualesIds,
    required String now,
  }) async {
    final conservados = <String>{
      for (final fila in filas)
        if (fila['id'] case final String id) id,
    };

    // Lo que el doctor quitó se anula, no se borra.
    final anulados = actualesIds.where((id) => !conservados.contains(id));
    if (anulados.isNotEmpty) {
      await supabaseClient
          .from('tratamientos_aplicados')
          .update({'deleted_at': now, 'updated_at': now})
          .inFilter('id', anulados.toList());
    }

    final idsFinales = <String>[];
    final porInsertar = <int, Map<String, dynamic>>{};

    for (var i = 0; i < filas.length; i++) {
      final fila = Map<String, dynamic>.from(filas[i]);
      final id = fila.remove('id') as String?;
      final campos = {
        ...fila,
        'diente_id': dienteId,
        'consulta_id': consultaId,
        'updated_at': now,
      };

      if (id == null) {
        porInsertar[i] = {...campos, 'created_at': now};
        idsFinales.add('');
        continue;
      }
      await supabaseClient
          .from('tratamientos_aplicados')
          .update(campos)
          .eq('id', id);
      idsFinales.add(id);
    }

    if (porInsertar.isNotEmpty) {
      final insertados =
          await supabaseClient
                  .from('tratamientos_aplicados')
                  .insert(porInsertar.values.toList())
                  .select('id')
              as List;
      final posiciones = porInsertar.keys.toList();
      for (var i = 0; i < posiciones.length; i++) {
        idsFinales[posiciones[i]] = insertados[i]['id'] as String;
      }
    }

    return idsFinales;
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
          'diente:dientes!inner(fdi_code), '
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
          'diente:dientes!inner(fdi_code), '
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
          'diente:dientes!inner(id, fdi_code), '
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
    final filas = await supabaseClient
        .from('consultas')
        .select('id, fecha, motivo_consulta, tipo_atencion, doctor_id')
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
