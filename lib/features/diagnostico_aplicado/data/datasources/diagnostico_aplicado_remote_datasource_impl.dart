import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/data/datasources/diagnostico_aplicado_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiagnosticoAplicadoRemoteDatasourceImpl
    implements DiagnosticoAplicadoRemoteDatasource {
  final SupabaseClient supabaseClient;

  DiagnosticoAplicadoRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<void> insertDiagnostico(Map<String, dynamic> data) async {
    try {
      data.remove('id');
      data['created_at'] = DateTime.now().toIso8601String();
      data['updated_at'] = DateTime.now().toIso8601String();
      await supabaseClient.from('diagnosticos_aplicados').insert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al aplicar el diagnóstico: ${e.message}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchByConsulta(String consultaId) async {
    try {
      final response = await supabaseClient
          .from('diagnosticos_aplicados')
          .select('*, diagnosis:diagnosticos(*)')
          .eq('consulta_id', consultaId)
          .filter('deleted_at', 'is', null);

      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception(
        'Error al recuperar diagnósticos de la consulta: ${e.message}',
      );
    } catch (e) {
      throw Exception('Error inesperado al cargar diagnósticos: $e');
    }
  }

  @override
  Future<void> deleteDiagnostico(String id) async {
    try {
      await supabaseClient
          .from('diagnosticos_aplicados')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar diagnóstico aplicado: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al eliminar: $e');
    }
  }
}
