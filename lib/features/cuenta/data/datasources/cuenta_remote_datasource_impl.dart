import 'package:salud_dental_clinic_management/features/cuenta/data/datasources/cuenta_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CuentaRemoteDatasourceImpl implements CuentaRemoteDatasource {
  final SupabaseClient supabaseClient;

  CuentaRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchCuentasByPaciente(
    String pacienteId,
  ) async {
    final response = await supabaseClient
        .from('cuentas')
        .select('*, pagos(*), item_cuentas(*)')
        .eq('paciente_id', pacienteId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> registrarCuenta(Map<String, dynamic> data) async {
    await supabaseClient.from('cuentas').insert(data);
  }

  @override
  Future<void> registrarPago(
    String cuentaId,
    Map<String, dynamic> pagoData,
  ) async {
    await supabaseClient.from('pagos').insert(pagoData);
  }

  @override
  Future<void> deleteCuenta(String id) async {
    await supabaseClient
        .from('cuentas')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
