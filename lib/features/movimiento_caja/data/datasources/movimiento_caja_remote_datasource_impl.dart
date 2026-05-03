import 'package:salud_dental_clinic_management/features/movimiento_caja/data/datasources/movimiento_caja_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MovimientoCajaRemoteDatasourceImpl
    implements MovimientoCajaRemoteDatasource {
  final SupabaseClient supabaseClient;

  MovimientoCajaRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<void> registrarMovimiento(Map<String, dynamic> data) async {
    try {
      data.remove('id');
      data['created_at'] = DateTime.now().toIso8601String();
      await supabaseClient.from('movimientos_caja').insert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al registrar el movimiento de caja: ${e.message}');
    }
  }

  @override
  Future<void> actualizarMovimiento(Map<String, dynamic> data) async {
    try {
      data.remove('id');
      data['updated_at'] = DateTime.now().toIso8601String();
      await supabaseClient.from('movimientos_caja').upsert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar el movimiento: ${e.message}');
    }
  }

  @override
  Future<void> eliminarMovimiento(String id) async {
    try {
      await supabaseClient
          .from('movimientos_caja')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al anular movimiento de caja: ${e.message}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMovimientosPorCaja(
    String cajaDiariaId,
  ) async {
    try {
      final response = await supabaseClient
          .from('movimientos_caja')
          .select()
          .eq('caja_diaria_id', cajaDiariaId)
          .filter('deleted_at', 'is', null)
          .order('fecha', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener movimientos de la caja: ${e.message}');
    }
  }
}
