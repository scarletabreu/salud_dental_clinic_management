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
    final response = await supabaseClient
        .from('equipos_mantenimientos')
        .select(
          '*, equipo:equipos(*), consumible:consumibles(*), suplidor:suplidores(*)',
        )
        .eq('equipo_id', equipoId)
        .filter('deleted_at', 'is', null)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<void> insertMantenimiento(Map<String, dynamic> data) async {
    data.remove('id');
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    await supabaseClient.from('equipos_mantenimientos').insert(data);
  }

  @override
  Future<void> updateMantenimiento(String id, Map<String, dynamic> data) async {
    data.remove('id');

    data['updated_at'] = DateTime.now().toIso8601String();

    await supabaseClient
        .from('equipos_mantenimientos')
        .update(data)
        .eq('id', id);
  }

  @override
  Future<void> softDeleteMantenimiento(String id) async {
    await supabaseClient
        .from('equipos_mantenimientos')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }
}
