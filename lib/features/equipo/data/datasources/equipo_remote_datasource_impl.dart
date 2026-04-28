import 'package:supabase_flutter/supabase_flutter.dart';
import 'equipo_remote_datasource.dart';

class EquipoRemoteDatasourceImpl implements EquipoRemoteDatasource {
  final SupabaseClient supabaseClient;

  EquipoRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchEquipos() async {
    final response = await supabaseClient
        .from('equipos')
        .select()
        .isFilter('deleted_at', null)
        .order('nombre', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> upsertEquipo(Map<String, dynamic> data) async {
    await supabaseClient.from('equipos').upsert(data);
  }

  @override
  Future<void> softDeleteEquipo(String id) async {
    await supabaseClient
        .from('equipos')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
