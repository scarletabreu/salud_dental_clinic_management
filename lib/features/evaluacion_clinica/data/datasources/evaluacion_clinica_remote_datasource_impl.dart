import 'package:salud_dental_clinic_management/features/evaluacion_clinica/data/datasources/evaluacion_clinica_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EvaluacionClinicaRemoteDatasourceImpl
    implements EvaluacionClinicaRemoteDatasource {
  final SupabaseClient supabaseClient;

  EvaluacionClinicaRemoteDatasourceImpl({required this.supabaseClient});

  static const _selectEvaluacion =
      '*, hallazgos:diagnosticos_aplicados!diagnosticos_aplicados_evaluacion_id_fkey('
      '*, diagnosis:diagnosticos(*))';

  @override
  Future<String> asegurarEvaluacionDeConsulta(Map<String, dynamic> data) async {
    final consultaId = data['consulta_id'] as String?;
    if (consultaId != null) {
      final existente = await supabaseClient
          .from('evaluaciones_clinicas')
          .select('id')
          .eq('consulta_id', consultaId)
          .isFilter('deleted_at', null)
          .maybeSingle();
      if (existente != null) return existente['id'] as String;
    }

    final ahora = DateTime.now().toUtc().toIso8601String();
    final fila = await supabaseClient
        .from('evaluaciones_clinicas')
        .insert({...data, 'created_at': ahora, 'updated_at': ahora})
        .select('id')
        .single();
    return fila['id'] as String;
  }

  @override
  Future<Map<String, dynamic>?> fetchPorConsulta(String consultaId) async {
    final fila = await supabaseClient
        .from('evaluaciones_clinicas')
        .select(_selectEvaluacion)
        .eq('consulta_id', consultaId)
        .isFilter('deleted_at', null)
        .maybeSingle();
    return fila == null ? null : Map<String, dynamic>.from(fila);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPorPaciente(String pacienteId) async {
    final filas = await supabaseClient
        .from('evaluaciones_clinicas')
        .select(_selectEvaluacion)
        .eq('paciente_id', pacienteId)
        .isFilter('deleted_at', null)
        .order('fecha', ascending: false);
    return List<Map<String, dynamic>>.from(filas as List);
  }

  @override
  Future<void> vincularHallazgos({
    required String evaluacionId,
    required String consultaId,
  }) async {
    await supabaseClient
        .from('diagnosticos_aplicados')
        .update({
          'evaluacion_id': evaluacionId,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('consulta_id', consultaId)
        .isFilter('evaluacion_id', null)
        .isFilter('deleted_at', null);
  }
}
