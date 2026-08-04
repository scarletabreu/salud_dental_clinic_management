import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/features/pago/data/datasources/pago_remote_datasource.dart';

class PagoRemoteDatasourceImpl implements PagoRemoteDatasource {
  final SupabaseClient supabaseClient;

  PagoRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<void> anularPago(String id, {String? motivo}) async {
    await supabaseClient.rpc(
      'anular_pago',
      params: {'p_pago_id': id, 'p_motivo': motivo},
    );
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
    String? cuotaId,
  }) async {
    final res = await supabaseClient.rpc(
      'registrar_pago',
      params: {
        'p_cuenta_id': cuentaId,
        'p_monto': monto,
        'p_metodo_pago': metodoPago,
        'p_cuota_id': cuotaId,
      },
    );
    return res as String;
  }
}
