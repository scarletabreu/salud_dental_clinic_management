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
  Future<void> actualizarEstadoCuota(String cuotaId, String nuevoEstado) async {
    await supabaseClient
        .from('cuotas')
        .update({
          'estado': nuevoEstado,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', cuotaId);
  }

  @override
  Future<void> crearCuotas(List<Map<String, dynamic>> cuotasData) async {
    final String now = DateTime.now().toIso8601String();

    final List<Map<String, dynamic>> cleanData = cuotasData.map((data) {
      final Map<String, dynamic> item = Map.from(data);
      item.remove('id');
      item['created_at'] = now;
      item['updated_at'] = now;
      return item;
    }).toList();

    await supabaseClient.from('cuotas').insert(cleanData);
  }

  @override
  Future<void> deleteCuota(String id) async {
    await supabaseClient
        .from('cuotas')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'estado': 'cancelada',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }
}
