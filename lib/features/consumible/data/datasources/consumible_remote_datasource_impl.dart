import 'package:salud_dental_clinic_management/features/consumible/data/datasources/consumible_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsumibleRemoteDatasourceImpl implements ConsumibleRemoteDatasource {
  final SupabaseClient supabaseClient;

  ConsumibleRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchConsumibles() async {
    final response = await supabaseClient
        .from('consumibles')
        .select('*, suplidor:suplidores(nombre)')
        .eq('activo', true)
        .order('nombre', ascending: true);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<void> adjustStock(String id, int nuevoStock, String motivo) async {
    await supabaseClient.rpc(
      'ajustar_stock_consumible',
      params: {
        'p_consumible_id': id,
        'p_nuevo_stock': nuevoStock,
        'p_motivo': motivo,
      },
    );
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
          'activo': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }
}
