import 'package:salud_dental_clinic_management/features/consumible_compra/data/datasources/consumible_compra_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsumibleCompraRemoteDatasourceImpl
    implements ConsumibleCompraRemoteDatasource {
  final SupabaseClient supabaseClient;

  ConsumibleCompraRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchItemsByCompra(String compraId) async {
    try {
      final response = await supabaseClient
          .from('consumibles_compra')
          .select()
          .eq('compra_id', compraId)
          .filter('deleted_at', 'is', null);

      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener items de la compra: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cargar items: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchConsumibleById(String id) async {
    try {
      return await supabaseClient
          .from('consumibles_compra')
          .select()
          .eq('id', id)
          .filter('deleted_at', 'is', null)
          .maybeSingle();
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener consumible específico: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al buscar consumible: $e');
    }
  }

  @override
  Future<void> updateConsumible(Map<String, dynamic> consumibleData) async {
    try {
      await supabaseClient.from('consumibles_compra').upsert(consumibleData);
    } on PostgrestException catch (e) {
      throw Exception(
        'Error al actualizar consumible de la compra: ${e.message}',
      );
    } catch (e) {
      throw Exception('Error inesperado al actualizar: $e');
    }
  }

  @override
  Future<void> deleteConsumible(String id) async {
    try {
      await supabaseClient
          .from('consumibles_compra')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar consumible: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al eliminar: $e');
    }
  }
}
