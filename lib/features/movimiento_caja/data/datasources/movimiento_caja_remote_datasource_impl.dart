import 'package:salud_dental_clinic_management/features/movimiento_caja/data/datasources/movimiento_caja_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MovimientoCajaRemoteDatasourceImpl
    implements MovimientoCajaRemoteDatasource {
  final SupabaseClient supabaseClient;

  MovimientoCajaRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<void> registrarMovimiento(Map<String, dynamic> data) async {
    await supabaseClient.from('movimientos_caja').insert(data);
  }

  @override
  Future<void> actualizarMovimiento(Map<String, dynamic> data) async {
    await supabaseClient.from('movimientos_caja').upsert(data);
  }

  @override
  Future<void> eliminarMovimiento(String id) async {
    await supabaseClient
        .from('movimientos_caja')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMovimientosPorCaja(
    String cajaDiariaId,
  ) async {
    final response = await supabaseClient
        .from('movimientos_caja')
        .select()
        .eq('caja_diaria_id', cajaDiariaId)
        .isFilter(
          'deleted_at',
          null,
        ) // <--- CRÍTICO: No mostrar movimientos anulados
        .order('fecha', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}
