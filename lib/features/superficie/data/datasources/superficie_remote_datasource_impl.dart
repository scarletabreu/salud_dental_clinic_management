import 'package:salud_dental_clinic_management/features/superficie/data/datasources/superficie_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SuperficieRemoteDatasourceImpl implements SuperficieRemoteDatasource {
  final SupabaseClient supabaseClient;

  SuperficieRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<void> actualizarSuperficie(Map<String, dynamic> data) async {
    try {
      await supabaseClient.from('superficies').upsert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al guardar/actualizar superficie: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al persistir superficie: $e');
    }
  }

  @override
  Future<void> eliminarSuperficie(String id) async {
    try {
      await supabaseClient
          .from('superficies')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar superficie: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al eliminar superficie: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSuperficiesPorDiente(
    String dienteId,
  ) async {
    try {
      final response = await supabaseClient
          .from('superficies')
          .select()
          .eq('diente_id', dienteId)
          .filter('deleted_at', 'is', null);

      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception(
        'Error al recuperar superficies del diente: ${e.message}',
      );
    } catch (e) {
      throw Exception('Error inesperado al cargar superficies: $e');
    }
  }
}
