import 'package:salud_dental_clinic_management/features/item_cuenta/data/datasources/item_cuenta_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ItemCuentaDatasourceImpl implements ItemCuentaDatasource {
  final SupabaseClient supabaseClient;

  ItemCuentaDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchItemsByCuenta(String cuentaId) async {
    final response = await supabaseClient
        .from('items_cuenta')
        .select('*, tratamientos_aplicados(*)')
        .eq('cuenta_id', cuentaId)
        .isFilter('deleted_at', null);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> insertItem(Map<String, dynamic> data) async {
    await supabaseClient.from('items_cuenta').insert(data);
  }

  @override
  Future<void> softDeleteItem(String id) async {
    await supabaseClient
        .from('items_cuenta')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
