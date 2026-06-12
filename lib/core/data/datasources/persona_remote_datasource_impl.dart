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
  Future<List<PersonaModel>> searchPersonas(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      // Busca por nombre O apellido usando ilike (case-insensitive).
      // Supabase no soporta OR entre columnas distintas con un solo .ilike(),
      // así que usamos el filtro `or` explícito.
      final response = await supabase
          .from('personas')
          // La tabla puente es `persona_contactos` (plural); se usa el alias
          // `persona_contacto` porque PersonaModel.fromJson lee esa clave.
          .select('*, persona_contacto:persona_contactos(*, contactos(*))')
          .or('nombre.ilike.%$query%,apellido.ilike.%$query%')
          .eq('estatus', 'activo')
          .filter('deleted_at', 'is', null)
          .limit(10);
 
      return (response as List)
          .map((json) => PersonaModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error al buscar personas: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al buscar personas: $e');
    }
  }

  @override
  Future<PersonaModel> fetchPersonaById(String id) async {
    try {
      final response = await supabase
          .from('personas')
          .select('*, persona_contacto:persona_contactos(*, contactos(*))')
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
  Future<PersonaModel> createPersona(PersonaModel persona) async {
    String? contactoId;
    String? personaId;

    try {
      if (persona.contactos.isEmpty) {
        throw Exception('La persona debe tener al menos un contacto.');
      }

      final primerContacto = persona.contactos.first as ContactoModel;

      final contactoResponse = await supabase
          .from('contactos')
          .insert(primerContacto.toJson())
          .select('id')
          .single();

      contactoId = contactoResponse['id'] as String;

      final personaResponse = await supabase
          .from('personas')
          .insert(persona.toJson())
          .select()
          .single();

      personaId = personaResponse['id'] as String;

      await supabase.from('persona_contactos').insert({
        'persona_id': personaId,
        'contacto_id': contactoId,
        'es_principal': true,
      });

      return PersonaModel.fromJson({
        ...personaResponse,
        'contactos': persona.contactos.map((c) => (c as ContactoModel).toJson()).toList(),
      });

    } on PostgrestException catch (e) {
      if (contactoId != null) {
        await supabase.from('contactos').delete().eq('id', contactoId);
      }
      if (personaId != null) {
        await supabase.from('personas').delete().eq('id', personaId);
      }
      throw Exception('Error al registrar persona en Supabase: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al crear persona: $e');
    }
  }

  @override
  Future<void> updatePersona(PersonaModel persona) async {
    if (persona.id == null) {
      throw Exception('No se puede actualizar una persona sin un ID válido.');
    }

    try {
      final data = persona.toJson();
      data.remove('id');

      await supabase.from('personas').update(data).eq('id', persona.id!);
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
