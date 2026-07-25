import 'package:salud_dental_clinic_management/features/consulta/data/datasources/consulta_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsultaRemoteDatasourceImpl implements ConsultaRemoteDatasource {
  final SupabaseClient supabaseClient;

  ConsultaRemoteDatasourceImpl({required this.supabaseClient});

  static const _selectConsulta =
      '*, recetas(*), documentos_clinicos(*), '
      'odontograma:odontogramas(id, consulta_id, evaluacion_clinica, '
      'dientes(id, odontograma_id, fdi_code, observaciones, esta_ausente, '
      'tratamientos_aplicados_ids))';

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
  Future<Map<int, List<String>>> guardarResultadoConsulta({
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
          'tratamientos_aplicados_ids)',
        )
        .eq('consulta_id', consultaId)
        .isFilter('deleted_at', null)
        .maybeSingle();
    if (odontograma == null) {
      if (dientesPorFdi.isEmpty) return const {};
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
    final idsPorFdi = <int, List<String>>{};

    for (final d in dientes) {
      final fdi = (d['fdi_code'] as num).toInt();
      final dienteId = d['id'] as String;
      final actualesIds =
          (d['tratamientos_aplicados_ids'] as List?)?.cast<String>() ??
          const <String>[];

      final entrante = dientesPorFdi[fdi];
      final filas =
          (entrante?['tratamientos'] as List?)?.cast<Map<String, dynamic>>() ??
          const <Map<String, dynamic>>[];
      final ausente = entrante?['esta_ausente'] as bool? ?? false;
      final observaciones = entrante?['observaciones'] as String?;

      final cambioEstadoPieza =
          ausente != (d['esta_ausente'] as bool? ?? false) ||
          observaciones != d['observaciones'] as String?;

      if (filas.isEmpty && actualesIds.isEmpty && !cambioEstadoPieza) continue;

      final idsFinales = await _reconciliarTratamientos(
        consultaId: consultaId,
        dienteId: dienteId,
        filas: filas,
        actualesIds: actualesIds,
        now: now,
      );
      if (idsFinales.isNotEmpty) idsPorFdi[fdi] = idsFinales;

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

    return idsPorFdi;
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
  }) async {
    var query = supabaseClient
        .from('tratamientos_aplicados')
        .select(
          '*, tratamiento:tratamientos(nombre), '
          'diente:dientes!inner(fdi_code), '
          'consulta:consultas!inner(paciente_id, fecha)',
        )
        .eq('consulta.paciente_id', pacienteId)
        .isFilter('deleted_at', null);

    if (excluyendoConsultaId != null) {
      query = query.neq('consulta_id', excluyendoConsultaId);
    }

    final response = await query.order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchEvaluacionesPaciente(
    String pacienteId, {
    String? excluyendoConsultaId,
  }) async {
    var query = supabaseClient
        .from('odontogramas')
        .select('evaluacion_clinica, consulta:consultas!inner(paciente_id, fecha)')
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
