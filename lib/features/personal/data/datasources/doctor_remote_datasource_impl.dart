import 'package:salud_dental_clinic_management/features/personal/data/datasources/doctor_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/personal/data/models/doctor_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorRemoteDatasourceImpl implements DoctorRemoteDatasource {
  final SupabaseClient supabaseClient;

  DoctorRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<void> createDoctor(String userId) async {
    await supabaseClient.from('doctores').insert({
      'id': userId,
      'estatus': 'activo',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<String>> fetchDoctorUserIds() async {
    final response = await supabaseClient
        .from('doctores')
        .select('id')
        .eq('estatus', 'activo')
        .filter('deleted_at', 'is', null);

    return List<String>.from(
      (response as List).map((item) => item['user_id']),
    );
  }

  @override
  Future<List<DoctorModel>> fetchActiveDoctores() async {
    final response = await supabaseClient.rpc('get_active_doctors');

    print('RAW SUPABASE RESPONSE: $response');

    return (response as List)
        .map((json) => DoctorModel.fromJsonFn(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<bool> isDoctor(String userId) async {
    try {
      final response = await supabaseClient
          .from('doctores')
          .select('id')
          .eq('id', userId)
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
    await supabaseClient
        .from('doctores')
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
          'updated_at': DateTime.now().toIso8601String(),
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
    return await supabaseClient
        .from('doctores')
        .select('*')
        .eq('id', userId)
        .filter('deleted_at', 'is', null)
        .maybeSingle();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchDoctorAsistentesByAsistenteId(
    String asistenteId,
  ) async {
    final response = await supabaseClient
        .from('doctor_asistentes')
        .select('doctor_id')
        .eq('asistente_id', asistenteId);

    return List<Map<String, dynamic>>.from(response as List);
  }
}
