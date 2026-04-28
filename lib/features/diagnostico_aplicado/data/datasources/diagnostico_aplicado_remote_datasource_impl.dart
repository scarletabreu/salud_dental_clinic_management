import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/data/datasources/diagnostico_aplicado_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiagnosticoAplicadoRemoteDatasourceImpl
    implements DiagnosticoAplicadoRemoteDatasource {
  final SupabaseClient supabaseClient;

  DiagnosticoAplicadoRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<void> insertDiagnostico(Map<String, dynamic> data) async {
    await supabaseClient.from('diagnosticos_aplicados').insert(data);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchByConsulta(String consultaId) async {
    final response = await supabaseClient
        .from('diagnosticos_aplicados')
        .select('*, diagnosis:diagnosticos(*)')
        .eq('consulta_id', consultaId)
        .isFilter('deleted_at', null);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> deleteDiagnostico(String id) async {
    await supabaseClient
        .from('diagnosticos_aplicados')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
