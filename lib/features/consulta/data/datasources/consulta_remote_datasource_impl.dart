import 'package:salud_dental_clinic_management/features/consulta/data/datasources/consulta_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsultaRemoteDatasourceImpl implements ConsultaRemoteDatasource {
  final SupabaseClient supabaseClient;

  ConsultaRemoteDatasourceImpl({required this.supabaseClient});

  /// Embed común del listado/detalle. Solo relaciones con FK fiable hacia
  /// `consultas`: recetas, documentos clínicos y el odontograma con sus
  /// dientes (los tratamientos cuelgan de `dientes.tratamientos_aplicados_ids`).
  static const _selectConsulta =
      '*, recetas(*), documentos_clinicos(*), '
      'odontograma:odontogramas(id, consulta_id, '
      'dientes(id, odontograma_id, fdi_code, observaciones, '
      'tratamientos_aplicados_ids))';

  @override
  Future<String> crearConsultaCompleta(Map<String, dynamic> params) async {
    try {
      final res = await supabaseClient.rpc(
        'crear_consulta_completa',
        params: params,
      );
      return res as String;
    } on PostgrestException catch (e) {
      throw Exception('Error al crear la consulta completa: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al crear la consulta completa: $e');
    }
  }

  @override
  Future<void> guardarResultadoConsulta({
    required String consultaId,
    required String? pacienteId,
    required Map<int, List<Map<String, dynamic>>> tratamientosPorFdi,
    String? notas,
    Map<String, dynamic>? signosVitales,
    bool? finalizada,
    List<Map<String, dynamic>>? recetas,
  }) async {
    try {
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

      if (recetas != null && recetas.isNotEmpty && pacienteId != null) {
        await supabaseClient.from('recetas').insert(
          recetas
              .map((receta) => {
                    ...receta,
                    'paciente_id': pacienteId,
                    'created_at': receta['created_at'] ?? now,
                    'updated_at': now,
                  })
              .toList(),
        );
      }

      final odontograma = await supabaseClient
          .from('odontogramas')
          .select('id, dientes(id, fdi_code, tratamientos_aplicados_ids)')
          .eq('consulta_id', consultaId)
          .isFilter('deleted_at', null)
          .maybeSingle();
      if (odontograma == null) {
        // Sin odontograma no hay dónde colgar tratamientos. Si tampoco hay
        // nada que guardar, terminamos en silencio (p. ej. guardar solo notas).
        if (tratamientosPorFdi.isEmpty) return;
        throw Exception('No se encontró el odontograma de la consulta.');
      }

      final dientes = odontograma['dientes'] as List;

      // Reemplazo idempotente: borramos los tratamientos aplicados de ESTA
      // consulta y los reinsertamos desde el estado en memoria (fuente de
      // verdad). Así guardar avance N veces no duplica filas ni deja huérfanos.
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

        // Nada que poner ni que limpiar en este diente: no lo tocamos.
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
    } on PostgrestException catch (e) {
      throw Exception(
        'Error al guardar el resultado de la consulta: ${e.message}',
      );
    } catch (e) {
      throw Exception('Error inesperado al guardar la consulta: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchConsultas() async {
    try {
      final response = await supabaseClient
          .from('consultas')
          .select(_selectConsulta)
          .isFilter('deleted_at', null)
          .order('fecha', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener el listado de consultas: ${e.message}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchConsultasByDoctor(
    String doctorId,
  ) async {
    try {
      final response = await supabaseClient
          .from('consultas')
          .select(_selectConsulta)
          .eq('doctor_id', doctorId)
          .isFilter('deleted_at', null)
          .order('fecha', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception(
        'Error al obtener consultas del doctor: ${e.message}',
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchConsultasByPaciente(
    String pacienteId,
  ) async {
    try {
      final response = await supabaseClient
          .from('consultas')
          .select(_selectConsulta)
          .eq('paciente_id', pacienteId)
          .isFilter('deleted_at', null)
          .order('fecha', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener historial de consultas: ${e.message}');
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchConsultaById(String id) async {
    try {
      return await supabaseClient
          .from('consultas')
          .select(_selectConsulta)
          .eq('id', id)
          .isFilter('deleted_at', null)
          .maybeSingle();
    } on PostgrestException catch (e) {
      throw Exception('Error al recuperar consulta clínica: ${e.message}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTratamientosAplicadosPorIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    try {
      final response = await supabaseClient
          .from('tratamientos_aplicados')
          .select('*, tratamiento:tratamientos(nombre)')
          .inFilter('id', ids)
          .isFilter('deleted_at', null);

      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener tratamientos aplicados: ${e.message}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTratamientosHistoricosPaciente(
    String pacienteId, {
    String? excluyendoConsultaId,
  }) async {
    try {
      // `!inner` en consultas → filtra por paciente; `!inner` en dientes →
      // descarta tratamientos generales (sin diente) y trae el fdi_code para
      // proyectar sobre el odontograma.
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
    } on PostgrestException catch (e) {
      throw Exception(
        'Error al obtener historial de tratamientos del paciente: ${e.message}',
      );
    }
  }

  @override
  Future<void> updateConsulta(
    String id,
    Map<String, dynamic> consultaData,
  ) async {
    try {
      consultaData.remove('id');
      consultaData['updated_at'] = DateTime.now().toIso8601String();
      await supabaseClient.from('consultas').update(consultaData).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar consulta: ${e.message}');
    }
  }

  @override
  Future<void> deleteConsulta(String id) async {
    try {
      await supabaseClient
          .from('consultas')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar consulta: ${e.message}');
    }
  }
}
