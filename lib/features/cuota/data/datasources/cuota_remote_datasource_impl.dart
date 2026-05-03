import 'package:salud_dental_clinic_management/features/cuota/data/datasources/cuota_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CuotaRemoteDatasourceImpl implements CuotaRemoteDatasource {
  final SupabaseClient supabaseClient;

  CuotaRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchCuotasByCuenta(
    String cuentaId,
  ) async {
    try {
      final response = await supabaseClient
          .from('cuotas')
          .select()
          .eq('cuenta_id', cuentaId)
          .filter('deleted_at', 'is', null)
          .order('fecha_vencimiento', ascending: true);
      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener cuotas de la cuenta: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cargar cuotas: $e');
    }
  }

  @override
  Future<void> actualizarEstadoCuota(String cuotaId, String nuevoEstado) async {
    try {
      await supabaseClient
          .from('cuotas')
          .update({
            'estado': nuevoEstado,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', cuotaId);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar estado de la cuota: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al actualizar estado: $e');
    }
  }

  @override
  Future<void> crearCuotas(List<Map<String, dynamic>> cuotasData) async {
    try {
      final String now = DateTime.now().toIso8601String();

      final List<Map<String, dynamic>> cleanData = cuotasData.map((data) {
        final Map<String, dynamic> item = Map.from(data);
        item.remove('id');
        item['created_at'] = now;
        item['updated_at'] = now;
        return item;
      }).toList();

      await supabaseClient.from('cuotas').insert(cleanData);
    } on PostgrestException catch (e) {
      throw Exception('Error al registrar nuevas cuotas: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al registrar cuotas: $e');
    }
  }

  @override
  Future<void> deleteCuota(String id) async {
    try {
      await supabaseClient
          .from('cuotas')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'estado': 'cancelada',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al cancelar la cuota: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cancelar cuota: $e');
    }
  }
}
