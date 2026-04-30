import 'package:salud_dental_clinic_management/features/personal/data/datasources/admin_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRemoteDatasourceImpl implements AdminRemoteDatasource {
  final SupabaseClient supabase;

  AdminRemoteDatasourceImpl(this.supabase);

  @override
  Future<void> createAdmin(String userId) async {
    try {
      await supabase.from('admins').insert({
        'user_id': userId,
        'estatus': 'activo',
        'created_at': DateTime.now().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      throw Exception('Error al registrar administrador: ${e.message}');
    }
  }

  @override
  Future<List<String>> fetchAdminUserIds() async {
    try {
      final response = await supabase
          .from('admins')
          .select('user_id')
          .eq('estatus', 'activo')
          .filter('deleted_at', 'is', null);

      return (response as List).map((e) => e['user_id'] as String).toList();
    } on PostgrestException catch (e) {
      throw Exception(
        'Error al recuperar lista de administradores: ${e.message}',
      );
    }
  }

  @override
  Future<bool> isAdmin(String userId) async {
    try {
      final response = await supabase
          .from('admins')
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
  Future<void> updateAdmin(String userId, String newUserId) async {
    try {
      await supabase
          .from('admins')
          .update({
            'user_id': newUserId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar administrador: ${e.message}');
    }
  }

  @override
  Future<void> deactivateAdmin(String userId) async {
    try {
      await supabase
          .from('admins')
          .update({
            'estatus': 'inactivo',
            'deleted_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw Exception('Error al desactivar administrador: ${e.message}');
    }
  }

  @override
  Future<void> reactivateAdmin(String userId) async {
    try {
      await supabase
          .from('admins')
          .update({
            'estatus': 'activo',
            'deleted_at': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw Exception('Error al reactivar administrador: ${e.message}');
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchAdminById(String userId) async {
    try {
      final response = await supabase
          .from('admins')
          .select('*')
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .maybeSingle();
      return response;
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener datos del administrador: ${e.message}');
    }
  }
}
