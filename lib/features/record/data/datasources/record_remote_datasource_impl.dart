import 'package:salud_dental_clinic_management/features/record/data/datasources/record_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecordRemoteDatasourceImpl implements RecordRemoteDatasource {
  final SupabaseClient supabaseClient;

  RecordRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<Map<String, dynamic>?> fetchRecordByPaciente(String pacienteId) async {
    try {
      final response = await supabaseClient
          .from('records')
          .select('*, consultas(*)')
          .eq('paciente_id', pacienteId)
          .filter('deleted_at', 'is', null)
          .maybeSingle();

      return response;
    } on PostgrestException catch (e) {
      throw Exception('Error al recuperar el expediente clínico: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cargar record: $e');
    }
  }

  @override
  Future<void> upsertRecord(Map<String, dynamic> data) async {
    try {
      await supabaseClient.from('records').upsert(data);
    } on PostgrestException catch (e) {
      throw Exception(
        'Error al guardar/actualizar el expediente: ${e.message}',
      );
    } catch (e) {
      throw Exception('Error inesperado al persistir expediente: $e');
    }
  }

  @override
  Future<void> anularRecord(String id) async {
    try {
      await supabaseClient
          .from('records')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al anular el expediente: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al anular record: $e');
    }
  }
}
