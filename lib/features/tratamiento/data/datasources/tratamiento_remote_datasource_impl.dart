import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/data/datasources/tratamiento_remote_datasource.dart';

class TratamientoRemoteDatasourceImpl implements TratamientoRemoteDatasource {
  final SupabaseClient supabaseClient;

  TratamientoRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<Map<String, dynamic>>> fetchTratamientos() async {
    try {
      final response = await supabaseClient
          .from('tratamientos')
          .select('*, contraindicaciones(*)')
          .filter('deleted_at', 'is', null)
          .order('nombre', ascending: true);

      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception(
        'Error al recuperar catálogo de tratamientos: ${e.message}',
      );
    } catch (e) {
      throw Exception('Error inesperado al cargar tratamientos: $e');
    }
  }

  @override
  Future<void> createTratamiento(Map<String, dynamic> data) async {
    try {
      // 1. Limpiamos campos que Supabase autogenera o que pertenecen a relaciones
      data.remove('id');
      data.remove(
        'contraindicaciones',
      ); // Evita que explote si va la lista vacía de la UI

      // 2. Forzamos que la propiedad costo use el valor numérico correcto
      // Si en tu toJson() guardaste la propiedad como 'precio_base', la recuperamos aquí:
      if (data.containsKey('precio_base') && !data.containsKey('costo')) {
        data['costo'] = data.remove('precio_base');
      }

      final now = DateTime.now().toIso8601String();
      data['created_at'] = now;
      data['updated_at'] = now;

      await supabaseClient.from('tratamientos').insert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al registrar nuevo tratamiento: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al crear tratamiento: $e');
    }
  }

  @override
  Future<void> updateTratamiento(String id, Map<String, dynamic> data) async {
    try {
      data.remove('id');
      data.remove('contraindicaciones');

      if (data.containsKey('precio_base') && !data.containsKey('costo')) {
        data['costo'] = data.remove('precio_base');
      }

      data['updated_at'] = DateTime.now().toIso8601String();

      await supabaseClient.from('tratamientos').update(data).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar tratamiento: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al actualizar tratamiento: $e');
    }
  }

  @override
  Future<void> upsertTratamiento(Map<String, dynamic> data) async {
    try {
      data.remove('id');
      data['updated_at'] = DateTime.now().toIso8601String();
      await supabaseClient.from('tratamientos').upsert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al guardar/actualizar tratamiento: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al persistir tratamiento: $e');
    }
  }

  @override
  Future<void> deleteTratamiento(String id) async {
    try {
      await supabaseClient
          .from('tratamientos')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar tratamiento: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al eliminar tratamientos: $e');
    }
  }
}
