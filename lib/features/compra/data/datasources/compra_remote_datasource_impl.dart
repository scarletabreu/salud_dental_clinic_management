import 'package:salud_dental_clinic_management/features/compra/data/datasources/compra_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/compra/data/models/compra_model.dart';
import 'package:salud_dental_clinic_management/features/consumible_compra/data/models/consumible_compra_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompraRemoteDatasourceImpl implements CompraRemoteDatasource {
  final SupabaseClient supabaseClient;

  CompraRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchCompras() async {
    final response = await supabaseClient
        .from('compras')
        .select('*, items:consumibles_compra(*)')
        .filter('deleted_at', 'is', null)
        .order('fecha', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<Map<String, dynamic>?> fetchCompraById(String id) async {
    return await supabaseClient
        .from('compras')
        .select('*, items:consumibles_compra(*)')
        .eq('id', id)
        .filter('deleted_at', 'is', null)
        .maybeSingle();
  }

  @override
  Future<void> createCompra(CompraModel compra) async {
    try {
      final compraResponse = await supabaseClient
          .from('compras')
          .insert({
            'fecha': compra.fecha.toIso8601String(),
            'estado': compra.estado.name,
          })
          .select('id')
          .single();

      final String compraId = compraResponse['id'];

      final itemsData = compra.items.map((item) {
        final model = item as ConsumibleCompraModel;
        final json = model.toJson();
        json['compra_id'] = compraId;
        return json;
      }).toList();

      await supabaseClient.from('consumibles_compra').insert(itemsData);
    } catch (e) {
      throw Exception('Error al registrar la compra: $e');
    }
  }

  @override
  Future<void> updateCompraEstado(String id, String nuevoEstado) async {
    await supabaseClient
        .from('compras')
        .update({'estado': nuevoEstado})
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
}
