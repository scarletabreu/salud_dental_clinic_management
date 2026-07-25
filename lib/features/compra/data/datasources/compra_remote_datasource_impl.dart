import 'package:salud_dental_clinic_management/features/compra/data/datasources/compra_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/compra/data/models/compra_model.dart';
import 'package:salud_dental_clinic_management/features/consumible_compra/data/models/consumible_compra_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompraRemoteDatasourceImpl implements CompraRemoteDatasource {
  final SupabaseClient supabaseClient;

  CompraRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchCompras() async {
    // 1. Obtener las compras
    final comprasResponse = await supabaseClient
        .from('compras')
        .select()
        .filter('deleted_at', 'is', null)
        .order('fecha', ascending: false);

    final compras = List<Map<String, dynamic>>.from(comprasResponse);
    if (compras.isEmpty) return [];

    final compraIds = compras
        .map((c) => c['id'] as String?)
        .whereType<String>()
        .toList();

    if (compraIds.isEmpty) return compras;

    // 2. Obtener los consumibles asociados
    final itemsResponse = await supabaseClient
        .from('consumibles_compras')
        .select()
        .filter('compra_id', 'in', compraIds);

    final items = List<Map<String, dynamic>>.from(itemsResponse);

    // 3. Unir los ítems dentro de su respectiva compra
    for (var compra in compras) {
      final itemsDeCompra = items
          .where((item) => item['compra_id'] == compra['id'])
          .toList();
      compra['items'] = itemsDeCompra;
    }

    return compras;
  }

  @override
  Future<Map<String, dynamic>?> fetchCompraById(String id) async {
    final compra = await supabaseClient
        .from('compras')
        .select()
        .eq('id', id)
        .filter('deleted_at', 'is', null)
        .maybeSingle();

    if (compra == null) return null;

    final itemsResponse = await supabaseClient
        .from('consumibles_compras')
        .select()
        .eq('compra_id', id);

    final compraMap = Map<String, dynamic>.from(compra);
    compraMap['items'] = List<Map<String, dynamic>>.from(itemsResponse);

    return compraMap;
  }

  @override
  Future<void> createCompra(CompraModel compra) async {
    final Map<String, dynamic> compraData = compra.toJson();

    compraData['created_at'] = DateTime.now().toIso8601String();
    compraData['updated_at'] = DateTime.now().toIso8601String();

    final compraResponse = await supabaseClient
        .from('compras')
        .insert(compraData)
        .select('id')
        .single();

    final String compraId = compraResponse['id'];

    final itemsData = compra.items.map((item) {
      final model = item as ConsumibleCompraModel;
      final json = model.toJson();
      json['compra_id'] = compraId;
      json.remove('id');
      return json;
    }).toList();

    await supabaseClient.from('consumibles_compras').insert(itemsData);
  }

  @override
  Future<void> updateCompraEstado(String id, String nuevoEstado) async {
    await supabaseClient
        .from('compras')
        .update({
          'estado': nuevoEstado,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  @override
  Future<void> deleteCompra(String id) async {
    await supabaseClient
        .from('compras')
        .update({
          'estado': 'cancelado',
          'deleted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  @override
  Future<void> recibirCompra({
    required String compraId,
    required String usuarioId,
  }) async {
    await supabaseClient.rpc(
      'recibir_compra',
      params: {'p_compra_id': compraId, 'p_usuario_id': usuarioId},
    );
  }
}
