import 'package:salud_dental_clinic_management/features/orden_medica/data/datasources/orden_medica_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrdenMedicaRemoteDatasourceImpl implements OrdenMedicaRemoteDatasource {
  final SupabaseClient supabaseClient;

  OrdenMedicaRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<void> insertarOrden(Map<String, dynamic> data) async {
    try {
      data.remove('id');
      data['created_at'] = DateTime.now().toIso8601String();
      data['updated_at'] = DateTime.now().toIso8601String();
      await supabaseClient.from('ordenes_medicas').insert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al insertar orden médica: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al insertar orden: $e');
    }
  }

  @override
  Future<void> actualizarOrden(Map<String, dynamic> data) async {
    try {
      data.remove('id');
      data['updated_at'] = DateTime.now().toIso8601String();
      await supabaseClient.from('ordenes_medicas').upsert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar orden médica: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al actualizar orden: $e');
    }
  }

  @override
  Future<void> eliminarOrden(String id) async {
    try {
      await supabaseClient
          .from('ordenes_medicas')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar orden médica: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al eliminar orden: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchOrdenesPorPaciente(
    String pacienteId,
  ) async {
    try {
      final response = await supabaseClient
          .from('ordenes_medicas')
          .select('*, procedimiento:tratamientos(nombre)')
          .eq('paciente_id', pacienteId)
          .filter('deleted_at', 'is', null)
          .order('fecha', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception(
        'Error al recuperar órdenes médicas del paciente: ${e.message}',
      );
    } catch (e) {
      throw Exception('Error inesperado al buscar órdenes: $e');
    }
  }
}
