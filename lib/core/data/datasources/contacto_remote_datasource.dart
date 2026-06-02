import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';

abstract class ContactoRemoteDataSource {
  Future<ContactoModel?> fetchContactoByPersonaId(String personaId);
  Future<void> createContacto(String personaId, ContactoModel contacto);
  Future<void> updateContacto(ContactoModel contacto);
  Future<void> deleteContacto(String id);
}
