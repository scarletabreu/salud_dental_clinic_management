import 'package:salud_dental_clinic_management/features/orden_medica/data/datasources/orden_medica_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrdenMedicaRemoteDatasourceImpl implements OrdenMedicaRemoteDatasource {
  final SupabaseClient supabaseClient;

  OrdenMedicaRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<void> insertarOrden(Map<String, dynamic> data) async {
    await supabaseClient.from('ordenes_medicas').insert(data);
  }

  @override
  Future<void> actualizarOrden(Map<String, dynamic> data) async {
    await supabaseClient.from('ordenes_medicas').upsert(data);
  }

  @override
  Future<void> eliminarOrden(String id) async {
    await supabaseClient
        .from('ordenes_medicas')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchOrdenesPorPaciente(
    String pacienteId,
  ) async {
    final response = await supabaseClient
        .from('ordenes_medicas')
        .select('*, procedimiento:tratamientos(nombre)')
        .eq('paciente_id', pacienteId)
        .isFilter('deleted_at', null)
        .order('fecha', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}
