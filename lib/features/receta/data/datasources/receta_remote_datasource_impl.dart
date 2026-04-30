import 'package:salud_dental_clinic_management/features/receta/data/datasources/receta_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecetaRemoteDatasourceImpl implements RecetaRemoteDatasource {
  final SupabaseClient supabaseClient;

  RecetaRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<void> crearReceta(Map<String, dynamic> data) async {
    try {
      await supabaseClient.from('recetas').insert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al registrar receta médica: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al crear receta: $e');
    }
  }

  @override
  Future<void> actualizarReceta(Map<String, dynamic> data) async {
    try {
      await supabaseClient.from('recetas').upsert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar receta: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al actualizar receta: $e');
    }
  }

  @override
  Future<void> anularReceta(String id) async {
    try {
      await supabaseClient
          .from('recetas')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al anular receta: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al anular receta: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRecetasByPaciente(
    String pacienteId,
  ) async {
    try {
      final response = await supabaseClient
          .from('recetas')
          .select('*, medicina:medicinas(nombre)')
          .eq('paciente_id', pacienteId)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception('Error al recuperar recetas del paciente: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al buscar recetas: $e');
    }
  }
}
