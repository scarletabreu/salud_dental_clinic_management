import 'package:salud_dental_clinic_management/core/data/datasources/contacto_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';

class ContactoRemoteDataSourceImpl implements ContactoRemoteDataSource {
  final SupabaseClient supabase;

  ContactoRemoteDataSourceImpl(this.supabase);

  @override
  Future<ContactoModel?> fetchContactoByPersonaId(String personaId) async {
    final response = await supabase
        .from('contactos')
        .select()
        .eq('persona_id', personaId)
        .filter('deleted_at', 'is', null)
        .maybeSingle();

    if (response == null) return null;
    return ContactoModel.fromJson(response);
  }

  @override
  Future<void> createContacto(String personaId, ContactoModel contacto) async {
    final data = contacto.toJson();
    data['persona_id'] = personaId;
    data['created_at'] = DateTime.now().toIso8601String();

    await supabase.from('contactos').insert(data);
  }

  @override
  Future<void> updateContacto(ContactoModel contacto) async {
    if (contacto.id == null) {
      throw Exception('No se puede actualizar un contacto sin un ID válido.');
    }

    final data = contacto.toJson();
    data['updated_at'] = DateTime.now().toIso8601String();
    data.remove('id');

    await supabase.from('contactos').update(data).eq('id', contacto.id!);
  }

  @override
  Future<void> deleteContacto(String id) async {
    await supabase
        .from('contactos')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
