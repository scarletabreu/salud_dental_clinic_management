import 'package:salud_dental_clinic_management/features/personal/data/datasources/doctor_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorRemoteDatasourceImpl implements DoctorRemoteDatasource {
  final SupabaseClient supabaseClient;

  DoctorRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<void> createDoctor(String userId) async {
    await supabaseClient.from('doctors').insert({
      'user_id': userId,
      'estatus': 'activo',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<String>> fetchDoctorUserIds() async {
    final response = await supabaseClient
        .from('doctors')
        .select('user_id')
        .eq('estatus', 'activo');
    return List<String>.from(response.map((item) => item['user_id']));
  }

  @override
  Future<bool> isDoctor(String userId) async {
    final response = await supabaseClient
        .from('doctors')
        .select('user_id')
        .eq('user_id', userId)
        .eq('estatus', 'activo')
        .maybeSingle();
    return response != null;
  }

  @override
  Future<void> updateDoctor(String userId, String newUserId) async {
    await supabaseClient
        .from('doctors')
        .update({
          'user_id': newUserId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId);
  }

  @override
  Future<void> deactivateDoctor(String userId) async {
    await supabaseClient
        .from('doctors')
        .update({
          'estatus': 'inactivo',
          'deleted_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId);
  }

  @override
  Future<void> reactivateDoctor(String userId) async {
    await supabaseClient
        .from('doctors')
        .update({
          'estatus': 'activo',
          'deleted_at': null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId);
  }

  @override
  Future<Map<String, dynamic>?> fetchDoctorById(String userId) async {
    final response = await supabaseClient
        .from('doctors')
        .select('*')
        .eq('user_id', userId)
        .maybeSingle();
    return response;
  }
}
