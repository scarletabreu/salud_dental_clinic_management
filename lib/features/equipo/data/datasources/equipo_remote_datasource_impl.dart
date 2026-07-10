import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/features/equipo/data/datasources/equipo_remote_datasource.dart';

class EquipoRemoteDatasourceImpl implements EquipoRemoteDatasource {
  final SupabaseClient supabaseClient;

  EquipoRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchEquipos() async {
    final response = await supabaseClient
        .from('equipos')
        .select()
        .filter('deleted_at', 'is', null)
        .order('nombre', ascending: true);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<void> createEquipo(Map<String, dynamic> data) async {
    data.remove('id');

    final now = DateTime.now().toIso8601String();
    data['created_at'] = now;
    data['updated_at'] = now;

    await supabaseClient.from('equipos').insert(data);
  }

  @override
  Future<void> upsertEquipo(Map<String, dynamic> data) async {
    if (!(_isValidUuid(data['id']))) {
      data.remove('id');
      data['created_at'] = DateTime.now().toIso8601String();
    }

    data['updated_at'] = DateTime.now().toIso8601String();

    await supabaseClient.from('equipos').upsert(data);
  }

  bool _isValidUuid(dynamic id) {
    return id != null && id is String && id.length == 36 && id.contains('-');
  }

  @override
  Future<void> softDeleteEquipo(String id) async {
    await supabaseClient
        .from('equipos')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }
}
