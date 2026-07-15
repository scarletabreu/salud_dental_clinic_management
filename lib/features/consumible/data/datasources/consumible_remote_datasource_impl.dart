import 'package:salud_dental_clinic_management/features/consumible/data/datasources/consumible_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsumibleRemoteDatasourceImpl implements ConsumibleRemoteDatasource {
  final SupabaseClient supabaseClient;

  ConsumibleRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchConsumibles() async {
    final response = await supabaseClient
        .from('consumibles')
        .select()
        .isFilter('deleted_at', null)
        .order('nombre', ascending: true);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<void> updateStock(String id, int nuevoStock) async {
    await supabaseClient
        .from('consumibles')
        .update({'stock_actual': nuevoStock})
        .eq('id', id);
  }

  @override
  Future<void> upsertConsumible(Map<String, dynamic> data) async {
    data.remove('id');
    data['updated_at'] = DateTime.now().toIso8601String();
    await supabaseClient.from('consumibles').upsert(data);
  }

  @override
  Future<void> createConsumible(Map<String, dynamic> data) async {
    data.remove('id');
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    await supabaseClient.from('consumibles').insert(data);
  }

  @override
  Future<void> updateConsumible(String id, Map<String, dynamic> data) async {
    data.remove('id');
    data['updated_at'] = DateTime.now().toIso8601String();
    await supabaseClient.from('consumibles').update(data).eq('id', id);
  }

  @override
  Future<void> deleteConsumible(String id) async {
    await supabaseClient
        .from('consumibles')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }
}
