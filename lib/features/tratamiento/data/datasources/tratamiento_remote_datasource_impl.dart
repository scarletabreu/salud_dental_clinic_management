import 'package:salud_dental_clinic_management/features/tratamiento/data/datasources/tratamiento_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TratamientoRemoteDatasourceImpl implements TratamientoRemoteDatasource {
  final SupabaseClient supabaseClient;

  TratamientoRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchTratamientos() async {
    final response = await supabaseClient
        .from('tratamientos')
        .select('*, contraindicaciones(*)')
        .isFilter('deleted_at', null)
        .order('nombre', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> upsertTratamiento(Map<String, dynamic> data) async {
    await supabaseClient.from('tratamientos').upsert(data);
  }

  @override
  Future<void> deleteTratamiento(String id) async {
    await supabaseClient
        .from('tratamientos')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
