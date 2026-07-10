import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/data/datasources/tratamiento_remote_datasource.dart';

class TratamientoRemoteDatasourceImpl implements TratamientoRemoteDatasource {
  final SupabaseClient supabaseClient;

  TratamientoRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchTratamientos() async {
    final response = await supabaseClient
        .from('tratamientos')
        .select('*, contraindicaciones(*)')
        .filter('deleted_at', 'is', null)
        .order('nombre', ascending: true);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<void> createTratamiento(Map<String, dynamic> data) async {
    data.remove('id');
    data.remove('contraindicaciones');

    if (data.containsKey('precio_base') && !data.containsKey('costo')) {
      data['costo'] = data.remove('precio_base');
    }

    final now = DateTime.now().toIso8601String();
    data['created_at'] = now;
    data['updated_at'] = now;

    await supabaseClient.from('tratamientos').insert(data);
  }

  @override
  Future<void> updateTratamiento(String id, Map<String, dynamic> data) async {
    data.remove('id');
    data.remove('contraindicaciones');

    if (data.containsKey('precio_base') && !data.containsKey('costo')) {
      data['costo'] = data.remove('precio_base');
    }

    data['updated_at'] = DateTime.now().toIso8601String();

    await supabaseClient.from('tratamientos').update(data).eq('id', id);
  }

  @override
  Future<void> upsertTratamiento(Map<String, dynamic> data) async {
    data.remove('id');
    data['updated_at'] = DateTime.now().toIso8601String();
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
