import 'package:salud_dental_clinic_management/features/personal/data/datasources/asistente_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AsistenteRemoteDatasourceImpl implements AsistenteRemoteDatasource {
  final SupabaseClient supabase;

  AsistenteRemoteDatasourceImpl(this.supabase);

  @override
  Future<void> createAsistente(String userId) async {
    await supabase.from('asistentes').insert({
      'user_id': userId,
      'estatus': 'activo',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<String>> fetchAsistenteUserIds() async {
    final response = await supabase
        .from('asistentes')
        .select('user_id')
        .eq('estatus', 'activo');
    return (response as List).map((e) => e['user_id'] as String).toList();
  }

  @override
  Future<bool> isAsistente(String userId) async {
    final response = await supabase
        .from('asistentes')
        .select('user_id')
        .eq('user_id', userId)
        .eq('estatus', 'activo')
        .maybeSingle();
    return response != null;
  }

  @override
  Future<void> updateAsistente(String userId, String newUserId) async {
    await supabase
        .from('asistentes')
        .update({
          'user_id': newUserId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId);
  }

  @override
  Future<void> deactivateAsistente(String userId) async {
    await supabase
        .from('asistentes')
        .update({
          'estatus': 'inactivo',
          'deleted_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId);
  }

  @override
  Future<void> reactivateAsistente(String userId) async {
    await supabase
        .from('asistentes')
        .update({
          'estatus': 'activo',
          'deleted_at': null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId);
  }

  @override
  Future<Map<String, dynamic>?> fetchAsistenteById(String userId) async {
    final response = await supabase
        .from('asistentes')
        .select('*')
        .eq('user_id', userId)
        .maybeSingle();
    return response;
  }
}
