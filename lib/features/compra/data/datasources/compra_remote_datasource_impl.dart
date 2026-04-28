import 'package:salud_dental_clinic_management/features/compra/data/datasources/compra_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompraRemoteDatasourceImpl implements CompraRemoteDatasource {
  final SupabaseClient supabaseClient;

  CompraRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchCompras() async {
    final response = await supabaseClient
        .from('compras')
        .select('*, items:consumibles_compra(*)')
        .isFilter('deleted_at', null)
        .order('fecha', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<Map<String, dynamic>?> fetchCompraById(String id) async {
    return await supabaseClient
        .from('compras')
        .select('*, items:consumibles_compra(*)')
        .eq('id', id)
        .isFilter('deleted_at', null)
        .maybeSingle();
  }

  @override
  Future<void> createCompra(Map<String, dynamic> compraData) async {
    await supabaseClient.from('compras').insert(compraData);
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
