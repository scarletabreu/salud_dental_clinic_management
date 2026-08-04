import 'package:salud_dental_clinic_management/features/personal/data/datasources/doctor_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/personal/data/models/doctor_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef GetActiveDoctorsRpc = Future<dynamic> Function();

class DoctorRemoteDatasourceImpl implements DoctorRemoteDatasource {
  final SupabaseClient supabaseClient;
  final GetActiveDoctorsRpc _getActiveDoctorsRpc;

  DoctorRemoteDatasourceImpl({
    required this.supabaseClient,
    GetActiveDoctorsRpc? getActiveDoctorsRpc,
  }) : _getActiveDoctorsRpc =
           getActiveDoctorsRpc ??
           (() => supabaseClient.rpc('get_active_doctors'));

  /// Catálogo de doctores agendables, administradores incluidos: desde
  /// HFX-CLIN-000 un admin tiene fila en `doctores`, que es lo que lee la RPC.
  @override
  Future<List<DoctorModel>> fetchActiveDoctores() async {
    final response = await _getActiveDoctorsRpc();

    return (response as List)
        .map((json) => DoctorModel.fromJsonFn(json as Map<String, dynamic>))
        .toList();
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
