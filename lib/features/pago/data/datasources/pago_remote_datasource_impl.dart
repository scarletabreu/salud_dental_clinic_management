import 'package:supabase_flutter/supabase_flutter.dart';

abstract class PagoRemoteDatasource {
  Future<void> registrarPago(Map<String, dynamic> data);
  Future<void> actualizarPago(Map<String, dynamic> data);
  Future<void> anularPago(String id);
  Future<List<Map<String, dynamic>>> fetchPagosPorCuenta(String cuentaId);
}

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
