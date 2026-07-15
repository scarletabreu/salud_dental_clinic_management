import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/features/item_cuenta/data/datasources/item_cuenta_remote_datasource.dart';

class ItemCuentaDatasourceImpl implements ItemCuentaDatasource {
  final SupabaseClient supabaseClient;

  ItemCuentaDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchItemsByCuenta(String cuentaId) async {
    final response = await supabaseClient
        .from('items_cuenta')
        .select('*, tratamientos_aplicados(*)')
        .eq('cuenta_id', cuentaId)
        .filter('deleted_at', 'is', null);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<void> insertItem(Map<String, dynamic> data) async {
    data.remove('id');
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    await supabaseClient.from('items_cuenta').insert(data);
  }

  @override
  Future<void> updateItem(String id, Map<String, dynamic> data) async {
    data.remove('id');
    data['updated_at'] = DateTime.now().toIso8601String();

    await supabaseClient.from('items_cuenta').update(data).eq('id', id);
  }

  @override
  Future<void> softDeleteItem(String id) async {
    await supabaseClient
        .from('items_cuenta')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }
}
