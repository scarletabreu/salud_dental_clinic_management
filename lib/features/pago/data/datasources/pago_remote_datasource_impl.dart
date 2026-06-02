import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/features/pago/data/datasources/pago_remote_datasource.dart';

class PagoRemoteDatasourceImpl implements PagoRemoteDatasource {
  final SupabaseClient supabaseClient;

  PagoRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<void> registrarPago(Map<String, dynamic> data) async {
    try {
      data.remove('id');
      data['created_at'] = DateTime.now().toIso8601String();
      data['updated_at'] = DateTime.now().toIso8601String();
      await supabaseClient.from('pagos').insert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al registrar pago: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al registrar pago: $e');
    }
  }

  @override
  Future<void> actualizarPago(Map<String, dynamic> data) async {
    try {
      data.remove('id');
      data['updated_at'] = DateTime.now().toIso8601String();
      await supabaseClient.from('pagos').upsert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar pago: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al actualizar pago: $e');
    }
  }

  @override
  Future<void> anularPago(String id) async {
    try {
      await supabaseClient
          .from('pagos')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al anular el pago: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al anular pago: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPagosPorCuenta(
    String cuentaId,
  ) async {
    try {
      final response = await supabaseClient
          .from('pagos')
          .select()
          .eq('cuenta_id', cuentaId)
          .filter('deleted_at', 'is', null)
          .order('fecha', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener lista de pagos: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cargar pagos: $e');
    }
  }
}
