import 'package:salud_dental_clinic_management/features/procedimiento/data/datasources/procedimiento_remore_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProcedimientoRemoteDatasourceImpl
    implements ProcedimientoRemoteDatasource {
  final SupabaseClient supabaseClient;

  ProcedimientoRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchProcedimientos() async {
    final response = await supabaseClient
        .from('procedimientos')
        .select('*, contraindicaciones(*)')
        .filter('deleted_at', 'is', null)
        .order('nombre', ascending: true);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<Map<String, dynamic>> insertProcedimiento(
    Map<String, dynamic> data,
  ) async {
    data.remove('id');
    final now = DateTime.now().toIso8601String();
    data['created_at'] = now;
    data['updated_at'] = now;

    final response = await supabaseClient
        .from('procedimientos')
        .insert(data)
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  @override
  Future<void> upsertProcedimiento(Map<String, dynamic> data) async {
    if (data['id'] == null ||
        data['id'].toString().length != 36 ||
        !data['id'].toString().contains('-')) {
      data.remove('id');
    }
    data['updated_at'] = DateTime.now().toIso8601String();
    await supabaseClient.from('procedimientos').upsert(data);
  }

  @override
  Future<void> softDeleteProcedimiento(String id) async {
    await supabaseClient
        .from('procedimientos')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }
}
