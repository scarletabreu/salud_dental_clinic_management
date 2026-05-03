import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/features/equipo_mantenimiento/data/datasources/equipo_mantenimiento_remote_datasource.dart';

class EquipoMantenimientoRemoteDatasourceImpl
    implements EquipoMantenimientoRemoteDatasource {
  final SupabaseClient supabaseClient;

  EquipoMantenimientoRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchMantenimientosByEquipo(
    String equipoId,
  ) async {
    try {
      final response = await supabaseClient
          .from('equipos_mantenimientos')
          .select(
            '*, equipo:equipos(*), consumible:consumibles(*), suplidor:suplidores(*)',
          )
          .eq('equipo_id', equipoId)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception(
        'Error al recuperar historial de mantenimientos: ${e.message}',
      );
    } catch (e) {
      throw Exception('Error inesperado al cargar mantenimientos: $e');
    }
  }

  @override
  Future<void> insertMantenimiento(Map<String, dynamic> data) async {
    try {
      data.remove('id');
      data['created_at'] = DateTime.now().toIso8601String();
      data['updated_at'] = DateTime.now().toIso8601String();
      await supabaseClient.from('equipos_mantenimientos').insert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al registrar nuevo mantenimiento: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al crear mantenimiento: $e');
    }
  }

  @override
  Future<void> updateMantenimiento(String id, Map<String, dynamic> data) async {
    try {
      data.remove('id');

      data['updated_at'] = DateTime.now().toIso8601String();

      await supabaseClient
          .from('equipos_mantenimientos')
          .update(data)
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar mantenimiento: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al actualizar mantenimiento: $e');
    }
  }

  @override
  Future<void> softDeleteMantenimiento(String id) async {
    try {
      await supabaseClient
          .from('equipos_mantenimientos')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al anular mantenimiento: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al anular mantenimiento: $e');
    }
  }
}
