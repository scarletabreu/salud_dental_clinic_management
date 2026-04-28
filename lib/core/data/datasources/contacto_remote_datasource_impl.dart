import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
import 'contacto_remote_datasource.dart';

class ContactoRemoteDataSourceImpl implements ContactoRemoteDataSource {
  final SupabaseClient supabase;

  ContactoRemoteDataSourceImpl(this.supabase);

  @override
  Future<ContactoModel?> fetchContactoByPersonaId(String personaId) async {
    final response = await supabase
        .from('contactos')
        .select()
        .eq('persona_id', personaId)
        .maybeSingle();

    if (response == null) return null;
    return ContactoModel.fromJson(response);
  }

  @override
  Future<void> createContacto(String personaId, ContactoModel contacto) async {
    final data = contacto.toJson();
    data['persona_id'] = personaId;
    await supabase.from('contactos').insert(data);
  }

  @override
  Future<void> updateContacto(ContactoModel contacto) async {
    await supabase
        .from('contactos')
        .update(contacto.toJson())
        .eq('persona_id', contacto.email);
  }

  @override
  Future<void> deleteContacto(String id) async {
    await supabase.from('contactos').delete().eq('id', id);
  }
}
