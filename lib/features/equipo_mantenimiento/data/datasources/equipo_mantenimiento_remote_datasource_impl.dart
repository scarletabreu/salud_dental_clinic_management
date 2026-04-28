import 'package:supabase_flutter/supabase_flutter.dart';
import 'equipo_mantenimiento_remote_datasource.dart';

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
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> insertMantenimiento(Map<String, dynamic> data) async {
    await supabaseClient.from('equipos_mantenimientos').insert(data);
  }

  @override
  Future<void> softDeleteMantenimiento(String id) async {
    await supabaseClient
        .from('equipos_mantenimientos')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
