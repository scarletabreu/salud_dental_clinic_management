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
  Future<void> createCondicion(Map<String, dynamic> condicionData) async {
    await supabaseClient.from('condiciones').insert(condicionData);
  }

  @override
  Future<void> deleteCondicion(String id) async {
    await supabaseClient
        .from('condiciones')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
