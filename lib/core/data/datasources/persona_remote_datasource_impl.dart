import 'package:salud_dental_clinic_management/core/data/datasources/persona_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/core/data/models/persona_model.dart';

class PersonaRemoteDataSourceImpl implements PersonaRemoteDataSource {
  final SupabaseClient supabase;

  PersonaRemoteDataSourceImpl(this.supabase);

  @override
  Future<List<PersonaModel>> fetchActivePersonas() async {
    final response = await supabase
        .from('personas')
        .select()
        .eq('estatus', 'activo');

    return (response as List)
        .map((json) => PersonaModel.fromJson(json))
        .toList();
  }

  @override
  Future<PersonaModel> fetchPersonaById(String id) async {
    final response = await supabase
        .from('personas')
        .select()
        .eq('id', id)
        .single();

    return PersonaModel.fromJson(response);
  }

  @override
  Future<void> createPersona(PersonaModel persona) async {
    await supabase.from('personas').insert(persona.toJson());
  }

  @override
  Future<void> updatePersona(PersonaModel persona) async {
    await supabase
        .from('personas')
        .update(persona.toJson())
        .eq('id', persona.id);
  }

  @override
  Future<void> deactivatePersona(String id) async {
    await supabase
        .from('personas')
        .update({'estatus': 'inactivo'})
        .eq('id', id);
  }
}
