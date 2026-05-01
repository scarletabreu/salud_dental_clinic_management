import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/features/equipo/data/datasources/equipo_remote_datasource.dart';

class EquipoRemoteDatasourceImpl implements EquipoRemoteDatasource {
  final SupabaseClient supabaseClient;

  EquipoRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchEquipos() async {
    try {
      final response = await supabaseClient
          .from('equipos')
          .select()
          .filter('deleted_at', 'is', null)
          .order('nombre', ascending: true);

      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception('Error al recuperar catálogo de equipos: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cargar equipos: $e');
    }
  }

  @override
  Future<void> upsertEquipo(Map<String, dynamic> data) async {
    try {
      await supabaseClient.from('equipos').upsert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al guardar/actualizar equipo: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al persistir equipo: $e');
    }
  }

  @override
  Future<void> softDeleteEquipo(String id) async {
    try {
      await supabaseClient
          .from('equipos')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar equipo: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al eliminar equipo: $e');
    }
  }
}
