import 'package:salud_dental_clinic_management/features/condicion/data/datasources/condicion_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CondicionRemoteDatasourceImpl implements CondicionRemoteDatasource {
  final SupabaseClient supabaseClient;

  CondicionRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchCondiciones() async {
    try {
      final response = await supabaseClient
          .from('condiciones')
          .select()
          .isFilter('deleted_at', null)
          .order('nombre', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener condiciones: ${e.message}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCondicionesByTipo(String tipo) async {
    try {
      final response = await supabaseClient
          .from('condiciones')
          .select()
          .eq('tipo', tipo)
          .isFilter('deleted_at', null)
          .order('nombre', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Error al obtener condiciones por tipo: ${e.message}');
    }
  }

  @override
  Future<void> createCondicion(Map<String, dynamic> condicionData) async {
    try {
      condicionData.remove('id');
      condicionData['created_at'] = DateTime.now().toIso8601String();
      condicionData['updated_at'] = DateTime.now().toIso8601String();
      await supabaseClient.from('condiciones').insert(condicionData);
    } on PostgrestException catch (e) {
      throw Exception('Error al crear condición: ${e.message}');
    }
  }

  @override
  Future<void> deleteCondicion(String id) async {
    try {
      await supabaseClient
          .from('condiciones')
          .update({
            'deleted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al borrar condición: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al borrar: $e');
    }
  }
}
