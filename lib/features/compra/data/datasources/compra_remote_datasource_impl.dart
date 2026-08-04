import 'package:salud_dental_clinic_management/features/compra/data/datasources/compra_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/compra/data/models/compra_model.dart';
import 'package:salud_dental_clinic_management/features/compra/domain/enums/estado_compra.dart';
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

  /// La compra y sus renglones nacen en una sola transacción del servidor.
  ///
  /// Antes eran dos escrituras seguidas: si la segunda fallaba quedaba una
  /// compra sin artículos, y una compra sin artículos se «recibía» sin mover
  /// stock ni dinero, marcándose recibida igual.
  @override
  Future<void> createCompra(CompraModel compra) async {
    final items = [
      for (final item in compra.items)
        {
          'consumible_id': item.consumibleId,
          'suplidor_id': item.suplidorId,
          'cantidad': item.cantidad,
          'precio_unitario': item.precioUnitario,
        },
    ];

    await supabaseClient.rpc('crear_compra', params: {'p_items': items});
  }

  @override
  Future<void> updateCompraEstado(String id, String nuevoEstado) async {
    await supabaseClient
        .from('compras')
        .update({
          'estado': nuevoEstado,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  /// Anular es cancelar: el enum de la base la llama `cancelada`, en femenino.
  /// Escribir `'cancelado'` respondía `22P02` y no había forma de anular una
  /// compra desde la aplicación.
  @override
  Future<void> deleteCompra(String id) async {
    final ahora = DateTime.now().toUtc().toIso8601String();
    await supabaseClient
        .from('compras')
        .update({
          'estado': EstadoCompra.cancelada.dbValue,
          'deleted_at': ahora,
          'updated_at': ahora,
        })
        .eq('id', id);
  }

  @override
  Future<void> recibirCompra({
    required String compraId,
    required String usuarioId,
    String metodoPago = 'efectivo',
  }) async {
    await supabaseClient.rpc(
      'recibir_compra',
      params: {
        'p_compra_id': compraId,
        'p_usuario_id': usuarioId,
        'p_metodo_pago': metodoPago,
      },
    );
  }
}
