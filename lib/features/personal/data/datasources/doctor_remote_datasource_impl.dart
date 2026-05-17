import 'package:salud_dental_clinic_management/features/personal/data/datasources/doctor_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorRemoteDatasourceImpl implements DoctorRemoteDatasource {
  final SupabaseClient supabaseClient;

  DoctorRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<void> createDoctor(String userId) async {
    try {
      await supabaseClient.from('doctors').insert({
        'user_id': userId,
        'estatus': 'activo',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      throw Exception('Error al registrar doctor: ${e.message}');
    }
  }

  @override
  Future<List<String>> fetchDoctorUserIds() async {
    try {
      final response = await supabaseClient
          .from('doctors')
          .select('user_id')
          .eq('estatus', 'activo')
          .filter('deleted_at', 'is', null);

      return List<String>.from(
        (response as List).map((item) => item['user_id']),
      );
    } on PostgrestException catch (e) {
      throw Exception('Error al recuperar lista de doctores: ${e.message}');
    }
  }

  @override
  Future<bool> isDoctor(String userId) async {
    try {
      final response = await supabaseClient
          .from('doctors')
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
  Future<void> updateDoctor(String userId, String newUserId) async {
    try {
      await supabaseClient
          .from('doctors')
          .update({
            'user_id': newUserId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar doctor: ${e.message}');
    }
  }

  @override
  Future<void> deactivateDoctor(String userId) async {
    try {
      await supabaseClient
          .from('doctors')
          .update({
            'estatus': 'inactivo',
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw Exception('Error al desactivar doctor: ${e.message}');
    }
  }

  @override
  Future<void> reactivateDoctor(String userId) async {
    try {
      await supabaseClient
          .from('doctors')
          .update({
            'estatus': 'activo',
            'deleted_at': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw Exception('Error al reactivar doctor: ${e.message}');
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchDoctorById(String userId) async {
    try {
      final response = await supabaseClient
          .from('doctors')
          .select('*')
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .maybeSingle();
      return response;
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener datos del doctor: ${e.message}');
    }
  }
}
