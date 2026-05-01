import 'package:salud_dental_clinic_management/features/suplidor/data/datasources/suplidor_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SuplidorRemoteDatasourceImpl implements SuplidorRemoteDatasource {
  final SupabaseClient supabaseClient;

  SuplidorRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchSuplidores() async {
    try {
      final response = await supabaseClient
          .from('suplidores')
          .select()
          .filter('deleted_at', 'is', null)
          .order('nombre', ascending: true);

      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception(
        'Error al recuperar catálogo de suplidores: ${e.message}',
      );
    } catch (e) {
      throw Exception('Error inesperado al cargar suplidores: $e');
    }
  }

  @override
  Future<void> upsertSuplidor(Map<String, dynamic> data) async {
    try {
      await supabaseClient.from('suplidores').upsert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al guardar/actualizar suplidor: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al persistir suplidor: $e');
    }
  }

  @override
  Future<void> softDeleteSuplidor(String id) async {
    try {
      await supabaseClient
          .from('suplidores')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar suplidor: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al eliminar suplidor: $e');
    }
  }
}
