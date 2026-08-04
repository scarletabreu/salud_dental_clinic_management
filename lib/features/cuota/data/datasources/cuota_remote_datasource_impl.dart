import 'package:salud_dental_clinic_management/features/cuota/data/datasources/cuota_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CuotaRemoteDatasourceImpl implements CuotaRemoteDatasource {
  final SupabaseClient supabaseClient;

  CuotaRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchCuotasByCuenta(
    String cuentaId,
  ) async {
    final response = await supabaseClient
        .from('cuotas')
        .select()
        .eq('cuenta_id', cuentaId)
        .filter('deleted_at', 'is', null)
        .order('fecha_vencimiento', ascending: true);
    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<void> marcarCuotasVencidas(String cuentaId) async {
    await supabaseClient.rpc(
      'marcar_cuotas_vencidas',
      params: {'p_cuenta_id': cuentaId},
    );
  }

  @override
  Future<void> crearCuotas(List<Map<String, dynamic>> cuotasData) async {
    final cleanData = cuotasData.map((data) {
      final Map<String, dynamic> item = Map.from(data);
      item.remove('id');
      return item;
    }).toList();
    await supabaseClient.rpc(
      'generar_plan_cuotas',
      params: {
        'p_cuenta_id': cleanData.first['cuenta_id'],
        'p_cuotas': cleanData,
      },
    );
  }
}
