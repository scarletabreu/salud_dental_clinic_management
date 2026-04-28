import 'package:salud_dental_clinic_management/features/consulta/data/datasources/consulta_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsultaRemoteDatasourceImpl implements ConsultaRemoteDatasource {
  final SupabaseClient supabaseClient;

  ConsultaRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<void> crearConsulta(Map<String, dynamic> consultaData) async {
    await supabaseClient.from('consultas').insert(consultaData);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchConsultasByPaciente(
    String pacienteId,
  ) async {
    final response = await supabaseClient
        .from('consultas')
        .select('*, recetas(*), odontograma(*), documentos_clinicos(*)')
        .eq('paciente_id', pacienteId)
        .isFilter('deleted_at', null)
        .order('fecha', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<Map<String, dynamic>?> fetchConsultaById(String id) async {
    return await supabaseClient
        .from('consultas')
        .select('*, recetas(*), odontograma(*), documentos_clinicos(*)')
        .eq('id', id)
        .isFilter('deleted_at', null)
        .maybeSingle();
  }

  @override
  Future<void> updateConsulta(
    String id,
    Map<String, dynamic> consultaData,
  ) async {
    await supabaseClient.from('consultas').update(consultaData).eq('id', id);
  }

  @override
  Future<void> deleteConsulta(String id) async {
    await supabaseClient
        .from('consultas')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
