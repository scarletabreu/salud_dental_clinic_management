import 'package:salud_dental_clinic_management/features/suplidor/data/datasources/suplidor_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SuplidorRemoteDatasourceImpl implements SuplidorRemoteDatasource {
  final SupabaseClient supabaseClient;

  SuplidorRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchSuplidores() async {
    final response = await supabaseClient
        .from('suplidores')
        .select()
        .filter('deleted_at', 'is', null)
        .order('nombre', ascending: true);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<void> upsertSuplidor(Map<String, dynamic> data) async {
    data.remove('id');
    data['updated_at'] = DateTime.now().toUtc().toIso8601String();
    await supabaseClient.from('suplidores').upsert(data);
  }

  @override
  Future<void> createSuplidor(Map<String, dynamic> data) async {
    data.remove('id');

    final now = DateTime.now().toUtc().toIso8601String();
    data['created_at'] = now;
    data['updated_at'] = now;

    await supabaseClient.from('suplidores').insert(data);
  }

  @override
  Future<void> updateSuplidor(String id, Map<String, dynamic> data) async {
    data.remove('id');
    data['updated_at'] = DateTime.now().toUtc().toIso8601String();

    await supabaseClient.from('suplidores').update(data).eq('id', id);
  }

  @override
  Future<void> softDeleteSuplidor(String id) async {
    await supabaseClient
        .from('suplidores')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }
}
