import 'package:salud_dental_clinic_management/features/condicion/data/datasources/condicion_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CondicionRemoteDatasourceImpl implements CondicionRemoteDatasource {
  final SupabaseClient supabaseClient;

  CondicionRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchCondiciones() async {
    final response = await supabaseClient
        .from('condiciones')
        .select()
        .isFilter('deleted_at', null)
        .order('nombre', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCondicionesByTipo(String tipo) async {
    final response = await supabaseClient
        .from('condiciones')
        .select()
        .eq('tipo', tipo)
        .isFilter('deleted_at', null)
        .order('nombre', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<Map<String, dynamic>> createCondicion(
    Map<String, dynamic> condicionData,
  ) async {
    condicionData.remove('id');
    condicionData['created_at'] = DateTime.now().toIso8601String();
    condicionData['updated_at'] = DateTime.now().toIso8601String();
    final inserted = await supabaseClient
        .from('condiciones')
        .insert(condicionData)
        .select()
        .single();
    return Map<String, dynamic>.from(inserted);
  }

  @override
  Future<void> deleteCondicion(String id) async {
    await supabaseClient
        .from('condiciones')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }
}
