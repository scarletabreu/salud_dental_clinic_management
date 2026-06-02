import 'package:salud_dental_clinic_management/features/procedimiento/data/datasources/procedimiento_remore_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProcedimientoRemoteDatasourceImpl
    implements ProcedimientoRemoteDatasource {
  final SupabaseClient supabaseClient;

  ProcedimientoRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchProcedimientos() async {
    try {
      final response = await supabaseClient
          .from('procedimientos')
          .select('*, contraindicaciones(*)')
          .filter('deleted_at', 'is', null)
          .order('nombre', ascending: true);

      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception(
        'Error al recuperar catálogo de procedimientos: ${e.message}',
      );
    } catch (e) {
      throw Exception('Error inesperado al cargar procedimientos: $e');
    }
  }

  @override
  Future<void> createProcedimiento(Map<String, dynamic> data) async {
    try {
      data.remove('id');

      final now = DateTime.now().toIso8601String();
      data['created_at'] = now;
      data['updated_at'] = now;

      await supabaseClient.from('procedimientos').insert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al registrar nuevo procedimiento: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al crear procedimiento: $e');
    }
  }

  @override
  Future<void> upsertProcedimiento(Map<String, dynamic> data) async {
    try {
      data.remove('id');
      data['updated_at'] = DateTime.now().toIso8601String();
      await supabaseClient.from('procedimientos').upsert(data);
    } on PostgrestException catch (e) {
      throw Exception(
        'Error al guardar/actualizar procedimiento: ${e.message}',
      );
    } catch (e) {
      throw Exception('Error inesperado al persistir procedimiento: $e');
    }
  }

  @override
  Future<void> softDeleteProcedimiento(String id) async {
    try {
      await supabaseClient
          .from('procedimientos')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar procedimiento: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al eliminar: $e');
    }
  }
}
