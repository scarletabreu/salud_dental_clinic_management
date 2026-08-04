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
    final termino = query.trim();
    if (termino.isEmpty) return [];

    // El campo prometía «Nombre, apellido o cédula» y sólo buscaba por los dos
    // primeros: al agendar, escribir la cédula no encontraba a nadie (defecto
    // D16 de la jornada de QA del 1 ago 2026).
    //
    // La cédula dominicana se escribe con guiones o sin ellos —`001-1391820-5`
    // y `00113918205` son la misma— y en la base conviven ambas formas, así
    // que se busca por las dos.
    final soloDigitos = termino.replaceAll(RegExp(r'[^0-9]'), '');
    final condiciones = <String>[
      'nombre.ilike.%${_escaparPatron(termino)}%',
      'apellido.ilike.%${_escaparPatron(termino)}%',
      'cedula.ilike.%${_escaparPatron(termino)}%',
      if (soloDigitos.isNotEmpty && soloDigitos != termino)
        'cedula.ilike.%$soloDigitos%',
    ];

    final response = await supabase
        .from('personas')
        .select('*, persona_contacto:persona_contactos(*, contactos(*))')
        .or(condiciones.join(','))
        .eq('estatus', 'activo')
        .filter('deleted_at', 'is', null)
        .limit(10);

    return (response as List)
        .map((json) => PersonaModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Neutraliza lo que PostgREST interpreta dentro de un `or(...)`.
  ///
  /// Una coma parte la lista de condiciones y un paréntesis la cierra: un
  /// nombre con `(` convertía la búsqueda en una petición malformada. `%` y `_`
  /// son comodines de `ilike` y buscarlos literalmente es lo que espera quien
  /// los escribe.
  static String _escaparPatron(String termino) => termino
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_')
      .replaceAll(',', ' ')
      .replaceAll('(', ' ')
      .replaceAll(')', ' ');

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
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }
}
