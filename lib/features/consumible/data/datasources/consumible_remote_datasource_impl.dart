import 'package:salud_dental_clinic_management/features/consumible/data/datasources/consumible_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsumibleRemoteDatasourceImpl implements ConsumibleRemoteDatasource {
  final SupabaseClient supabaseClient;

  ConsumibleRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchConsumibles() async {
    try {
      final response = await supabaseClient
          .from('consumibles')
          .select()
          .isFilter('deleted_at', null)
          .order('nombre', ascending: true);

      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener inventario: ${e.message}');
    }
  }

  @override
  Future<void> updateStock(String id, int nuevoStock) async {
    try {
      await supabaseClient
          .from('consumibles')
          .update({'stock_actual': nuevoStock})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar stock: ${e.message}');
    }
  }

  @override
  Future<void> upsertConsumible(Map<String, dynamic> data) async {
    try {
      await supabaseClient.from('consumibles').upsert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al guardar consumible: ${e.message}');
    }
  }

  @override
  Future<void> createConsumible(Map<String, dynamic> data) async {
    try {
      await supabaseClient.from('consumibles').insert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al crear nuevo consumible: ${e.message}');
    }
  }

  @override
  Future<void> updateConsumible(String id, Map<String, dynamic> data) async {
    try {
      await supabaseClient.from('consumibles').update(data).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar consumible: ${e.message}');
    }
  }

  @override
  Future<void> deleteConsumible(String id) async {
    try {
      await supabaseClient
          .from('consumibles')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar consumible: ${e.message}');
    }
  }
}
