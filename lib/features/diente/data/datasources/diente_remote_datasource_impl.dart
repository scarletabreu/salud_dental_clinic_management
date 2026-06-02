import 'package:salud_dental_clinic_management/features/diente/data/datasources/diente_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DienteRemoteDatasourceImpl implements DienteRemoteDatasource {
  final SupabaseClient supabaseClient;

  DienteRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchDientesByOdontograma(
    String odontogramaId,
  ) async {
    try {
      final response = await supabaseClient
          .from('dientes')
          .select(
            '*, superficies(*), diagnosis_aplicados(*), tratamientos_aplicados(*)',
          )
          .eq('odontograma_id', odontogramaId)
          .filter('deleted_at', 'is', null);

      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception('Error al cargar piezas dentales: ${e.message}');
    }
  }

  @override
  Future<void> updateDiente(String id, Map<String, dynamic> data) async {
    try {
      data.remove('id');
      data['updated_at'] = DateTime.now().toIso8601String();
      await supabaseClient.from('dientes').update(data).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar el diente: ${e.message}');
    }
  }

  @override
  Future<void> deleteDienteData(String id) async {
    try {
      await supabaseClient
          .from('dientes')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar información del diente: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al eliminar: $e');
    }
  }
}
