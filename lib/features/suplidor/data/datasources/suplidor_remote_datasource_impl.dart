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
        .isFilter('deleted_at', null)
        .order('nombre', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> upsertSuplidor(Map<String, dynamic> data) async {
    await supabaseClient.from('suplidores').upsert(data);
  }

  @override
  Future<void> softDeleteSuplidor(String id) async {
    await supabaseClient
        .from('suplidores')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
