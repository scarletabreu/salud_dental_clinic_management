import 'package:salud_dental_clinic_management/features/tratamiento/data/datasources/tratamiento_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TratamientoRemoteDatasourceImpl implements TratamientoRemoteDatasource {
  final SupabaseClient supabaseClient;

  TratamientoRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchTratamientos() async {
    try {
      final response = await supabaseClient
          .from('tratamientos')
          .select('*, contraindicaciones(*)')
          .filter('deleted_at', 'is', null)
          .order('nombre', ascending: true);

      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception(
        'Error al recuperar catálogo de tratamientos: ${e.message}',
      );
    } catch (e) {
      throw Exception('Error inesperado al cargar tratamientos: $e');
    }
  }

  @override
  Future<void> upsertTratamiento(Map<String, dynamic> data) async {
    try {
      await supabaseClient.from('tratamientos').upsert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al guardar/actualizar tratamiento: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al persistir tratamiento: $e');
    }
  }

  @override
  Future<void> deleteTratamiento(String id) async {
    try {
      await supabaseClient
          .from('tratamientos')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar tratamiento: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al eliminar tratamientos: $e');
    }
  }
}
