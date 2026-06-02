import 'package:salud_dental_clinic_management/features/personal/data/datasources/asistente_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AsistenteRemoteDatasourceImpl implements AsistenteRemoteDatasource {
  final SupabaseClient supabase;

  AsistenteRemoteDatasourceImpl(this.supabase);

  @override
  Future<void> createAsistente(String userId) async {
    try {
      await supabase.from('asistentes').insert({
        'user_id': userId,
        'estatus': 'activo',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      throw Exception('Error al registrar asistente: ${e.message}');
    }
  }

  @override
  Future<List<String>> fetchAsistenteUserIds() async {
    try {
      final response = await supabase
          .from('asistentes')
          .select('user_id')
          .eq('estatus', 'activo')
          .filter('deleted_at', 'is', null);
      return (response as List).map((e) => e['user_id'] as String).toList();
    } on PostgrestException catch (e) {
      throw Exception('Error al recuperar lista de asistentes: ${e.message}');
    }
  }

  @override
  Future<bool> isAsistente(String userId) async {
    try {
      final response = await supabase
          .from('asistentes')
          .select('user_id')
          .eq('user_id', userId)
          .eq('estatus', 'activo')
          .filter('deleted_at', 'is', null)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> updateAsistente(String userId, String newUserId) async {
    try {
      await supabase
          .from('asistentes')
          .update({
            'user_id': newUserId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar asistente: ${e.message}');
    }
  }

  @override
  Future<void> deactivateAsistente(String userId) async {
    try {
      await supabase
          .from('asistentes')
          .update({
            'estatus': 'inactivo',
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw Exception('Error al desactivar asistente: ${e.message}');
    }
  }

  @override
  Future<void> reactivateAsistente(String userId) async {
    try {
      await supabase
          .from('asistentes')
          .update({
            'estatus': 'activo',
            'deleted_at': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw Exception('Error al reactivar asistente: ${e.message}');
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchAsistenteById(String userId) async {
    try {
      final response = await supabase
          .from('asistentes')
          .select('*')
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .maybeSingle();
      return response;
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener datos del asistente: ${e.message}');
    }
  }
}
