import 'package:salud_dental_clinic_management/features/cuenta/data/datasources/cuenta_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CuentaRemoteDatasourceImpl implements CuentaRemoteDatasource {
  final SupabaseClient supabaseClient;

  CuentaRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchTodasLasCuentas() async {
    final response = await supabaseClient
        .from('cuentas')
        .select('*, pagos(*), items_cuenta(*)')
        .filter('deleted_at', 'is', null)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCuentasByPaciente(
    String pacienteId,
  ) async {
    try {
      final response = await supabaseClient
          .from('cuentas')
          .select('*, pagos(*), items_cuenta(*)')
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
  Future<Map<String, dynamic>?> fetchCuentaById(String id) async {
  try {
    final response = await supabaseClient
        .from('cuentas')
        .select('*, pagos(*), items_cuenta(*)')
        .eq('id', id)
        .filter('deleted_at', 'is', null)
        .maybeSingle();
    return response;
  } on PostgrestException catch (e) {
    throw Exception('Error al obtener cuenta por consulta: ${e.message}');
  }
}

  @override
  Future<Map<String, dynamic>?> fetchCuentaByConsultaId(String consultaId) async {
  try {
    final response = await supabaseClient
        .from('cuentas')
        .select('*, pagos(*), items_cuenta(*)')
        .eq('consulta_id', consultaId)
        .filter('deleted_at', 'is', null)
        .maybeSingle();
    return response;
  } on PostgrestException catch (e) {
    throw Exception('Error al obtener cuenta por consulta: ${e.message}');
  }
}

  /// Lo único editable de una pre-factura desde el cliente. La pantalla ya
  /// ofrecía elegir entre contado y crédito, pero la elección se quedaba en el
  /// estado del widget: `cuentas.metodo_pago` seguía siendo `contado` para
  /// siempre, incluso con un plan de cuotas configurado.
  @override
  Future<void> fijarModoPago(String id, MetodoPago modo) async {
    try {
      await supabaseClient
          .from('cuentas')
          .update({
            'metodo_pago': modo.dbValue,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar el modo de pago: ${e.message}');
    }
  }

  @override
  Future<void> deleteCuenta(String id) async {
    final ahora = DateTime.now().toUtc().toIso8601String();
    await supabaseClient
        .from('cuentas')
        .update({'deleted_at': ahora, 'updated_at': ahora})
        .eq('id', id);
  }
}
