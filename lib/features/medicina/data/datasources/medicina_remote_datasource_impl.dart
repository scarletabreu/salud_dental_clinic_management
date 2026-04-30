import 'package:supabase_flutter/supabase_flutter.dart';
import 'medicina_remote_datasource.dart';

class MedicinaRemoteDatasourceImpl implements MedicinaRemoteDatasource {
  final SupabaseClient supabaseClient;

  MedicinaRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchMedicinas() async {
    try {
      final response = await supabaseClient
          .from('medicinas')
          .select('*')
          .filter('deleted_at', 'is', null);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> insertMedicina(Map<String, dynamic> data) async {
    await supabaseClient.from('medicinas').insert(data);
  }

  @override
  Future<void> upsertMedicina(Map<String, dynamic> data) async {
    await supabaseClient.from('medicinas').upsert(data);
  }

  @override
  Future<void> softDeleteMedicina(String id) async {
    await supabaseClient
        .from('medicinas')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
