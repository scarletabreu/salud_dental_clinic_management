import 'package:salud_dental_clinic_management/features/consumible/data/datasources/consumible_remote_datasource.dart';
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

  /// El ajuste va por la RPC, que es quien tiene capacidad para moverlo.
  ///
  /// Antes se leía el stock y se insertaba el movimiento a mano. Eso dejaba la
  /// diferencia calculada en el cliente —dos ajustes simultáneos se pisaban— y
  /// exigía que `movimientos_stock_consumible` fuese escribible por cualquier
  /// usuario autenticado, que es el agujero que cierra HFX-CLIN-007.
  /// `ajustar_stock_consumible` exige capacidad administrativa, toma el lock y
  /// deja el estado del consumible recalculado.
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
