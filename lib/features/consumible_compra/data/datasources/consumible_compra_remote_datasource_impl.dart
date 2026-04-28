import 'package:salud_dental_clinic_management/features/consumible_compra/data/datasources/consumible_compra_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsumibleCompraRemoteDatasourceImpl
    implements ConsumibleCompraRemoteDatasource {
  final SupabaseClient supabaseClient;

  ConsumibleCompraRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchItemsByCompra(String compraId) async {
    final response = await supabaseClient
        .from('consumibles_compra')
        .select()
        .eq('compra_id', compraId)
        .isFilter('deleted_at', null);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<Map<String, dynamic>?> fetchConsumibleById(String id) async {
    return await supabaseClient
        .from('consumibles_compra')
        .select()
        .eq('id', id)
        .isFilter('deleted_at', null)
        .maybeSingle();
  }

  @override
  Future<void> updateConsumible(Map<String, dynamic> consumibleData) async {
    await supabaseClient.from('consumibles_compra').upsert(consumibleData);
  }

  @override
  Future<void> deleteConsumible(String id) async {
    await supabaseClient
        .from('consumibles_compra')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
