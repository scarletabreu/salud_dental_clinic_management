import 'package:salud_dental_clinic_management/features/medicina/data/datasources/medicina_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MedicinaRemoteDatasourceImpl implements MedicinaRemoteDatasource {
  final SupabaseClient supabaseClient;

  MedicinaRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchMedicinas() async {
    try {
      final response = await supabaseClient
          .from('medicinas')
          .select('*')
          .filter('deleted_at', 'is', null);

      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener catálogo de medicinas: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cargar medicinas: $e');
    }
  }

  @override
  Future<void> insertMedicina(Map<String, dynamic> data) async {
    try {
      await supabaseClient.from('medicinas').insert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al registrar medicina: ${e.message}');
    }
  }

  @override
  Future<void> upsertMedicina(Map<String, dynamic> data) async {
    try {
      await supabaseClient.from('medicinas').upsert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar medicina: ${e.message}');
    }
  }

  @override
  Future<void> softDeleteMedicina(String id) async {
    try {
      await supabaseClient
          .from('medicinas')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar medicina: ${e.message}');
    }
  }
}
