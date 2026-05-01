import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/data/datasources/tratamiento_aplicado_datasource.dart';

class TratamientoAplicadoDatasourceImpl
    implements TratamientoAplicadoDatasource {
  final SupabaseClient supabaseClient;

  TratamientoAplicadoDatasourceImpl({required this.supabaseClient});

  @override
  Future<void> registrarTratamiento(Map<String, dynamic> data) async {
    try {
      await supabaseClient.from('tratamientos_aplicados').insert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al registrar tratamiento aplicado: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al registrar tratamiento: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPorPaciente(String pacienteId) async {
    try {
      final response = await supabaseClient
          .from('tratamientos_aplicados')
          .select('*, tratamiento:tratamientos(*)')
          .eq('paciente_id', pacienteId)
          .filter('deleted_at', 'is', null);

      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception(
        'Error al recuperar tratamientos del paciente: ${e.message}',
      );
    } catch (e) {
      throw Exception('Error inesperado al cargar tratamientos: $e');
    }
  }

  @override
  Future<void> marcarComoTerminado(String id) async {
    try {
      await supabaseClient
          .from('tratamientos_aplicados')
          .update({'esta_terminado': true})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(
        'Error al marcar tratamiento como terminado: ${e.message}',
      );
    } catch (e) {
      throw Exception('Error inesperado al actualizar estado: $e');
    }
  }

  @override
  Future<void> eliminarTratamiento(String id) async {
    try {
      await supabaseClient
          .from('tratamientos_aplicados')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar tratamiento aplicado: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al eliminar: $e');
    }
  }
}
