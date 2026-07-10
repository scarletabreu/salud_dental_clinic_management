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
    final response = await supabaseClient
        .from('contraindicaciones')
        .select('*')
        .eq('condicion_id', condicionId)
        .filter('deleted_at', 'is', null);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchContraindicacionesByTratamiento(
    String tratamientoId,
  ) async {
    final response = await supabaseClient
        .from('contraindicaciones')
        .select('*')
        .eq('tratamiento_id', tratamientoId)
        .filter('deleted_at', 'is', null);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchContraindicacionesByProcedimiento(
    String procedimientoId,
  ) async {
    final response = await supabaseClient
        .from('contraindicaciones')
        .select('*')
        .eq('procedimiento_id', procedimientoId)
        .filter('deleted_at', 'is', null);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchContraindicacionesByMedicina(
    String medicinaId,
  ) async {
    final response = await supabaseClient
        .from('contraindicaciones')
        .select('*')
        .eq('medicina_id', medicinaId)
        .filter('deleted_at', 'is', null);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<void> registrarContraindicacion(Map<String, dynamic> data) async {
    data.remove('id');
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    await supabaseClient.from('contraindicaciones').insert(data);
  }

  @override
  Future<void> deleteContraindicacion(String id) async {
    await supabaseClient
        .from('contraindicaciones')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }
}
