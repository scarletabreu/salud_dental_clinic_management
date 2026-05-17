import 'package:salud_dental_clinic_management/features/odontograma/data/datasources/odontograma_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OdontogramaRemoteDatasourceImpl implements OdontogramaRemoteDatasource {
  final SupabaseClient supabaseClient;

  OdontogramaRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<Map<String, dynamic>?> fetchOdontogramaByConsulta(
    String consultaId,
  ) async {
    try {
      final response = await supabaseClient
          .from('odontogramas')
          .select(
            '*, dientes:dientes(*, diagnosis:diagnosticos_aplicados(*), tratamientos:tratamientos_aplicados(*))',
          )
          .eq('consulta_id', consultaId)
          .filter('deleted_at', 'is', null)
          .maybeSingle();

      return response;
    } on PostgrestException catch (e) {
      throw Exception('Error al recuperar odontograma: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cargar odontograma: $e');
    }
  }

  @override
  Future<void> crearOdontograma(Map<String, dynamic> data) async {
    try {
      data.remove('id');

      data['created_at'] = DateTime.now().toIso8601String();
      data['updated_at'] = DateTime.now().toIso8601String();
      await supabaseClient.from('odontogramas').insert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al registrar nuevo odontograma: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al crear odontograma: $e');
    }
  }

  @override
  Future<void> actualizarOdontograma(Map<String, dynamic> data) async {
    try {
      data.remove('id');
      data['updated_at'] = DateTime.now().toIso8601String();
      await supabaseClient.from('odontogramas').upsert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar odontograma: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al actualizar odontograma: $e');
    }
  }

  @override
  Future<void> eliminarOdontograma(String id) async {
    try {
      await supabaseClient
          .from('odontogramas')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar odontograma: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al eliminar odontograma: $e');
    }
  }
}
