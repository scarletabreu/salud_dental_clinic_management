import 'package:salud_dental_clinic_management/features/cuenta/data/datasources/cuenta_remote_datasource.dart';
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

Future<void> updateCuenta(String id, Map<String, dynamic> data) async {
  try {
    data['updated_at'] = DateTime.now().toIso8601String();
    await supabaseClient.from('cuentas').update(data).eq('id', id);
  } on PostgrestException catch (e) {
    throw Exception('Error al actualizar cuenta: ${e.message}');
  }
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
