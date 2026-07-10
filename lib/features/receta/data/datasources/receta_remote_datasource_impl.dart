import 'package:salud_dental_clinic_management/features/receta/data/datasources/receta_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecetaRemoteDatasourceImpl implements RecetaRemoteDatasource {
  final SupabaseClient supabaseClient;

  RecetaRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<void> crearReceta(Map<String, dynamic> data) async {
    data.remove('id');
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    await supabaseClient.from('recetas').insert(data);
  }

  @override
  Future<void> actualizarReceta(Map<String, dynamic> data) async {
    data.remove('id');
    data['updated_at'] = DateTime.now().toIso8601String();
    await supabaseClient.from('recetas').upsert(data);
  }

  @override
  Future<void> anularReceta(String id) async {
    await supabaseClient
        .from('recetas')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRecetasByPaciente(
    String pacienteId,
  ) async {
    final response = await supabaseClient
        .from('recetas')
        .select('*, medicina:medicinas(nombre)')
        .eq('paciente_id', pacienteId)
        .filter('deleted_at', 'is', null)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }
}
