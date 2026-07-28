import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
import 'package:salud_dental_clinic_management/core/data/models/persona_model.dart';
import 'package:salud_dental_clinic_management/core/data/datasources/persona_remote_datasource.dart';

class PersonaRemoteDataSourceImpl implements PersonaRemoteDataSource {
  final SupabaseClient supabase;

  PersonaRemoteDataSourceImpl(this.supabase);

  @override
  Future<List<PersonaModel>> fetchActivePersonas() async {
    final response = await supabase
        .from('personas')
        .select()
        .eq('estatus', 'activo')
        .filter('deleted_at', 'is', null);

    return (response as List)
        .map((json) => PersonaModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<PersonaModel>> searchPersonas(String query) async {
    if (query.trim().isEmpty) return [];
    final response = await supabase
        .from('personas')
        .select('*, persona_contacto:persona_contactos(*, contactos(*))')
        .or('nombre.ilike.%$query%,apellido.ilike.%$query%')
        .eq('estatus', 'activo')
        .filter('deleted_at', 'is', null)
        .limit(10);

    return (response as List)
        .map((json) => PersonaModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PersonaModel> fetchPersonaById(String id) async {
    final response = await supabase
        .from('personas')
        .select('*, persona_contacto:persona_contactos(*, contactos(*))')
        .eq('id', id)
        .single();

    return PersonaModel.fromJson(response);
  }

  @override
  Future<PersonaModel> createPersona(PersonaModel persona) async {
    if (persona.contactos.isEmpty) {
      throw Exception('La persona debe tener al menos un contacto.');
    }

    String? contactoId;
    String? personaId;

    try {
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
        'contactos': persona.contactos
            .map((c) => (c as ContactoModel).toJson())
            .toList(),
      });
    } on PostgrestException {
      if (contactoId != null) {
        await supabase.from('contactos').delete().eq('id', contactoId);
      }
      if (personaId != null) {
        await supabase.from('personas').delete().eq('id', personaId);
      }
      rethrow;
    }
  }

  @override
  Future<void> updatePersona(PersonaModel persona) async {
    if (persona.id == null) {
      throw Exception('No se puede actualizar una persona sin un ID válido.');
    }

    final data = persona.toJson();
    data.remove('id');

    await supabase.from('personas').update(data).eq('id', persona.id!);
  }

  @override
  Future<void> deactivatePersona(String id) async {
    await supabase
        .from('personas')
        .update({
          'estatus': 'inactivo',
          'deleted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }
}
