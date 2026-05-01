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
          .from('contraindicaciones')
          .select('*')
          .eq('condicion_id', condicionId)
          .filter('deleted_at', 'is', null);

      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener contraindicaciones: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<void> registrarContraindicacion(Map<String, dynamic> data) async {
    try {
      await supabaseClient.from('contraindicaciones').insert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al registrar contraindicación: ${e.message}');
    }
  }

  @override
  Future<void> deleteContraindicacion(String id) async {
    try {
      await supabaseClient
          .from('contraindicaciones')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar contraindicación: ${e.message}');
    }
  }
}
