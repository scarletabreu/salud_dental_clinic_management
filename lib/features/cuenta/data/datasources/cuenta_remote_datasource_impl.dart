import 'package:salud_dental_clinic_management/features/cuenta/data/datasources/cuenta_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CuentaRemoteDatasourceImpl implements CuentaRemoteDatasource {
  final SupabaseClient supabaseClient;

  CuentaRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchCuentasByPaciente(
    String pacienteId,
  ) async {
    try {
      final response = await supabaseClient
          .from('cuentas')
          .select('*, pagos(*), item_cuentas(*)')
          .eq('paciente_id', pacienteId)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener historial financiero: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cargar historial financiero: $e');
    }
  }

  @override
  Future<void> registrarCuenta(Map<String, dynamic> data) async {
    try {
      data.remove('id');
      data['created_at'] = DateTime.now().toIso8601String();
      data['updated_at'] = DateTime.now().toIso8601String();
      await supabaseClient.from('cuentas').insert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al registrar nueva cuenta: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al crear cuenta: $e');
    }
  }

  @override
  Future<void> registrarPago(
    String cuentaId,
    Map<String, dynamic> pagoData,
  ) async {
    try {
      pagoData['cuenta_id'] = cuentaId;
      pagoData.remove('id');
      pagoData['created_at'] = DateTime.now().toIso8601String();
      pagoData['updated_at'] = DateTime.now().toIso8601String();
      await supabaseClient.from('pagos').insert(pagoData);
    } on PostgrestException catch (e) {
      throw Exception('Error al registrar pago: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al registrar pago: $e');
    }
  }

  @override
  Future<void> deleteCuenta(String id) async {
    try {
      await supabaseClient
          .from('cuentas')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar cuenta: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al eliminar cuenta: $e');
    }
  }
}
