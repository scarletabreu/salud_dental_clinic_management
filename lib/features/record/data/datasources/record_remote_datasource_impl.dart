import 'package:salud_dental_clinic_management/features/record/data/datasources/record_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecordRemoteDatasourceImpl implements RecordRemoteDatasource {
  final SupabaseClient supabaseClient;

  RecordRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<Map<String, dynamic>?> fetchRecordByPaciente(String pacienteId) async {
    final response = await supabaseClient
        .from('records')
        .select('*, consultas(*)')
        .eq('paciente_id', pacienteId)
        .isFilter('deleted_at', null)
        .maybeSingle();
    return response;
  }

  @override
  Future<void> upsertRecord(Map<String, dynamic> data) async {
    await supabaseClient.from('records').upsert(data);
  }

  @override
  Future<void> anularRecord(String id) async {
    await supabaseClient
        .from('records')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
