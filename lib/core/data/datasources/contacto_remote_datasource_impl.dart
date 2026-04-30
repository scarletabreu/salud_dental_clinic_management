import 'package:salud_dental_clinic_management/core/data/datasources/contacto_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';

class ContactoRemoteDataSourceImpl implements ContactoRemoteDataSource {
  final SupabaseClient supabase;

  ContactoRemoteDataSourceImpl(this.supabase);

  @override
  Future<ContactoModel?> fetchContactoByPersonaId(String personaId) async {
    try {
      final response = await supabase
          .from('contactos')
          .select()
          .eq('persona_id', personaId)
          .filter('deleted_at', 'is', null)
          .maybeSingle();

      if (response == null) return null;
      return ContactoModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Error al recuperar contacto: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al cargar contacto: $e');
    }
  }

  @override
  Future<void> createContacto(String personaId, ContactoModel contacto) async {
    try {
      final data = contacto.toJson();
      data['persona_id'] = personaId;
      data['created_at'] = DateTime.now().toIso8601String();
      await supabase.from('contactos').insert(data);
    } on PostgrestException catch (e) {
      throw Exception('Error al registrar contacto: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al crear contacto: $e');
    }
  }

  @override
  Future<void> updateContacto(ContactoModel contacto) async {
    try {
      final data = contacto.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();

      await supabase.from('contactos').update(data).eq('id', contacto.id);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar contacto: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al actualizar contacto: $e');
    }
  }

  @override
  Future<void> deleteContacto(String id) async {
    try {
      await supabase
          .from('contactos')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al eliminar contacto: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al eliminar contacto: $e');
    }
  }
}
