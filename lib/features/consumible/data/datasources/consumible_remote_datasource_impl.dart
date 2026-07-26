import 'package:salud_dental_clinic_management/features/consumible/data/datasources/consumible_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/enums/motivo_ajuste_stock.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsumibleRemoteDatasourceImpl implements ConsumibleRemoteDatasource {
  final SupabaseClient supabaseClient;

  ConsumibleRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchConsumibles() async {
    final response = await supabaseClient
        .from('consumibles')
        // El suplidor viaja en el mismo viaje: el listado lo muestra y pedirlo
        // aparte era una consulta por fila.
        .select('*, suplidor:suplidores(nombre)')
        .filter('deleted_at', 'is', null)
        .order('nombre', ascending: true);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<void> registrarConsumoClinico(
    String consumibleId,
    int cantidad,
  ) async {
    await supabaseClient.from('movimientos_stock_consumible').insert({
      'consumible_id': consumibleId,
      'diferencia': -cantidad,
      'motivo': MotivoAjusteStock.usoInterno.name,
    });
  }

  @override
  Future<void> adjustStock(String id, int nuevoStock, String motivo) async {
    final actual = await supabaseClient
        .from('consumibles')
        .select('stock_actual')
        .eq('id', id)
        .single();
    final diferencia = nuevoStock - (actual['stock_actual'] as int);

    await supabaseClient.from('movimientos_stock_consumible').insert({
      'consumible_id': id,
      'diferencia': diferencia,
      'motivo': motivo,
    });
  }

  @override
  Future<void> updateStock(String id, int nuevoStock) async {
    await supabaseClient
        .from('consumibles')
        .update({
          'stock_actual': nuevoStock,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  @override
  Future<void> upsertConsumible(Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();

    if (data['id'] == null) {
      data['created_at'] = DateTime.now().toIso8601String();
      await supabaseClient.from('consumibles').insert(data);
    } else {
      await supabaseClient.from('consumibles').upsert(data);
    }
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
