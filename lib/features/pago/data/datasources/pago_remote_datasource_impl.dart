import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/features/pago/data/datasources/pago_remote_datasource.dart';

class PagoRemoteDatasourceImpl implements PagoRemoteDatasource {
  final SupabaseClient supabaseClient;

  PagoRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<void> registrarPago(Map<String, dynamic> data) async {
    await supabaseClient.from('pagos').insert(data);
  }

  @override
  Future<void> actualizarPago(Map<String, dynamic> data) async {
    await supabaseClient.from('pagos').upsert(data);
  }

  @override
  Future<void> anularPago(String id) async {
    await supabaseClient
        .from('pagos')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPagosPorCuenta(
    String cuentaId,
  ) async {
    final response = await supabaseClient
        .from('pagos')
        .select()
        .eq('cuenta_id', cuentaId)
        .isFilter('deleted_at', null)
        .order('fecha', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}
