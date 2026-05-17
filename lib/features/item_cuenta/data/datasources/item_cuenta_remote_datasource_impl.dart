import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/features/item_cuenta/data/datasources/item_cuenta_remote_datasource.dart';

class ItemCuentaDatasourceImpl implements ItemCuentaDatasource {
  final SupabaseClient supabaseClient;

  ItemCuentaDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchItemsByCuenta(String cuentaId) async {
    try {
      final response = await supabaseClient
          .from('items_cuenta')
          .select('*, tratamientos_aplicados(*)')
          .eq('cuenta_id', cuentaId)
          .filter('deleted_at', 'is', null);

      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception('Error al recuperar items de la cuenta: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cargar items: $e');
    }
  }

  @override
  Future<void> insertItem(Map<String, dynamic> data) async {
    try {
      data.remove('id');
      data['created_at'] = DateTime.now().toIso8601String();
      data['updated_at'] = DateTime.now().toIso8601String();
      await supabaseClient.from('items_cuenta').insert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al insertar item en la cuenta: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al insertar item: $e');
    }
  }

  @override
  Future<void> updateItem(String id, Map<String, dynamic> data) async {
    try {
      data.remove('id');
      data['updated_at'] = DateTime.now().toIso8601String();

      await supabaseClient.from('items_cuenta').update(data).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar item de la cuenta: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al actualizar item: $e');
    }
  }

  @override
  Future<void> softDeleteItem(String id) async {
    try {
      await supabaseClient
          .from('items_cuenta')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar item: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al eliminar item: $e');
    }
  }
}
