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
        .isFilter('deleted_at', null)
        .order('fecha_vencimiento', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> actualizarEstadoCuota(String cuotaId, String nuevoEstado) async {
    await supabaseClient
        .from('cuotas')
        .update({'estado': nuevoEstado})
        .eq('id', cuotaId);
  }

  @override
  Future<void> crearCuotas(List<Map<String, dynamic>> cuotasData) async {
    await supabaseClient.from('cuotas').insert(cuotasData);
  }

  @override
  Future<void> deleteCuota(String id) async {
    await supabaseClient
        .from('cuotas')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'estado': 'cancelada',
        })
        .eq('id', id);
  }
}
