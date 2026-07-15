import 'package:salud_dental_clinic_management/features/consulta/data/datasources/consulta_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsultaRemoteDatasourceImpl implements ConsultaRemoteDatasource {
  final SupabaseClient supabaseClient;

  ConsultaRemoteDatasourceImpl({required this.supabaseClient});

  static const _selectConsulta =
      '*, recetas(*), documentos_clinicos(*), '
      'odontograma:odontogramas(id, consulta_id, '
      'dientes(id, odontograma_id, fdi_code, observaciones, '
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
  Future<void> guardarResultadoConsulta({
    required String consultaId,
    required String? pacienteId,
    required Map<int, List<Map<String, dynamic>>> tratamientosPorFdi,
    required List<Map<String, dynamic>> recetas,
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
          {
            ...r,
            'consulta_id': consultaId,
            'updated_at': now,
          },
      ]);
    }

    final odontograma = await supabaseClient
        .from('odontogramas')
        .select('id, dientes(id, fdi_code, tratamientos_aplicados_ids)')
        .eq('consulta_id', consultaId)
        .isFilter('deleted_at', null)
        .maybeSingle();
    if (odontograma == null) {
      if (tratamientosPorFdi.isEmpty) return;
      throw Exception('No se encontró el odontograma de la consulta.');
    }

    final dientes = odontograma['dientes'] as List;

    await supabaseClient
        .from('tratamientos_aplicados')
        .delete()
        .eq('consulta_id', consultaId);

    for (final d in dientes) {
      final fdi = (d['fdi_code'] as num).toInt();
      final dienteId = d['id'] as String;
      final actualesIds =
          (d['tratamientos_aplicados_ids'] as List?)?.cast<String>() ??
          const [];
      final filas = tratamientosPorFdi[fdi] ?? const [];

      if (filas.isEmpty && actualesIds.isEmpty) continue;

      var nuevosIds = const <String>[];
      if (filas.isNotEmpty) {
        final insertados = await supabaseClient
            .from('tratamientos_aplicados')
            .insert([
              for (final fila in filas)
                {
                  ...fila,
                  'diente_id': dienteId,
                  'consulta_id': consultaId,
                  'created_at': now,
                  'updated_at': now,
                },
            ])
            .select('id');
        nuevosIds = [
          for (final row in insertados as List) row['id'] as String,
        ];
      }

      await supabaseClient
          .from('dientes')
          .update({
            'tratamientos_aplicados_ids': nuevosIds,
            'updated_at': now,
          })
          .eq('id', dienteId);
    }
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
