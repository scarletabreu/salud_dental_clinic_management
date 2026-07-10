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
        .filter('deleted_at', 'is', null)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<void> registrarCuenta(Map<String, dynamic> data) async {
    data.remove('id');
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    await supabaseClient.from('cuentas').insert(data);
  }

  @override
  Future<void> registrarPago(
    String cuentaId,
    Map<String, dynamic> pagoData,
  ) async {
    pagoData['cuenta_id'] = cuentaId;
    pagoData.remove('id');
    pagoData['created_at'] = DateTime.now().toIso8601String();
    pagoData['updated_at'] = DateTime.now().toIso8601String();
    await supabaseClient.from('pagos').insert(pagoData);
  }

  @override
  Future<void> deleteCuenta(String id) async {
    await supabaseClient
        .from('cuentas')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }
}
