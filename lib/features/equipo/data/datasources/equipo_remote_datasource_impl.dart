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
  Future<void> createEquipo(Map<String, dynamic> data) async {
    try {
      data.remove('id');

      final now = DateTime.now().toIso8601String();
      data['created_at'] = now;
      data['updated_at'] = now;

      await supabaseClient.from('equipos').insert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al registrar nuevo equipo: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al registrar equipo: $e');
    }
  }

  @override
  Future<void> upsertEquipo(Map<String, dynamic> data) async {
    try {
      if (!(_isValidUuid(data['id']))) {
        data.remove('id');
        data['created_at'] = DateTime.now().toIso8601String();
      }

      data['updated_at'] = DateTime.now().toIso8601String();

      await supabaseClient.from('equipos').upsert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al guardar/actualizar equipo: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al persistir equipo: $e');
    }
  }

  bool _isValidUuid(dynamic id) {
    return id != null && id is String && id.length == 36 && id.contains('-');
  }

  @override
  Future<void> softDeleteEquipo(String id) async {
    try {
      await supabaseClient
          .from('equipos')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar equipo: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al eliminar equipo: $e');
    }
  }
}
