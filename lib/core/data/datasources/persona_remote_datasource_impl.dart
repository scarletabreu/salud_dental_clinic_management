import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
import 'package:salud_dental_clinic_management/core/data/models/persona_model.dart';
import 'package:salud_dental_clinic_management/core/data/datasources/persona_remote_datasource.dart';

class PersonaRemoteDataSourceImpl implements PersonaRemoteDataSource {
  final SupabaseClient supabase;

  PersonaRemoteDataSourceImpl(this.supabase);

  @override
  Future<List<PersonaModel>> fetchActivePersonas() async {
    try {
      final response = await supabase
          .from('personas')
          .select()
          .eq('estatus', 'activo')
          .filter('deleted_at', 'is', null);

      return (response as List)
          .map((json) => PersonaModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error al recuperar personas activas: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<PersonaModel> fetchPersonaById(String id) async {
    try {
      final response = await supabase
          .from('personas')
          .select('*, persona_contacto(*, contactos(*))')
          .eq('id', id)
          .single();

      return PersonaModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Error al recuperar persona: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<void> createPersona(PersonaModel persona) async {
    String? contactoId;
    try {
      final contactoResponse = await supabase
          .from('contactos')
          .insert((persona.contacto as ContactoModel).toJson())
          .select('id')
          .single();

      contactoId = contactoResponse['id'] as String;

      final personaResponse = await supabase
          .from('personas')
          .insert(persona.toJson())
          .select('id')
          .single();

      final personaId = personaResponse['id'] as String;

      await supabase.from('persona_contacto').insert({
        'persona_id': personaId,
        'contacto_id': contactoId,
        'es_principal': true,
      });
    } on PostgrestException catch (e) {
      if (contactoId != null) {
        await supabase.from('contactos').delete().eq('id', contactoId);
      }
      throw Exception('Error al registrar persona: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al crear persona: $e');
    }
  }

  @override
  Future<void> updatePersona(PersonaModel persona) async {
    try {
      await supabase
          .from('personas')
          .update(persona.toJson())
          .eq('id', persona.id);
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar persona: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al actualizar: $e');
    }
  }

  @override
  Future<void> deactivatePersona(String id) async {
    try {
      await supabase
          .from('personas')
          .update({
            'estatus': 'inactivo',
            'deleted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Error al desactivar persona: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al desactivar: $e');
    }
  }
}
