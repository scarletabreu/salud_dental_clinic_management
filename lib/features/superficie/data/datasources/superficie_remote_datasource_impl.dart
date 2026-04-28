import 'package:salud_dental_clinic_management/features/superficie/data/datasources/superficie_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SuperficieRemoteDatasourceImpl implements SuperficieRemoteDatasource {
  final SupabaseClient supabaseClient;

  SuperficieRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<void> actualizarSuperficie(Map<String, dynamic> data) async {
    await supabaseClient.from('superficies').upsert(data);
  }

  @override
  Future<void> eliminarSuperficie(String id) async {
    await supabaseClient
        .from('superficies')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSuperficiesPorDiente(
    String dienteId,
  ) async {
    final response = await supabaseClient
        .from('superficies')
        .select()
        .eq('diente_id', dienteId)
        .isFilter('deleted_at', null);
    return List<Map<String, dynamic>>.from(response);
  }
}
