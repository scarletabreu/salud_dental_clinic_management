import 'package:salud_dental_clinic_management/features/medicina/data/datasources/medicina_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MedicinaRemoteDatasourceImpl implements MedicinaRemoteDatasource {
  final SupabaseClient supabaseClient;

  MedicinaRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchMedicinas() async {
    final response = await supabaseClient
        .from('medicinas')
        .select('*')
        .filter('deleted_at', 'is', null);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<void> insertMedicina(Map<String, dynamic> data) async {
    data.remove('id');
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    await supabaseClient.from('medicinas').insert(data);
  }

  @override
  Future<void> upsertMedicina(Map<String, dynamic> data) async {
    if (!(_isValidUuid(data['id']))) {
      data.remove('id');
    }
    data['updated_at'] = DateTime.now().toIso8601String();
    await supabaseClient.from('medicinas').upsert(data);
  }

  bool _isValidUuid(dynamic id) {
    return id != null && id is String && id.length == 36 && id.contains('-');
  }

  @override
  Future<void> softDeleteMedicina(String id) async {
    await supabaseClient
        .from('medicinas')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }
}
