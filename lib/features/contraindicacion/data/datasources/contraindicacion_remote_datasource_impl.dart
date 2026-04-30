import 'package:salud_dental_clinic_management/features/contraindicacion/data/datasources/contraindicacion_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContraindicacionRemoteDatasourceImpl
    implements ContraindicacionRemoteDatasource {
  final SupabaseClient supabaseClient;

  ContraindicacionRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchContraindicacionesByCondicion(
    String condicionId,
  ) async {
    try {
      final response = await supabaseClient
          .from('medicinas')
          .select('*, contraindicaciones(*)')
          .filter('deleted_at', 'is', null);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> registrarContraindicacion(Map<String, dynamic> data) async {
    await supabaseClient.from('contraindicaciones').insert(data);
  }

  @override
  Future<void> deleteContraindicacion(String id) async {
    await supabaseClient
        .from('contraindicaciones')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
