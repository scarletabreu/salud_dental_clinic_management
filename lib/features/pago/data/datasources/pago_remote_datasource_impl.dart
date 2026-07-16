import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/features/pago/data/datasources/pago_remote_datasource.dart';

class PagoRemoteDatasourceImpl implements PagoRemoteDatasource {
  final SupabaseClient supabaseClient;

  PagoRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<void> registrarPago(Map<String, dynamic> data) async {
    data.remove('id');
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    await supabaseClient.from('pagos').insert(data);
  }

  @override
  Future<void> actualizarPago(Map<String, dynamic> data) async {
    data.remove('id');
    data['updated_at'] = DateTime.now().toIso8601String();
    await supabaseClient.from('pagos').upsert(data);
  }

  @override
  Future<void> anularPago(String id) async {
    await supabaseClient
        .from('pagos')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
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
        .filter('deleted_at', 'is', null)
        .order('fecha', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<String> registrarPagoTransaccional({
    required String cuentaId,
    required double monto,
    required String metodoPago,
  }) async {
    final res = await supabaseClient.rpc(
      'registrar_pago',
      params: {
        'p_cuenta_id': cuentaId,
        'p_monto': monto,
        'p_metodo_pago': metodoPago,
      },
    );
    return res as String;
  }
}
